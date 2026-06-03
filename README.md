<div align="center">

# 🚗 OmniDrive AI

**An End-to-End Intelligent Automotive Platform**

*Computer Vision · Sensor Fusion · Smart Marketplace · Role-Based Architecture*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-Postgres_17-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![YOLO](https://img.shields.io/badge/YOLO11-Large-FF6F00?logo=yolo&logoColor=white)](https://docs.ultralytics.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Academic-lightgrey)]()

> **Final Year Project** — BS Artificial Intelligence  
> Ammar Akbar · June 2026

</div>

---

## 📋 Overview

OmniDrive AI is a comprehensive automotive platform that bridges the gap between **car enthusiasts**, **technical knowledge**, and the **spare parts ecosystem**. Built as a Flutter mobile application with a Python AI backend and Supabase cloud infrastructure, it delivers four core capabilities:

| Module | What It Does |
|--------|-------------|
| 🔍 **AI Vision** | Identifies 50 car part classes from camera/gallery images using YOLO11-Large |
| ⚡ **Performance Testing** | Measures 0-60, 0-100 km/h, ¼-mile, and braking via GPS + IMU Kalman fusion |
| 🛒 **Marketplace** | Connects customers, vendors, riders, and admins for spare parts commerce |
| 🔐 **RBAC Auth** | Full authentication with email verification, password recovery, and 4 distinct roles |

---

## 🏗️ System Architecture

> Open [`diagrams/architecture_diagram.html`](diagrams/architecture_diagram.html) in a browser for the full interactive version.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         👤 USER LAYER                              │
│   Customer  ·  Vendor  ·  Rider  ·  Admin                         │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ Interacts via Flutter UI
┌───────────────────────────▼─────────────────────────────────────────┐
│                     📱 FLUTTER UI LAYER                            │
│  ┌──────────┐  ┌───────────┐  ┌─────────────┐  ┌──────────────┐   │
│  │ Auth     │  │ AI Vision │  │ Marketplace │  │ Performance  │   │
│  │ Module   │  │ Module    │  │ Module      │  │ Module       │   │
│  │ (8 scr)  │  │ (3 scr)   │  │ (25 scr)    │  │ (10 scr)     │   │
│  └──────────┘  └───────────┘  └─────────────┘  └──────────────┘   │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ Calls Service Layer
┌───────────────────────────▼─────────────────────────────────────────┐
│                     ⚙️ SERVICE LAYER (Dart)                        │
│  PartDetection · Marketplace · SensorFusion · OBD WiFi · PerfRun  │
└──────┬────────────────┬────────────────┬────────────────────────────┘
       │ HTTP POST      │ Supabase SDK   │ Sensor Streams
┌──────▼──────┐  ┌──────▼───────────┐  ┌─▼──────────────────────────┐
│ 🤖 FastAPI  │  │ 🐘 Supabase     │  │ 📡 HARDWARE               │
│  YOLO11-L   │  │  Postgres 17    │  │  GPS (Geolocator)         │
│  /predict   │  │  pgvector       │  │  IMU (Sensors+)           │
│  ~110ms     │  │  Storage        │  │  OBD-II (ELM327 WiFi)     │
│             │  │  RLS + RPCs     │  │  Camera (rear)            │
└─────────────┘  │  13 tables      │  └────────────────────────────┘
                 │ 🔥 Firebase FCM │
                 └─────────────────┘
```

---

## 🗂️ Project Structure

```
OmniDrive/
│
├── api/                                # Python AI Backend
│   ├── main.py                         # FastAPI server with /predict endpoint
│   ├── requirements.txt                # Python dependencies
│   ├── test_inference.py               # Offline inference testing
│   └── models/                         # YOLO11-Large weights (car_parts_large_v1.pt)
│
├── car_parts_scanner/                  # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                   # Entry point — Firebase, Supabase, Camera init
│   │   ├── car_part.dart               # CarPart data model
│   │   ├── part_detection_service.dart # YOLO API integration + scan history
│   │   ├── image_search_screen.dart    # AI Vision search UI
│   │   ├── camera_preview_screen.dart  # Full-screen camera with animated reticle
│   │   │
│   │   ├── auth/                       # 🔐 Authentication & RBAC (9 screens)
│   │   │   ├── auth_gate.dart          #   RBAC routing (session → role → shell)
│   │   │   ├── login_screen.dart       #   Premium animated login
│   │   │   ├── signup_screen.dart      #   Customer registration
│   │   │   ├── vendor_signup_screen.dart  # Vendor registration with business info
│   │   │   ├── pending_approval_screen.dart # Pending review screen (Rider / Vendor)
│   │   │   ├── admin_mfa_screen.dart   #   Admin Multi-Factor Auth (TOTP)
│   │   │   ├── verify_email_screen.dart   # Email verification waiting screen
│   │   │   ├── forgot_password_screen.dart # Password reset request
│   │   │   └── update_password_screen.dart # Deep-linked password update
│   │   │
│   │   ├── marketplace/                # 🛒 Marketplace (22 screens across 4 roles)
│   │   │   ├── marketplace_service.dart   # Unified Supabase CRUD layer
│   │   │   ├── marketplace_models.dart    # Data models (Product, Order, CartItem, etc.)
│   │   │   ├── marketplace_constants.dart # Theme, categories, status enums
│   │   │   ├── customer/               #   Customer: Home, Cart, Checkout, Orders, Category Filter (9 scr)
│   │   │   ├── vendor/                 #   Vendor: Dashboard, Catalogue, Orders (6 screens)
│   │   │   ├── rider/                  #   Rider: Orders (3 screens)
│   │   │   └── admin/                  #   Admin: Shell, Orders, Approvals, Profile (4 screens)
│   │   │
│   │   └── performance/               # ⚡ Performance Testing (10 files)
│   │       ├── sensor_fusion_service.dart  # 1-D Kalman filter (GPS + IMU)
│   │       ├── obd_wifi_service.dart       # ELM327 TCP/IP OBD-II client
│   │       ├── performance_run_service.dart # Test orchestration & timing
│   │       ├── performance_models.dart     # Data models for runs & metrics
│   │       ├── performance_home_screen.dart # Module entry with vehicle cards
│   │       ├── metric_selection_screen.dart # Choose test type (0-100, ¼-mile, etc.)
│   │       ├── pre_test_screen.dart        # Calibration & readiness checks
│   │       ├── live_test_screen.dart       # Real-time gauge during test
│   │       ├── results_screen.dart         # Post-test results with stats
│   │       └── run_history_screen.dart     # Historical test runs
│   │
│   ├── assets/icon/                    # App launcher icon source
│   ├── android/                        # Android config (adaptive icons, manifest)
│   ├── ios/                            # iOS config (Info.plist, AppIcon)
│   └── pubspec.yaml                    # Flutter dependencies & icon config
│
├── diagrams/                           # 📊 Architecture & Progress Diagrams
│   ├── architecture_diagram.html       # Interactive 6-layer system architecture
│   └── progress_gap_analysis.html      # Feature completion tracker (FYP-1 vs FYP-2)
│
├── dataset1/                           # Training dataset (26,820 images, 50 classes)
├── kaggle_notebooks/                   # Model training Jupyter notebooks
├── proposal/                           # FYP proposal & defense presentations
├── docs/                               # Legacy diagrams
├── firebase/                           # Firebase configuration
└── README.md                           # ← You are here
```

**File count:** 49 Dart source files · 109 `main.py` lines · 13 database tables

---

## 🧠 Module 1 — AI Visual Recognition

### Model Specifications

| Property | Value |
|----------|-------|
| Architecture | YOLO11 Large (`yolo11l-cls`) |
| Training Data | 26,820 images across 50 classes |
| Training Platform | Kaggle GPU (100 epochs) |
| Top-1 Accuracy | **99.1%** (validation set) |
| Inference Time | ~110ms on CPU |
| Weight File | `api/models/car_parts_large_v1.pt` |

### 50 Recognised Car Part Classes

<details>
<summary>Click to expand all 50 classes</summary>

Air Compressor · Alternator · Battery · Brake Caliper · Brake Pad · Brake Rotor · Camshaft · Carburetor · Clutch Plate · Coil Spring · Crankshaft · Cylinder Head · Distributor · Engine Block · Engine Valve · Fuel Injector · Fuse Box · Gas Cap · Headlights · Idler Arm · Ignition Coil · Instrument Cluster · Leaf Spring · Lower Control Arm · Muffler · Oil Filter · Oil Pan · Oil Pressure Sensor · Overflow Tank · Oxygen Sensor · Piston · Pressure Plate · Radiator · Radiator Fan · Radiator Hose · Radio · Rim · Shift Knob · Side Mirror · Spark Plug · Spoiler · Starter · Taillights · Thermostat · Torque Converter · Transmission · Vacuum Brake Booster · Valve Lifter · Water Pump · Window Regulator

</details>

### How It Works

```
📷 User captures/selects image
     │
     ▼
📤 Flutter sends multipart POST → FastAPI /predict
     │
     ▼
🤖 YOLO11-L processes image → top-5 predictions
     │
     ▼
📊 Results displayed with confidence bars (≥60% threshold)
     │
     ▼
💾 Scan saved to Supabase (image → Storage, record → scan_history)
```

---

## ⚡ Module 2 — Performance & Sensor Fusion

Real-time vehicle performance measurement using **GPS + IMU sensor fusion** with a 1-D Kalman filter.

### Supported Tests

| Test | Measurement | Method |
|------|-------------|--------|
| 0-60 km/h | Time (seconds) | Speed milestone detection |
| 0-100 km/h | Time (seconds) | Speed milestone detection |
| ¼-Mile | Time + Trap Speed | Trapezoidal distance integration |
| Braking | Distance (meters) | Reverse Kalman (sign inversion) |

### Kalman Filter Design

```
┌─────────────┐                ┌─────────────┐
│ IMU Accel   │  50Hz predict  │   Kalman     │  Smooth
│ (Sensors+)  │ ──────────────▶│   Filter     │──────▶ Speed
│ Linear,     │                │  x̂ₖ, Pₖ     │  (km/h)
│ gravity-free│                └──────▲───────┘
└─────────────┘                       │ 1-10Hz update
                               ┌──────┴───────┐
                               │  GPS Speed   │
                               │ (Geolocator) │
                               └──────────────┘
```

**Tuning parameters:** `q = 0.3` (process noise) · `r = 1.2` (measurement noise)

### OBD-II Integration

- **Adapter:** ELM327 WiFi (TCP socket at `192.168.0.10:35000`)
- **Protocol:** AT command init → PID `010D` polling → hex response parsing → km/h
- **Use case:** Provides ground-truth vehicle speed when connected; GPS/IMU fusion used as fallback

---

## 🛒 Module 3 — Marketplace Platform

A full-featured e-commerce module with **4 distinct role-based experiences**, powered by Supabase with Row Level Security.

### Role-Based Architecture

| Role | Screens | Key Features |
|------|---------|-------------|
| 🛍️ **Customer** | 9 | Browse products, category filters, cart, checkout, order tracking, profile |
| 🏪 **Vendor** | 6 | Revenue dashboard, product catalogue CRUD, order processing |
| 🚚 **Rider** | 3 | Accept/reject orders, delivery queue, status updates |
| 🔑 **Admin** | 4 | Vendor/Rider approvals panel, platform-wide order oversight |

### Order Lifecycle

```
📦 Customer places order
     │
     ▼
🏪 Vendor receives notification (FCM) → Confirms & prepares
     │
     ▼
🚚 Rider assigned → Picks up → Delivers
     │
     ▼
✅ Customer receives — Order marked "Delivered"
```

### Key Technical Features

- **Atomic stock management** via `decrement_stock()` Postgres RPC
- **Image upload** with Flutter Image Compress → Supabase Storage
- **Push notifications** via Firebase Cloud Messaging (foreground + background)
- **Shimmer loading** states for a premium UX feel

---

## 🔐 Module 4 — Authentication & RBAC

Fully implemented multi-role authentication system using **Supabase Auth** with Multi-Factor Authentication (MFA) and admin approval gating.

| Feature | Status | Description |
|---------|--------|-------------|
| Email/Password signup & login | ✅ | Standard credentials auth |
| Inline Role selection (Customer / Vendor / Rider) | ✅ | Premium tabbed selector on Login/Signup |
| Vendor-specific signup (business info) | ✅ | Business details field capture |
| Email verification flow | ✅ | Blocks logins until verified |
| Forgot & update password | ✅ | Deep-link recovery workflow |
| RBAC AuthGate routing to shells | ✅ | Automatically loads correct app dashboard |
| Admin MFA (TOTP / Google Authenticator) | ✅ | Compulsory 2FA for Admin console security |
| Admin Approval Gate (Rider / Vendor) | ✅ | New Rider/Vendor signups are locked until Admin approval |
| FCM token registration per user | ✅ | Dynamic push notification routing |
| Row Level Security on all 13 tables | ✅ | Database-enforced isolation |

**Auth Flow:**  
`App Launch → Splash → AuthGate → [No Session? → LoginScreen] → [Session? → Check Role → [If Admin? → Check MFA → Authenticate] → [If Rider/Vendor? → Check Approval Gate] → Route to Shell]`

---

## 🗄️ Database Schema

**Engine:** Supabase (PostgreSQL 17) with `pgvector` extension  
**Tables:** 13 · **RLS:** Enabled on all tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `user_profiles` | User identity & role | `id`, `full_name`, `email`, `role`, `phone`, `avatar_url`, `is_approved` |
| `vendor_profiles` | Vendor business details | `user_id`, `business_name`, `business_address` |
| `user_cars` | User's registered vehicles | `user_id`, `make`, `model`, `year` |
| `car_parts` | 50 YOLO class metadata | `class_name`, `description`, `average_price`, `compatibility_notes` |
| `scan_history` | AI Vision scan logs | `user_id`, `image_url`, `predicted_class`, `confidence` |
| `part_docs` | RAG knowledge base (FYP-2) | `content`, `embedding` (pgvector) |
| `categories` | Marketplace categories | `name`, `icon_name`, `display_order` |
| `products` | Vendor product listings | `vendor_id`, `name`, `price`, `stock`, `image_url` |
| `cart_items` | Shopping cart | `user_id`, `product_id`, `quantity` |
| `orders` | Order headers | `customer_id`, `vendor_id`, `rider_id`, `status`, `total` |
| `order_items` | Order line items | `order_id`, `product_id`, `quantity`, `unit_price` |
| `notifications` | In-app notifications | `user_id`, `title`, `body`, `type` |
| `performance_runs` | Performance test results | `user_id`, `test_type`, `time_seconds`, `speed_data` |

### Database Functions & Triggers

| Name | Type | Purpose |
|------|------|---------|
| `handle_new_user()` | Trigger | Auto-creates `user_profiles` row on signup & formats new rider/vendor records to unapproved |
| `protect_user_profile_fields` | Trigger | RLS helper to prevent unauthorized column changes |
| `decrement_stock()` | RPC | Atomic stock decrement (prevents overselling) |
| `approve_user()` | RPC | Admin approval workflow helper |
| `reject_user()` | RPC | Admin rejection / deletion helper |
| `get_pending_approvals()` | RPC | Fetch details of users awaiting approval |

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.x (stable channel) |
| Python | 3.10+ |
| Android Device | API 21+ (USB debugging enabled) |
| Network | Phone & PC on same WiFi |

### 1. Clone & Setup

```bash
git clone https://github.com/blackmangoo/OmniDrive.git
cd OmniDrive
```

### 2. Start the AI Backend

```bash
cd api
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

> **📌 Note:** The YOLO model weights (`car_parts_large_v1.pt`) must be in `api/models/`.

### 3. Run the Flutter App

```bash
cd car_parts_scanner
flutter pub get
flutter run
```

### 4. Configure Network

Update the API URL in `lib/part_detection_service.dart`:

```dart
// Replace with your PC's WiFi IP (run: ipconfig)
static const String _baseUrl = 'http://YOUR_IP:8000';
```

### 5. Test the API (Optional)

```bash
# Health check
curl http://localhost:8000/

# Predict from file
curl -X POST http://localhost:8000/predict -F "file=@path/to/image.jpg"

# API docs
open http://localhost:8000/docs
```

---

## 📦 Tech Stack & Dependencies

### Python Backend

```
fastapi>=0.115.0        # REST API framework
uvicorn>=0.30.0         # ASGI server
ultralytics>=8.3.0      # YOLO11 inference
Pillow>=11.0.0          # Image processing
python-multipart>=0.0.12 # File upload handling
```

### Flutter App (Key Dependencies)

```yaml
supabase_flutter: ^2.12.0      # Database, Auth, Storage
firebase_core: ^4.7.0           # Firebase initialization
firebase_messaging: ^16.2.0     # Push notifications
camera: ^0.10.5                 # Real-time camera preview
image_picker: ^1.2.1            # Gallery image selection
geolocator: ^14.0.2             # GPS positioning & speed
sensors_plus: ^7.0.0            # IMU accelerometer data
fl_chart: ^1.1.1                # Real-time speed gauges
http: ^1.6.0                    # API communication
permission_handler: ^12.0.1     # Runtime permissions
google_fonts: ^8.0.2            # Typography (Inter)
shimmer: ^3.0.0                 # Loading placeholders
cached_network_image: ^3.4.1    # Image caching
flutter_image_compress: ^2.4.0  # Upload optimization
flutter_local_notifications: ^21.0.0  # Local notifications
connectivity_plus: ^7.0.0       # Network state monitoring
shared_preferences: ^2.5.4      # Local key-value storage
audioplayers: ^6.6.0            # Audio feedback
badges: ^3.2.0                  # Badge notifications
intl: ^0.20.2                   # Internationalization
```

---

## 📊 Project Progress

> Open [`diagrams/progress_gap_analysis.html`](diagrams/progress_gap_analysis.html) for the full interactive dashboard.

### FYP-1 (Current Semester) — ~78% Complete

| Module | Status | Progress |
|--------|--------|----------|
| Authentication & RBAC | ✅ Complete | █████████████████████ 100% |
| AI Vision (YOLO11) | ✅ Complete | █████████████████████ 100% |
| Marketplace Platform | ✅ Complete | █████████████████████ 100% |
| Database & Cloud Infra | ✅ Complete | ████████████████████░ 95% |
| Performance & Sensor Fusion | 🔶 Mostly Done | █████████████████░░░ 85% |
| UI / UX Design | ✅ Complete | █████████████████████ 100% |

### FYP-2 (Next Semester) — Planned

| Module | Status | Description |
|--------|--------|-------------|
| 🧠 RAG Knowledge Base | 🟣 Planned | Document chunking → pgvector → Semantic search → LLM assistant |
| 🔑 Advanced Auth | 🟣 Planned | Google Sign-In, social OAuth, admin web panel |
| 🚀 Cloud Deployment | 🟣 Planned | FastAPI → Cloud Run, geospatial search, Play Store release |
| 🧪 Testing & QA | 🟣 Planned | Unit tests, integration tests, Sentry error tracking |

---

## 🔧 Known Issues & Technical Debt

| Issue | Severity | Notes |
|-------|----------|-------|
| Hardcoded FastAPI URL | ⚠️ Medium | Must update `_baseUrl` when WiFi IP changes |
| `decrement_stock` is `SECURITY DEFINER` | ⚠️ Medium | Should migrate to `SECURITY INVOKER` |
| Kalman filter tuning | 🔶 Low | `q`/`r` parameters need calibration with real driving data |
| Supabase free-tier pausing | ℹ️ Info | Project pauses after inactivity; manual restore required |

---

## 🎨 Design Philosophy

- **Dark premium theme** (`#0A0A0F` background) with cyan accents (`#4FC3F7`)
- **Smooth micro-animations** and transitions throughout
- **Shimmer loading** placeholders for perceived performance
- **Google Fonts** (Inter) for modern, clean typography
- **Adaptive app icon** generated for all Android density buckets + iOS sizes
- **Role-specific navigation shells** — each role sees only what they need

---

## 👨‍💻 Author

**Ammar Akbar**  
BS Artificial Intelligence — Final Year Project  
GitHub: [@blackmangoo](https://github.com/blackmangoo)

---

<div align="center">
<sub>Built with ❤️ using Flutter · FastAPI · YOLO11 · Supabase · Firebase</sub>
</div>
