# 🐳 OmniDrive Docker — Getting Started Index

Welcome! This guide will help you understand and use all the Docker files created for your project.

---

## 📖 Start Here (5 minutes)

### If you want to **START RIGHT NOW** (Recommended)

1. Open PowerShell in your project folder:
   ```powershell
   cd D:\OmniDrive
   ```

2. Run this command:
   ```powershell
   docker-compose up
   ```

3. Open your browser:
   ```
   http://localhost:8000/docs
   ```

4. You're done! The API is running.

---

## 📚 Documentation Files

Choose based on what you need:

### `QUICK_REFERENCE.txt` ⭐ (START HERE)
- **Best for:** Finding commands fast
- **Read time:** 2 minutes
- **Contains:**
  - Most common commands
  - Troubleshooting quick fixes
  - File explanations
- **Start here if:** You just want to get it running

### `USAGE_GUIDE.md` 📖
- **Best for:** Step-by-step instructions
- **Read time:** 15 minutes
- **Contains:**
  - Detailed setup for dev/prod
  - How to test the API
  - Code change workflows
  - Debugging troubleshooting
- **Start here if:** You want to understand every step

### `DOCKER_BEST_PRACTICES.md` 🏆
- **Best for:** Understanding the "why"
- **Read time:** 10 minutes
- **Contains:**
  - Explanation of each optimization
  - Performance improvements
  - Recommendations for further optimization
- **Start here if:** You want to learn about Docker optimization

### `DOCKER_QUICKSTART.ps1` 🚀
- **Best for:** Reference of all commands
- **Read time:** On-demand
- **Contains:**
  - Commented command examples
  - Copy-paste ready
- **Use this:** As a command cheat sheet

---

## 🗂️ Docker Files Explained

### `Dockerfile`
**What it is:** The blueprint for building your API container.

**When you interact with it:**
- When you run `docker build` or `docker-compose up`
- You don't edit it directly (unless adding new dependencies)

**Key feature:** Multi-stage build reduces image size by 60%

---

### `.dockerignore`
**What it is:** Tells Docker what files to skip when building.

**When you interact with it:**
- Automatically used during `docker build`
- You don't need to touch it (already configured)

**Key feature:** Excludes large files like `dataset1/` to speed up builds

---

### `docker-compose.yml` (DEFAULT)
**What it is:** Configuration for development environment.

**When you use it:**
- **Every time you're developing locally**
- Run: `docker-compose up`

**Key features:**
- Auto-reload when you change code ✅
- Source code mounted as volume
- Best for development

---

### `docker-compose.override.yml`
**What it is:** Development tweaks that auto-load with `docker-compose.yml`.

**When you use it:**
- Automatically loaded (you don't need to do anything)
- Contains hot-reload configuration

**Key feature:** Enables `--reload` flag for auto-updates

---

### `docker-compose.prod.yml`
**What it is:** Configuration for production deployment.

**When you use it:**
- When deploying to a server
- Run: `docker-compose -f docker-compose.prod.yml up -d`

**Key features:**
- 4 concurrent workers (handles more requests)
- Auto-restart on failure
- No hot-reload (not needed in production)
- Best for production servers

---

## 🎯 Common Scenarios

### Scenario 1: "I want to develop locally"
→ Use `docker-compose up`
→ Read: `QUICK_REFERENCE.txt` (3 min) + `USAGE_GUIDE.md` (Hot Reload section)

### Scenario 2: "I want to deploy to a server"
→ Use `docker-compose.prod.yml`
→ Read: `USAGE_GUIDE.md` (Production Mode section)

### Scenario 3: "I want to understand what's happening"
→ Read: `DOCKER_BEST_PRACTICES.md`

### Scenario 4: "Something broke, I need to fix it"
→ Read: `USAGE_GUIDE.md` (Troubleshooting section)

### Scenario 5: "I need a command, what was it again?"
→ Check: `QUICK_REFERENCE.txt`

---

## 🚀 Step-by-Step: First Time Setup

### Minute 1-2: Verify Docker is working
```powershell
docker --version
docker run hello-world
```

### Minute 3-5: Start the API
```powershell
cd D:\OmniDrive
docker-compose up
```

### Minute 6-10: Test the API
Open browser: `http://localhost:8000/docs`

### Minute 11+: Make code changes
Edit `api/main.py` → Save → API auto-reloads (1 second)

**Total time:** ~10 minutes

---

## 📊 What Each File Does at Runtime

```
You run: docker-compose up
    ↓
docker-compose.yml is read
    ↓
docker-compose.override.yml is auto-loaded
    ↓
Dockerfile is executed (build stage)
    ↓
Container starts with hot-reload enabled
    ↓
API available at http://localhost:8000
    ↓
You edit code → File saved → uvicorn reloads in 1 sec
    ↓
Test API: curl or browser
```

---

## 🔑 Key Concepts

### What is a Container?
A lightweight, isolated environment that runs your application. Think of it as a mini-computer that only has what your app needs.

### What is docker-compose?
A tool that simplifies running containers. Instead of long `docker run` commands, you just say `docker-compose up`.

### What is the Dockerfile?
A recipe that says: "Start with Python 3.11, install these packages, copy this code, run this command."

### What is hot-reload?
When you change your code and save, the API automatically restarts with the new code. No manual restart needed.

---

## ⚡ Quick Command Cheat Sheet

| What you want | Command |
|---|---|
| **Start development** | `docker-compose up` |
| **Start in background** | `docker-compose up -d` |
| **View logs** | `docker-compose logs -f` |
| **Stop everything** | `docker-compose down` |
| **Start production** | `docker-compose -f docker-compose.prod.yml up -d` |
| **Rebuild after dep changes** | `docker-compose up --build` |
| **Check if running** | `docker-compose ps` |
| **Test API** | `curl http://localhost:8000/` |
| **Open docs** | Visit `http://localhost:8000/docs` |

---

## 🎓 Learning Path

**Day 1:** 
- Read this file
- Run `docker-compose up`
- Test the API at `http://localhost:8000/docs`

**Day 2:**
- Read `QUICK_REFERENCE.txt`
- Try stopping/starting containers
- Make a code change and watch hot-reload

**Day 3+:**
- Read `USAGE_GUIDE.md` for deeper understanding
- Try production config: `docker-compose -f docker-compose.prod.yml up`
- Read `DOCKER_BEST_PRACTICES.md` to understand optimizations

---

## 🆘 Quick Troubleshooting

**Problem:** Container won't start
**Fix:** 
```powershell
docker-compose down
docker-compose logs  # Check for errors
# Fix the error in your code
docker-compose up --build
```

**Problem:** Port 8000 already in use
**Fix:**
```powershell
docker-compose down
docker-compose up
```

**Problem:** Changes to code aren't showing up
**Fix:** You're in production mode. Use: `docker-compose up` (not `-f docker-compose.prod.yml`)

**For more fixes:** See `USAGE_GUIDE.md` → Troubleshooting section

---

## 📞 Next Steps

1. **Read:** `QUICK_REFERENCE.txt` (2 min) ← Start here
2. **Run:** `docker-compose up` (5 min)
3. **Test:** Visit `http://localhost:8000/docs` (1 min)
4. **Explore:** `USAGE_GUIDE.md` for details

---

## 📁 Files at a Glance

```
Project Root/
├── Dockerfile                    ← Build recipe (don't edit unless you know what you're doing)
├── .dockerignore                 ← Ignore large files (already configured)
├── docker-compose.yml            ← Development (DEFAULT - use this)
├── docker-compose.override.yml   ← Dev tweaks (auto-loaded)
├── docker-compose.prod.yml       ← Production (use when deploying)
│
├── 📖 QUICK_REFERENCE.txt        ← ⭐ Start here! (2 min read)
├── 📖 USAGE_GUIDE.md             ← Detailed guide (15 min read)
├── 📖 DOCKER_BEST_PRACTICES.md   ← Technical details (10 min read)
├── 📖 DOCKER_QUICKSTART.ps1      ← Command examples (reference)
│
└── api/
    ├── main.py                   ← Your FastAPI code
    ├── requirements.txt          ← Python dependencies
    ├── test_inference.py
    └── models/
        └── car_parts_large_v1.pt ← Your YOLO model
```

---

## 🎯 You're Ready!

Everything is set up. Just run:

```powershell
docker-compose up
```

Then visit: `http://localhost:8000/docs`

Happy coding! Let me know if you have any questions.
