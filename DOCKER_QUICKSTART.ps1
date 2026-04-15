#!/usr/bin/env powershell

# OmniDrive API - Quick Start Guide
# ==================================

# 1. DEVELOPMENT MODE (with hot reload)
# ======================================
# Run this to start the API with auto-reload on code changes:
#   docker-compose up
#
# Or explicitly use the override:
#   docker-compose -f docker-compose.yml -f docker-compose.override.yml up
#
# The API will be available at: http://localhost:8000
# Interactive docs: http://localhost:8000/docs


# 2. PRODUCTION MODE (optimized, no reload)
# ==========================================
# Run this for production deployment:
#   docker-compose -f docker-compose.prod.yml up -d
#
# This runs with:
#   - 4 worker processes
#   - Auto-restart on failure
#   - Read-only model volume
#   - Health checks enabled


# 3. BUILD THE IMAGE MANUALLY
# ============================
# Build and tag:
#   docker build -t omnidrive-api:latest .
#   docker build -t omnidrive-api:v1.0 .
#
# Build with BuildKit (faster, better caching):
#   docker buildx build -t omnidrive-api:latest --load .


# 4. PUSH TO DOCKER HUB (optional)
# ==================================
# Tag for your registry:
#   docker tag omnidrive-api:latest yourusername/omnidrive-api:latest
#
# Push:
#   docker push yourusername/omnidrive-api:latest


# 5. TEST THE API
# ================
# Health check:
#   curl http://localhost:8000/
#
# Swagger UI:
#   Start server and visit: http://localhost:8000/docs
#
# Predict endpoint (from PowerShell):
#   $file = "path/to/image.jpg"
#   curl.exe -X POST http://localhost:8000/predict `
#     -F "file=@$file"


# 6. VIEW LOGS
# =============
# Follow logs from all services:
#   docker-compose logs -f
#
# Logs from API only:
#   docker-compose logs -f api
#
# Logs from running container:
#   docker logs -f omnidrive-api


# 7. STOP & CLEANUP
# ==================
# Stop containers:
#   docker-compose down
#
# Stop and remove volumes:
#   docker-compose down -v
#
# Remove image:
#   docker rmi omnidrive-api:latest
#
# System cleanup (prune unused images/networks):
#   docker system prune


# 8. ENVIRONMENT SETUP
# =====================
# For Windows development, ensure Docker Desktop is running
# For Linux, ensure Docker daemon is started:
#   sudo systemctl start docker
#
# Verify Docker works:
#   docker --version
#   docker run hello-world
