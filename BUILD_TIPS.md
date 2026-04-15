# Docker Build Troubleshooting

## Issue: Download Timeout (PyTorch/Torch)

The error you saw:
```
ReadTimeoutError: HTTPSConnectionPool(host='files.pythonhosted.org', port=443): Read timed out.
```

This happens when downloading large packages (PyTorch is 530MB+). Network instability or slow connections cause timeouts.

### Solution 1: Retry with Longer Timeout (RECOMMENDED)
Already applied to Dockerfile. Just retry:

```powershell
docker-compose down
docker-compose up --build
```

If it times out again, wait a few minutes and retry. PyPI servers sometimes slow down.

### Solution 2: Use CPU-Only PyTorch (Lighter Download)
If timeout persists, use CPU-only torch (smaller):

Edit `api/requirements.txt` and replace:
```
torch>=1.8.0
torchvision>=0.9.0
```

With:
```
torch>=1.8.0 --index-url https://download.pytorch.org/whl/cpu
torchvision>=0.9.0 --index-url https://download.pytorch.org/whl/cpu
```

Then rebuild:
```powershell
docker-compose up --build
```

### Solution 3: Pre-download Dependencies (Advanced)
Download wheels locally first, then build offline:

```powershell
# Download all dependencies
pip download -r api/requirements.txt -d ./wheels

# Then use local wheels in Dockerfile (modify COPY command)
```

### Solution 4: Use Multi-Stage Cache (Already Implemented)
The Dockerfile uses multi-stage builds. If build fails mid-way, Docker caches successful layers. Retry automatically reuses cached layers and only re-downloads failed packages.

## Issue: Version Attribute Warnings

Fixed! Removed `version: '3.9'` from all docker-compose files. This attribute is deprecated in modern Docker Compose.

## Quick Commands

```powershell
# Retry build
docker-compose up --build

# Clean and start fresh
docker system prune -a
docker-compose up --build

# Check available disk space
docker system df

# View build logs in detail
docker-compose up --build 2>&1 | Tee-Object -FilePath build.log
```

## Network Issues?

If you're behind a corporate proxy or firewall:

1. Check internet connection:
```powershell
ping pypi.org
```

2. Try a different PyPI mirror in Dockerfile:
```dockerfile
RUN pip install --index-url https://mirrors.aliyun.com/pypi/simple/ -r requirements.txt
```

3. Use apt-get mirror (if in China):
```dockerfile
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
```

## Still Failing?

Try this minimal version to isolate the issue:

```powershell
# Test if basic Docker works
docker run -it python:3.11-slim python --version

# Test if pip works
docker run -it python:3.11-slim pip install --upgrade pip

# Build just the base image
docker build -t test-base -f- . <<< "FROM python:3.11-slim
RUN pip install fastapi uvicorn"
```

## Expected Build Time

- **Cold build (first time):** 5-10 minutes (downloads base image + all packages)
- **Rebuild (cached):** 30-60 seconds (reuses cached layers)
- **Network dependent:** Slow internet = longer downloads

Be patient on first build!
