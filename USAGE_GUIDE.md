# How to Use the Docker Files — Complete Guide

## Prerequisites
- Docker Desktop installed (Windows/Mac) or Docker Engine (Linux)
- Docker Compose installed (included with Docker Desktop)
- Your project directory with the created files

## Files Overview

```
OmniDrive/
├── Dockerfile                  # Build recipe for the API container
├── .dockerignore               # Excludes large files from build context
├── docker-compose.yml          # Development setup (DEFAULT)
├── docker-compose.override.yml # Auto-loaded development tweaks
├── docker-compose.prod.yml     # Production configuration
├── DOCKER_QUICKSTART.ps1       # Command reference
└── DOCKER_BEST_PRACTICES.md    # Detailed explanations
```

---

## 🚀 Option 1: Development Mode (EASIEST FOR BEGINNERS)

This is the simplest way to start. The API will reload automatically when you change code.

### Step 1: Open Terminal/PowerShell
Navigate to your project root:
```powershell
cd D:\OmniDrive
```

### Step 2: Start the Containers
```powershell
docker-compose up
```

**What happens:**
1. Docker reads `docker-compose.yml`
2. Automatically loads `docker-compose.override.yml` (development tweaks)
3. Builds the image (first time takes 3-5 minutes)
4. Starts the API container on port 8000
5. Mounts your source code for hot reload

### Step 3: Verify It's Running
Open a new terminal and run:
```powershell
curl http://localhost:8000/
```

Expected response:
```json
{
  "status": "online",
  "message": "Car Parts Classification API is Running",
  "model_loaded": true
}
```

Or visit in browser: **http://localhost:8000/docs** (interactive Swagger UI)

### Step 4: Stop the Container
In the original terminal, press `Ctrl+C`:
```
Gracefully stopping... (press Ctrl+C again to force)
```

Or in another terminal:
```powershell
docker-compose down
```

---

## 🏭 Option 2: Production Mode (OPTIMIZED)

For running like a real server with multiple workers and auto-restart.

### Step 1: Start Production
```powershell
docker-compose -f docker-compose.prod.yml up -d
```

**Flags:**
- `-f docker-compose.prod.yml` — Use production config
- `-d` — Run in background (detached)

### Step 2: Check Status
```powershell
docker-compose -f docker-compose.prod.yml ps
```

Output:
```
NAME                    STATUS              PORTS
omnidrive-api-prod      Up 2 minutes        0.0.0.0:8000->8000/tcp
```

### Step 3: View Logs
```powershell
# Follow logs in real-time
docker-compose -f docker-compose.prod.yml logs -f api

# View last 50 lines
docker-compose -f docker-compose.prod.yml logs --tail 50 api
```

### Step 4: Stop Production
```powershell
docker-compose -f docker-compose.prod.yml down
```

---

## 🛠️ Option 3: Manual Docker Build & Run

If you don't want to use docker-compose, build and run manually.

### Step 1: Build the Image
```powershell
docker build -t omnidrive-api:latest .
```

**What this does:**
- Reads the `Dockerfile`
- Executes all commands (install dependencies, copy code, etc.)
- Creates an image named `omnidrive-api` with tag `latest`

**Output (final lines):**
```
=> => naming to docker.io/library/omnidrive-api:latest
```

### Step 2: Run the Container
```powershell
docker run -d `
  --name omnidrive-api `
  -p 8000:8000 `
  -v ${PWD}/api/models:/app/models:ro `
  omnidrive-api:latest
```

**Flags explained:**
- `-d` — Run detached (background)
- `--name omnidrive-api` — Container name (for reference)
- `-p 8000:8000` — Map port 8000 from host to container
- `-v ${PWD}/api/models:/app/models:ro` — Mount models (read-only)
- `omnidrive-api:latest` — Image to run

### Step 3: Check if Running
```powershell
docker ps
```

### Step 4: View Logs
```powershell
docker logs -f omnidrive-api
```

### Step 5: Stop the Container
```powershell
docker stop omnidrive-api
docker rm omnidrive-api
```

---

## 🧪 Testing the API

### Test 1: Health Check
```powershell
curl http://localhost:8000/
```

### Test 2: Interactive Docs
Visit in your browser:
```
http://localhost:8000/docs
```

Then:
1. Click the **`POST /predict`** endpoint
2. Click **"Try it out"**
3. Click **"Choose File"** and select an image
4. Click **"Execute"**

Response example:
```json
{
  "success": true,
  "top_prediction": "Brake Pad",
  "top_confidence": 87.43,
  "all_predictions": [
    {"class": "Brake Pad", "confidence": 87.43},
    {"class": "Brake Rotor", "confidence": 8.21},
    {"class": "Brake Caliper", "confidence": 3.01},
    {"class": "Oil Filter", "confidence": 0.89},
    {"class": "Spark Plug", "confidence": 0.46}
  ],
  "inference_time_ms": 112.45
}
```

### Test 3: Upload Image via PowerShell
```powershell
$imagePath = "D:\path\to\your\image.jpg"
curl.exe -X POST http://localhost:8000/predict -F "file=@$imagePath"
```

### Test 4: Upload Image via Python
```python
import requests

with open('image.jpg', 'rb') as f:
    response = requests.post(
        'http://localhost:8000/predict',
        files={'file': f}
    )
    print(response.json())
```

---

## 📊 Viewing Logs & Debugging

### View Container Logs
```powershell
# Follow logs (real-time)
docker-compose logs -f api

# View last 100 lines
docker-compose logs --tail 100 api

# For manual containers
docker logs -f omnidrive-api
```

### Check Container Status
```powershell
docker-compose ps
```

### Inspect Container Details
```powershell
docker inspect omnidrive-api
```

Shows:
- IP address
- Port mappings
- Environment variables
- Volume mounts
- Health status

### View Resource Usage
```powershell
docker stats omnidrive-api
```

Shows real-time:
- CPU %
- Memory usage
- Network I/O
- Block I/O

---

## 🔄 Making Code Changes (Development)

With development mode running (`docker-compose up`):

### Change 1: Modify `api/main.py`
```python
# Example: change the status message
@app.get("/")
def read_root():
    return {
        "status": "online",
        "message": "Updated message!",  # ← Change this
        "model_loaded": model is not None
    }
```

Save the file → API automatically reloads in ~1 second

Test:
```powershell
curl http://localhost:8000/
```

### Change 2: Update Dependencies
Edit `api/requirements.txt`, add a new package:
```
fastapi>=0.115.0
uvicorn>=0.30.0
ultralytics>=8.3.0
Pillow>=11.0.0
python-multipart>=0.0.12
numpy>=1.26.0  # ← New dependency
```

Rebuild:
```powershell
docker-compose down
docker-compose up --build
```

---

## 🗑️ Cleanup Commands

### Remove Container (but keep image)
```powershell
docker-compose down
```

### Remove Container & Volume Data
```powershell
docker-compose down -v
```

### Remove Image
```powershell
docker rmi omnidrive-api:latest
```

### Remove Unused Images, Networks, Volumes
```powershell
docker system prune
```

### Remove Everything (CAREFUL!)
```powershell
docker system prune -a
```

---

## 🚨 Troubleshooting

### Problem: Port 8000 Already in Use
```
Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:8000 -> 0.0.0.0:0: listen tcp 0.0.0.0:8000: bind: An attempt was made to use a port in a state precluding its use.
```

**Solution:**
Find and stop the process:
```powershell
# Find process using port 8000
Get-NetTCPConnection -LocalPort 8000 | Select-Object -ExpandProperty OwningProcess

# Kill it
Stop-Process -Id <PID> -Force

# Or use different port
docker run -p 8001:8000 omnidrive-api:latest
```

### Problem: Image Build Fails
```
ERROR: failed to solve with frontend dockerfile.v0: failed to read dockerfile
```

**Solution:**
Make sure you're in the project root with `Dockerfile`:
```powershell
ls -Path . -Name Dockerfile  # Verify file exists
docker build -t omnidrive-api:latest .
```

### Problem: Model File Not Found
```
FileNotFoundError: api/models/car_parts_large_v1.pt
```

**Solution:**
Verify the model file exists:
```powershell
Test-Path D:\OmniDrive\api\models\car_parts_large_v1.pt
```

If missing, the Dockerfile COPY will fail. Download or generate the model first.

### Problem: Container Exits Immediately
```powershell
docker logs omnidrive-api
# Shows error then container stops
```

Check the logs:
```powershell
docker-compose logs api
```

Common causes:
- Model file missing
- Python import error
- Syntax error in code

### Problem: Out of Memory / Disk Space
```
ERROR: no space left on device
```

**Solution:**
```powershell
# Check space
docker system df

# Clean up
docker system prune -a
```

---

## 📈 Performance Tips

### Tip 1: Use BuildKit (Faster Builds)
```powershell
$env:DOCKER_BUILDKIT = 1
docker build -t omnidrive-api:latest .
```

### Tip 2: Cache Dependencies Aggressively
Don't change `requirements.txt` unless you update dependencies. The layer is cached and reused.

### Tip 3: Use `.dockerignore`
Already created for you. Prevents copying large files (dataset1/, models/ if >100MB, etc.)

### Tip 4: Production Workers
Use `docker-compose.prod.yml` which runs 4 uvicorn workers:
```yaml
command: uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

Handles 4x more concurrent requests.

### Tip 5: Limit Container Resources
Add to docker-compose.yml:
```yaml
services:
  api:
    # ... existing config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M
```

---

## 🎯 Common Workflows

### Workflow 1: Development Sprint
```powershell
# Start
docker-compose up

# [Make changes to code]
# [API auto-reloads, test in browser/curl]

# When done
Ctrl+C
docker-compose down
```

### Workflow 2: Prepare for Production
```powershell
# Test with production config
docker-compose -f docker-compose.prod.yml up

# Verify API works
curl http://localhost:8000/docs

# Verify logs
docker-compose -f docker-compose.prod.yml logs api

# Stop
docker-compose -f docker-compose.prod.yml down
```

### Workflow 3: Deploy to Server
```powershell
# Build image
docker build -t omnidrive-api:v1.0 .

# Tag for registry
docker tag omnidrive-api:v1.0 yourusername/omnidrive-api:v1.0

# Push to Docker Hub
docker push yourusername/omnidrive-api:v1.0

# On server, pull and run
docker pull yourusername/omnidrive-api:v1.0
docker-compose -f docker-compose.prod.yml up -d
```

### Workflow 4: Debugging
```powershell
# Start in foreground (see logs immediately)
docker-compose up

# In another terminal, send request
curl http://localhost:8000/predict -F "file=@test.jpg"

# Watch logs in first terminal for errors
```

---

## 📞 Next Steps

1. **Start development:** `docker-compose up`
2. **Test the API:** Visit `http://localhost:8000/docs`
3. **Make changes:** Edit code, auto-reload happens
4. **Deploy:** Use `docker-compose.prod.yml` and follow "Deploy to Server"

Questions? Check `DOCKER_BEST_PRACTICES.md` for technical details.
