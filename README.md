# 🚗 OmniDrive AI

> **Final Year Project** — BS Computer Science  
> An AI-driven automotive ecosystem combining Computer Vision, RAG, and a Spare Parts Marketplace.

---

## 📋 Project Abstract

OmniDrive AI bridges the gap between car enthusiasts, technical knowledge, and the local spare parts marketplace. It combines:

- **Computer Vision** — YOLO11 Large model trained on 26,820 images across 50 car part classes
- **RAG (Retrieval-Augmented Generation)** — Expert Q&A on automotive topics *(Phase 2)*
- **Sensor Fusion** — Real-time OBD-II/GPS performance analytics *(Phase 3)*
- **Marketplace** — Vendor listings with geospatial search for spare parts *(Phase 2)*

---

## 🗂️ Project Structure

```
OmniDrive/
├── api/                        # FastAPI backend (YOLO11 inference server)
│   ├── main.py                 # FastAPI app with /predict endpoint
│   ├── requirements.txt        # Python dependencies
│   ├── test_inference.py       # Local model testing script
│   └── runs/                   # YOLO training output & model weights
│
├── car_parts_scanner/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart                   # App entry point, camera & Supabase init
│   │   ├── image_search_screen.dart    # Home/Search screen (search bar UI)
│   │   ├── camera_preview_screen.dart  # Full-screen camera scanner
│   │   ├── part_detection_service.dart # YOLO API + Supabase + scan history
│   │   ├── car_part.dart               # CarPart data model
│   │   └── ...
│   ├── android/                # Android-specific config (permissions, manifest)
│   ├── ios/                    # iOS-specific config (Info.plist permissions)
│   └── pubspec.yaml            # Flutter dependencies
│
├── dataset1/                   # Training dataset
│   └── merged/
│       ├── class_counts.csv    # 50 classes, 26,820 total images
│       └── ...
│
└── README.md
```

---

## ✅ Module Status

| Module | Status | Notes |
|---|---|---|
| **1. AI Visual Recognition** | ✅ **Complete** | YOLO11L, 50 classes, FastAPI deployed |
| **2. RAG / Expert Q&A** | 🔲 Phase 2 | `part_docs` table ready, embeddings TBD |
| **3. Performance Analytics** | 🔲 Phase 3 | OBD-II + GPS sensor fusion |
| **4. Marketplace** | 🔲 Phase 2 | Vendors, listings, geospatial search |
| **Auth (all roles)** | 🔲 Phase 1.5 | Supabase Auth — email/password |

---

## 🧠 Module 1 — AI Visual Recognition (DONE)

### Model
- **Architecture:** YOLO11 Large (`yolo11l-cls`)
- **Dataset:** 26,820 images, 50 mechanical car part classes
- **Training:** Kaggle GPU (100 epochs)
- **Reported Accuracy:** 99.1% top-1 validation accuracy
- **Inference time:** ~110ms on CPU (PC host)

### 50 Recognised Classes
Air Compressor, Alternator, Battery, Brake Caliper, Brake Pad, Brake Rotor, Camshaft, Carburetor, Clutch Plate, Coil Spring, Crankshaft, Cylinder Head, Distributor, Engine Block, Engine Valve, Fuel Injector, Fuse Box, Gas Cap, Headlights, Idler Arm, Ignition Coil, Instrument Cluster, Leaf Spring, Lower Control Arm, Muffler, Oil Filter, Oil Pan, Oil Pressure Sensor, Overflow Tank, Oxygen Sensor, Piston, Pressure Plate, Radiator, Radiator Fan, Radiator Hose, Radio, Rim, Shift Knob, Side Mirror, Spark Plug, Spoiler, Starter, Taillights, Thermostat, Torque Converter, Transmission, Vacuum Brake Booster, Valve Lifter, Water Pump, Window Regulator

### Flutter App — Phase 1 Features
- 🔍 Search bar with camera icon (scanner) and gallery icon (picker)
- 📷 Full-screen camera preview with animated reticle + framing tips
- 🖼️ Gallery image picker (iOS & Android)
- 🟢 Live "API Live" status badge (pings `/` endpoint)
- 📊 Top-5 predictions with confidence bars + inference time display
- ✅ 60% confidence gate — rejects low-quality scans with an instructive message
- 💾 Scan history — image uploaded to Supabase Storage, record saved to `scan_history` table

---

## 🗄️ Database Schema (Supabase)

### `car_parts` — 50 rows
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `class_name` | text (unique) | Matches YOLO class label exactly |
| `description` | text | Automotive consultant-style descriptions |
| `average_price` | numeric | **PKR** pricing (Pakistani market) |
| `compatibility_notes` | text | Vehicle-specific fitment notes |

### `scan_history` — grows with usage
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid (nullable) | Populated after Phase 1.5 auth |
| `image_url` | text | Public URL in `scan_images` Supabase Storage bucket |
| `predicted_class` | text | YOLO top-1 prediction |
| `confidence` | numeric(5,2) | e.g. 87.43 |
| `inference_time_ms` | numeric(7,2) | API response time |
| `created_at` | timestamptz | Auto-set |

### `part_docs` — empty (Phase 2 RAG)
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | PK |
| `content` | text | Chunk text for RAG |
| `embedding` | vector | pgvector embeddings |

---

## 🔐 Authentication Roadmap

Four user roles are planned:

| Role | Description | Phase |
|---|---|---|
| **User** | Scans parts, views results, scan history | Phase 1.5 |
| **Vendor** | Lists spare parts, manages inventory | Phase 2 |
| **Admin** | Manages users, vendors, listings | Phase 2 |
| **Rider** | Delivery tracking, order management | Phase 2 |

**Implementation:** Supabase Auth (email/password) with a `user_profiles` table holding a `role` column. RLS policies enforce access control per role.

---

## 🚀 Running the Project

### Prerequisites
- Python 3.10+ with `.venv` active (`d:\OmniDrive\.venv`)
- Flutter SDK (stable channel)
- Phone on same WiFi network as PC
- YOLO model weights at `api/runs/...` (or adjust path in `main.py`)

### 1. Start the FastAPI inference server

```powershell
# From d:\OmniDrive\  (with .venv active)
cd api
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Server starts at `http://0.0.0.0:8000`  
Docs available at `http://localhost:8000/docs`

> **⚠️ Network:** Update `_baseUrl` in `lib/part_detection_service.dart`  
> to your PC's current WiFi IP (`ipconfig` → IPv4 Address).

### 2. Run the Flutter app

```powershell
cd car_parts_scanner
flutter pub get
flutter run                  # deploys to connected device
# or
flutter run -d <device-id>   # specific device
```

### 3. Test the API directly (optional)

```powershell
# Health check
curl http://localhost:8000/

# Predict from file
curl -X POST http://localhost:8000/predict -F "file=@/path/to/image.jpg"
```

---

## 📦 Dependencies

### Python (api/requirements.txt)
```
fastapi>=0.115.0
uvicorn>=0.30.0
ultralytics>=8.3.0
Pillow>=11.0.0
python-multipart>=0.0.12
```

### Flutter (pubspec.yaml key deps)
```yaml
camera: ^latest          # live camera preview
image_picker: ^latest    # gallery selection
http: ^latest            # API calls + multipart upload
http_parser: ^latest     # MIME type for image upload
supabase_flutter: ^latest # database + storage + auth
```

---

## 🗺️ Phase Roadmap

```
Phase 1   ✅  Image Search Module (DONE)
              YOLO11 API · Flutter scanner UI · Scan history storage

Phase 1.5 🔲  Authentication (NEXT)
              Supabase Auth · User role · Login/signup screens
              Link scan_history.user_id to auth.uid()

Phase 2   🔲  Marketplace + RAG
              Vendor listings · Geospatial search · Expert Q&A

Phase 3   🔲  Performance Analytics
              OBD-II sensor fusion · GPS tracking · Dashcam integration
```

---

## 👨‍💻 Author

**Ammar Akbar** — BS Computer Science, Final Year Project  
*Last updated: March 2026*
