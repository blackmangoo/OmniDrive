from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import io
import os
import time
from PIL import Image
import requests
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI(title="Car Parts Classification API", version="1.0.0")

# Enable CORS for mobile app/frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the trained custom YOLO11 Large model exactly once at startup
try:
    print("Loading Custom YOLO11 Large Model into memory...")
    # Update this path if the script is run from a different directory
    model = YOLO("models/car_parts_large_v1.pt")
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model: {e}")
    try:
        model = YOLO("car_parts_large_v1.pt")
        print("Model loaded from root dir!")
    except:
        model = None

@app.get("/")
@app.post("/health")
@app.get("/health")
def read_root():
    return {
        "status": "online",
        "message": "Car Parts Classification API is Running",
        "model_loaded": model is not None
    }

@app.post("/predict")
async def predict_car_part(file: UploadFile = File(...)):
    """
    Accepts an image file and returns the top 3 predicted car parts
    along with their confidence scores.
    """
    if model is None:
        raise HTTPException(status_code=500, detail="Model is not loaded")

    # Validate file type — accept explicit image/* MIME types
    # OR application/octet-stream (what Android camera package sends)
    # OR fall back to a known image file extension.
    ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
    filename = file.filename or ""
    ext = os.path.splitext(filename)[-1].lower()

    is_image_mime = file.content_type and file.content_type.startswith("image/")
    is_octet = file.content_type in (None, "", "application/octet-stream")
    is_known_ext = ext in ALLOWED_EXTENSIONS

    if not (is_image_mime or (is_octet and is_known_ext)):
        raise HTTPException(
            status_code=400,
            detail=f"File is not a recognised image (content_type={file.content_type!r}, ext={ext!r})."
        )

    try:
        # Read the image bytes directly into a PIL Image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Ensure image is in RGB mode
        if image.mode != "RGB":
            image = image.convert("RGB")
            
        # Run YOLO inference
        start_time = time.time()
        results = model.predict(source=image, imgsz=224, verbose=False)
        inference_time = (time.time() - start_time) * 1000 # in ms
        
        # Process the single result
        result = results[0]
        
        # Get the top 5 predicted classes and their probabilities
        top5_indices = result.probs.top5
        top5_confs = result.probs.top5conf.tolist()
        
        predictions = []
        for idx, conf in zip(top5_indices, top5_confs):
            class_name = result.names[idx]
            predictions.append({
                "class": class_name,
                "confidence": round(float(conf) * 100, 2) # Return as percentage
            })
            
        return JSONResponse(content={
            "success": True,
            "top_prediction": predictions[0]["class"],
            "top_confidence": predictions[0]["confidence"],
            "all_predictions": predictions,
            "inference_time_ms": round(inference_time, 2)
        })
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

# ── RAG Chatbot Endpoint ──
from supabase import create_client, Client

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://cqeubytgsrxdkfejxvan.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY) if SUPABASE_KEY else None
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

class ChatRequest(BaseModel):
    query: str

@app.post("/chat")
async def chat_with_rag(request: ChatRequest):
    if not supabase_client or not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Missing API keys")

    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:embedContent?key={GEMINI_API_KEY}"
        res = requests.post(url, json={"model": "models/gemini-embedding-2", "content": {"parts": [{"text": request.query}]}, "outputDimensionality": 768}).json()
        query_embedding = res["embedding"]["values"]

        response = supabase_client.rpc("match_documents", {"query_embedding": query_embedding, "match_threshold": 0.7, "match_count": 3}).execute()
        docs = response.data
        context_text = "\n\n".join([doc['content'] for doc in docs]) if docs else "No specific DIY documentation found."

        prompt = f"You are a helpful AI mechanic. Answer based on this docs:\n{context_text}\n\nQuestion: {request.query}"
        chat_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={GEMINI_API_KEY}"
        chat_res = requests.post(chat_url, json={"contents": [{"parts": [{"text": prompt}]}]}).json()
        
        return {"success": True, "answer": chat_res["candidates"][0]["content"]["parts"][0]["text"], "retrieved_docs": len(docs)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/ingest_data")
def trigger_ingestion():
    import subprocess
    result = subprocess.run(["python", "rag_ingest.py"], capture_output=True, text=True)
    return {"success": result.returncode == 0, "logs": result.stdout if result.returncode == 0 else result.stderr}

# This allows running the file directly with Python
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
