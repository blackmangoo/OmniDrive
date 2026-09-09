# OmniDrive API — Quick Start Guide

## Prerequisites
- Python installed with `fastapi`, `uvicorn`, `ultralytics`, `supabase`, `requests`
- Ngrok installed (Microsoft Store) and authenticated
- YOLO model file at `api/models/car_parts_large_v1.pt`

---

## Step 1: Set Environment Variables

Create a `.env` file in the `C:\fyp\OmniDrive\api` folder (this has already been created for you).
It contains your secret keys:
```text
GEMINI_API_KEY="your-gemini-key"
SUPABASE_URL="https://cqeubytgsrxdkfejxvan.supabase.co"
SUPABASE_KEY="your-supabase-service-key"
```

> **Important**: The backend is configured to automatically load these keys using `python-dotenv`. You don't need to manually set them in PowerShell anymore!

## Step 2: Start the Backend

```powershell
cd C:\fyp\OmniDrive\api
python app.py
```

Wait until you see:
```
Model loaded successfully!
Uvicorn running on http://0.0.0.0:7860
```

## Step 3: Start Ngrok Tunnel (New Terminal)

Open a **second** PowerShell window and run:
```powershell
ngrok http 7860 --url https://duchess-duty-slick.ngrok-free.dev
```

## Step 4: Hot Restart the Flutter App

The app will now say **API Online** ✅

---

## API Endpoints

| Endpoint       | Method   | Description                    |
|----------------|----------|--------------------------------|
| `/health`      | GET/POST | API status + model loaded check|
| `/predict`     | POST     | YOLO11 car part classification |
| `/chat`        | POST     | RAG AI Mechanic chatbot        |
| `/ingest_data` | GET      | Trigger RAG database seeding   |

## Static Ngrok Domain
```
https://duchess-duty-slick.ngrok-free.dev
```
This URL never changes. You don't need to update the Flutter app each time.

---

## RAG Chatbot Workflow

The AI Mechanic chatbot uses **Retrieval-Augmented Generation (RAG)** to answer car repair questions:

### Architecture
```
User Question → Gemini Embedding → Supabase pgvector search → Context Retrieval → Gemini 3.6 Flash → Answer
```

### How It Works (Step by Step)

1. **User sends a question** (e.g., "How do I change a tire?")
2. **Embedding**: The backend calls `gemini-embedding-2` API to convert the question into a 768-dimensional vector
3. **Vector Search**: The embedding is sent to Supabase's `match_documents` RPC function which performs cosine similarity search against the `part_docs` table using pgvector
4. **Context Retrieval**: The top 3 matching documents (threshold > 0.7 similarity) are retrieved
5. **Generation**: The retrieved documents + user question are sent to `gemini-3.6-flash` with a system prompt: "You are a helpful AI mechanic"
6. **Response**: The generated answer is returned to the Flutter app

### Database Setup (Supabase)

The RAG system requires a `part_docs` table with pgvector:
```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE part_docs (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  embedding VECTOR(768)
);

CREATE OR REPLACE FUNCTION match_documents(
  query_embedding VECTOR(768),
  match_threshold FLOAT,
  match_count INT
) RETURNS TABLE (id BIGINT, content TEXT, similarity FLOAT)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT part_docs.id, part_docs.content,
         1 - (part_docs.embedding <=> query_embedding) AS similarity
  FROM part_docs
  WHERE 1 - (part_docs.embedding <=> query_embedding) > match_threshold
  ORDER BY part_docs.embedding <=> query_embedding
  LIMIT match_count;
END; $$;
```

### Populating the Knowledge Base

Option A — Run the ingest script locally:
```powershell
$env:GEMINI_API_KEY = "your-key"
$env:SUPABASE_KEY = "your-service-role-key"
cd C:\fyp\OmniDrive\api
python rag_ingest.py
```

Option B — Use the Colab notebook (`fyp_rag_ingest_colab.py`) for bulk ingestion.

### Models Used
| Purpose    | Model                | Dimensions |
|------------|----------------------|------------|
| Embeddings | `gemini-embedding-2` | 768        |
| Chat       | `gemini-3.6-flash`   | N/A        |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Missing API keys` error | Set `$env:GEMINI_API_KEY` and `$env:SUPABASE_KEY` in the SAME terminal |
| `'candidates'` error | Gemini model may be deprecated — check model name in `app.py` |
| Flutter shows `API Offline` | Make sure both `python app.py` AND `ngrok` are running |
| Ngrok browser warning page | Flutter already sends `ngrok-skip-browser-warning` header automatically |
| `No such file: car_parts_large_v1.pt` | Place the model file in `api/` or `api/models/` |
