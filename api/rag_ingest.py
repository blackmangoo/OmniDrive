import os
import time
from supabase import create_client, Client
import google.generativeai as genai

# Setup Supabase client
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://cqeubytgsrxdkfejxvan.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")  # Needs the service_role key to bypass RLS or anon if RLS allows inserts

if not SUPABASE_KEY:
    print("Please set SUPABASE_KEY environment variable.")
    exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Setup Gemini API
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("Please set GEMINI_API_KEY environment variable.")
    exit(1)

genai.configure(api_key=GEMINI_API_KEY)

# Sample DIY Car Repair Knowledge Base (You can replace this with a PDF scraper later)
documents = [
    "How to change a tire: First loosen the lug nuts while the car is on the ground. Then, jack up the car at the designated jacking point. Remove the lug nuts and the tire. Place the spare tire on the hub, hand-tighten the lug nuts, lower the car, and then fully tighten the lug nuts in a star pattern.",
    "Checking engine oil: Make sure the car is on level ground and the engine is cool. Pull out the dipstick, wipe it clean with a rag, reinsert it fully, and pull it out again. The oil level should be between the MIN and MAX marks. If it's low, add oil of the recommended viscosity.",
    "Replacing brake pads: Safely jack up the car and remove the wheels. Remove the caliper bolts and hang the caliper securely (do not let it hang by the brake line). Remove the old brake pads, compress the caliper piston using a C-clamp, install the new pads, and reattach the caliper.",
    "Jump-starting a car: Connect the red cable to the positive terminal of the dead battery, then to the positive terminal of the good battery. Connect the black cable to the negative terminal of the good battery, and the other end to an unpainted metal surface on the dead car. Start the working car, let it run, then start the dead car.",
    "Changing a spark plug: Remove the spark plug wire or ignition coil. Use a spark plug socket and ratchet to unscrew the old spark plug. Check the gap on the new spark plug (if required by your vehicle). Thread the new spark plug in by hand, then tighten with the ratchet. Reattach the wire/coil."
]

print("Generating embeddings and inserting into Supabase...")

for i, doc in enumerate(documents):
    try:
        # Generate embedding using Gemini
        result = genai.embed_content(
            model="models/text-embedding-004",
            content=doc,
            task_type="retrieval_document",
            title=f"DIY Doc {i+1}"
        )
        embedding = result['embedding']
        
        # Insert into Supabase
        # Make sure the table part_docs exists with content (text) and embedding (vector) columns
        response = supabase.table('part_docs').insert({
            "content": doc,
            "embedding": embedding
        }).execute()
        
        print(f"Inserted document {i+1}")
        time.sleep(1) # simple rate limit for free tier
    except Exception as e:
        print(f"Error processing document {i+1}: {e}")

print("Done! The RAG knowledge base is now populated.")
