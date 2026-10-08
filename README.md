<div align="center">

# 🚗 OmniDrive AI
### Unified Edge AI Vision, Real-Time Sensor Fusion Telemetry & Distributed Automotive Marketplace

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.x_CPU-EE4C2C?logo=pytorch&logoColor=white)](https://pytorch.org)
[![YOLO11](https://img.shields.io/badge/YOLO11-Large_(99.34%25_Acc)-FF6F00?logo=ultralytics&logoColor=white)](https://docs.ultralytics.com)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL_15_+_pgvector-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Gemini](https://img.shields.io/badge/Google_Gemini-3.5_Flash_RAG-4285F4?logo=google&logoColor=white)](https://ai.google.dev)
[![Podman](https://img.shields.io/badge/Podman-OCI_Compliant-892CA0?logo=podman&logoColor=white)](https://podman.io)
[![CI/CD](https://img.shields.io/badge/GitHub_Actions-Automated_CI%2FCD-2088FF?logo=githubactions&logoColor=white)](https://github.com/blackmangoo/OmniDrive/actions)

**Final Year Project** · BS Artificial Intelligence, FAST-NUCES  
**Lead Developer:** Ammar Akbar ([@blackmangoo](https://github.com/blackmangoo))

</div>

---

## 📖 Executive Summary

**OmniDrive AI** is a production-grade, distributed automotive engineering ecosystem designed to unify on-device edge computing, deep learning visual diagnostics, physical dynamics telemetry, and multi-tenant commerce into a cohesive mobile experience.

### Core Engineering Capabilities

1. **Edge Computer Vision Diagnostics:** A custom-trained **YOLO11-Large** neural network recognizing **50 discrete automotive mechanical classes** with **99.34% Top-1 Accuracy** on 26,820 empirical images, running on an optimized CPU inference runtime constrained under 280MB RAM.
2. **Physical Dynamics Telemetry (Sensor Fusion):** A custom **2-State Discrete-Time Kalman Filter** ($\mathbf{x} = [v, b]^T$) fusing $50\text{ Hz}$ linear acceleration with $1-10\text{ Hz}$ GNSS Doppler fixes, featuring **Zero-Velocity Updates (ZUPT)**, **Stationary Gravity Vector Isolation**, **Longitudinal Forward Projection**, and **Sub-sample Linear Milestone Interpolation** for millimeter-accurate 0–60 km/h, 0–100 km/h, and quarter-mile benchmarking.
3. **RAG AI Master Mechanic:** A context-grounded retrieval-augmented generation engine leveraging **Supabase pgvector** (768-dimensional embeddings) and **Google Gemini 3.5 Flash** with multi-model fallback to synthesize verified technical repair manuals without hallucination.
4. **Transactional Multi-Tenant Marketplace:** A 4-tier Role-Based Access Control (RBAC) platform (Customer, Vendor, Rider, Admin) protected by **PostgreSQL Row Level Security (RLS)**, **atomic concurrency row-locks for rider claims**, **atomic inventory decrements**, and store-compliant flows (**Apple Sign-In on iOS** and **Account Deletion**).
5. **Modern DevOps & Automation:** Continuous Integration and Continuous Deployment (CI/CD) pipelines via **GitHub Actions** for automated release APK packaging, Pytest test suites, Docker/Podman containerization, and a **24/7 Keep-Alive Heartbeat Daemon** preventing cloud container cold-starts.

---

## 🏗️ High-Level System Architecture

```
                               ┌─────────────────────────────────────────────────────────────┐
                               │                    OmniDrive Mobile Client                  │
                               │                (Flutter Clean Architecture)                 │
                               │  - Presentation Layer (Tappable Motion, Responsive Theming) │
                               │  - Domain Layer (State Machines, Validation, Kalman Logic)   │
                               │  - Data Layer (Supabase PostgREST, REST Multipart, ELM327)  │
                               └──────────────┬──────────────────────────────┬───────────────┘
                                              │                              │
                         HTTPS Multipart POST │                              │ WebSocket / PostgREST
                         (/predict, /chat)    │                              │ (Auth, Orders, Realtime)
                                              ▼                              ▼
                     ┌───────────────────────────────────┐    ┌───────────────────────────────────┐
                     │        FastAPI AI Backend         │    │      Supabase Cloud Platform     │
                     │    (Containerized OCI / Render)   │    │  - PostgreSQL 15 + pgvector (768) │
                     ├───────────────────────────────────┤    │  - GoTrue Auth (OAuth / TOTP MFA) │
                     │ • YOLO11 Large Inference (50 cls) │    │  - Row Level Security (13 Tables) │
                     │ • Asynchronous Lifespan Pre-warm  │    │  - Atomic Postgres RPC Functions  │
                     │ • Mutex-Locked Predictor          │    │  - Realtime WebSocket Channels    │
                     │ • CPU Thread Clamping (<280MB)    │    │  - Storage Buckets (scan_images)  │
                     │ • Gemini 3.5 Flash RAG Controller │    └─────────────────▲─────────────────┘
                     └─────────────────┬─────────────────┘                      │
                                       │                                        │
                                       │ Google Gemini REST                     │ Cosine Similarity RPC
                                       ▼                                        │ (`match_documents`)
                     ┌───────────────────────────────────┐                      │
                     │   Google Generative Language API  │──────────────────────┘
                     │  - `gemini-embedding-2` (768-dim) │
                     │  - `gemini-3.5-flash` (Synthesis) │
                     └───────────────────────────────────┘
```

---

## 🧠 Deep-Dive: Computer Vision & Model Training

### 1. Dataset Construction & Preprocessing
- **Total Volume:** **26,820 verified automotive images** categorized across **50 discrete mechanical classes**.
- **Data Splits:**
  - **Training Set:** 19,251 images (71.8%)
  - **Validation Set:** 5,480 images (20.4%)
  - **Holdout Test Set:** 2,089 images (7.8%)
- **Data Augmentation Strategy:** Applied on-the-fly transformations using `RandAugment`, random erasing (`erasing=0.4`), HSV color-space perturbations (hue=0.015, saturation=0.7, value=0.4), horizontal flipping (`fliplr=0.5`), translation (0.1), and affine scale variations (0.5) to simulate harsh garage lighting, oil stains, and varying camera perspectives.

### 2. Empirical Architecture Comparison & Selection
To determine the optimal architecture for production deployment, three variants of the state-of-the-art **YOLO11** classification family were trained under identical conditions on cloud Tesla P100-PCIE-16GB GPUs:

| Model Variant | Parameters | GFLOPs | Train Epochs | Top-1 Accuracy | Top-5 Accuracy | Decision & Justification |
|:---|:---:|:---:|:---:|:---:|:---:|:---|
| **YOLO11-Medium** (`yolo11m-cls`) | 13.0M | 42.1 | 30 | 99.01% | 99.85% | Sub-optimal Top-1 accuracy compared to Large. |
| **YOLO11-Large** (`yolo11l-cls`) | **12.9M** | **58.2** | **30** | **99.34%** | **99.85%** | **Selected as Champion.** Optimal Pareto frontier of highest Top-1 accuracy and lightweight footprint. |
| **YOLO11-ExtraLarge** (`yolo11x-cls`) | 28.4M | 111.0 | 30 | 99.20% | 99.85% | 2.2x parameter bloat, slower inference latency, and slight validation degradation due to overparameterization. |

### 3. Hyperparameters & Training Dynamics
- **Image Input Size:** $224 \times 224 \times 3$ RGB
- **Optimizer:** `AdamW` (learning rate $\eta = 1.85 \times 10^{-4}$, momentum $\beta_1 = 0.9$, weight decay $\lambda = 5 \times 10^{-4}$)
- **Precision:** Automatic Mixed Precision (`AMP=True`) using FP16 tensor cores.
- **Batch Size:** 16 images per step with gradient accumulation.
- **Convergence:** Top-1 validation accuracy crossed 98.5% within 12 epochs and plateaued at **99.34%** at epoch 28.

### 4. Technical Hurdles & Engineering Solutions
1. **Kaggle Read-Only Virtual Filesystem:**
   - *Hurdle:* Kaggle mounts input datasets in immutable read-only directories (`/kaggle/input`), causing cache creation and training pipelines to fail.
   - *Solution:* Built an automated virtual symlinking pipeline mapping `/kaggle/input/.../{train,valid,test}` directly to dynamic `/kaggle/working/car_parts_dataset` virtual paths.
2. **Cloud Container OOM Crashes (Render 512MB RAM Limit):**
   - *Hurdle:* Standard PyTorch installs bundle ~900MB of CUDA binaries and spawn multi-threaded OpenMP thread pools matching host cores, immediately breaching the 512MB cloud ceiling.
   - *Solution:*
     - Pinned dependencies to CPU-only PyTorch wheels (`--extra-index-url https://download.pytorch.org/whl/cpu`).
     - Restricted CPU thread allocation to 1 worker (`torch.set_num_threads(1)`, `OMP_NUM_THREADS=1`).
     - Restricted memory arenas via `MALLOC_ARENA_MAX=2`.
     - Engineered asynchronous lifespan pre-warming and wrapped inference in `torch.inference_mode()` with an inference mutex lock, maintaining idle RAM at **~85MB** and peak load under **~280MB**.
3. **Mobile Network Upload Latency & 502 Timeouts:**
   - *Hurdle:* High-resolution mobile camera captures (8MB–12MB) caused mobile gateway timeouts.
   - *Solution:* Integrated on-device JPEG compression (`FlutterImageCompress`) in the Flutter data layer, resizing images to $512 \times 512$ at 85% quality before dispatch, reducing payload size by **99.5%** (~45 KB) and cutting upload latency to **<150 ms**.

---

## ⚡ Deep-Dive: 2-State Discrete Kalman Filter Sensor Fusion

Vehicle performance testing cannot rely on raw smartphone GPS alone due to hardware Doppler latency (~160–200 ms) and low update rates (1–5 Hz). Raw accelerometer integration fails due to resting sensor bias, gravitational bleed, and vibration noise. OmniDrive solves this using a custom **2-State Discrete-Time Kalman Filter**.

```
  ┌────────────────────────┐
  │  Resting Calibration   │ ──▶ Sample Gravity Vector g⃗ ──▶ Compute Unit Down Vector û_z
  └────────────────────────┘
              │
              ▼
  ┌────────────────────────┐
  │   50 Hz IMU Stream     │ ──▶ Subtract Vertical Heave: a⃗_h = a⃗ - (a⃗ · û_z) û_z
  │   (Sensors+ Event)     │ ──▶ Project Forward: a_long = a⃗_h · û_fwd
  └───────────┬────────────┘
              │
              ▼
  ┌────────────────────────┐
  │  Kalman Predict Step   │ ──▶ Propagate State: v = v + (a_long - b) · Δt
  │   (Kinematic Prior)    │ ──▶ Propagate Covariance: P = F P Fᵀ + Q(Δt)
  └───────────┬────────────┘
              │
              ▼
  ┌────────────────────────┐
  │ 1-10 Hz GNSS Doppler   │ ──▶ Apply Latency Lead: z_comp = v_gps + a_long · τ_latency
  │     (Geolocator)       │ ──▶ Calculate Dynamic Observation Noise R
  └───────────┬────────────┘ ──▶ Innovation Gate: Outlier Rejection if d² > 16.0 (4σ)
              │
              ▼
  ┌────────────────────────┐
  │   Kalman Update Step   │ ──▶ Compute Gain K = P Hᵀ (H P Hᵀ + R)⁻¹
  │   (Posterior Fusion)   │ ──▶ Correct State: x̂ = x̂ + K y | Update P
  └───────────┬────────────┘
              │
              ▼
  ┌────────────────────────┐
  │ Zero Velocity Update   │ ──▶ If speed < 0.8 km/h & accelerometer quiet:
  │        (ZUPT)          │     Clamp v = 0.0 m/s, Reset P_00, Absorb Bias b
  └────────────────────────┘
```

### Mathematical Formulation (`sensor_fusion_service.dart`)
1. **State Vector:**
   $$\mathbf{x} = \begin{bmatrix} v \\ b \end{bmatrix}$$
   where $v$ is longitudinal velocity ($\text{m/s}$) and $b$ is accelerometer sensor bias along the vehicle axis ($\text{m/s}^2$).
2. **Discrete State Transition & Control:**
   $$F = \begin{bmatrix} 1 & -\Delta t \\ 0 & 1 \end{bmatrix}, \quad B = \begin{bmatrix} \Delta t \\ 0 \end{bmatrix}$$
3. **Dynamic Process Noise Matrix ($Q$):**
   $$Q(\Delta t) = \begin{bmatrix} \sigma_a^2 \cdot \Delta t & 0 \\ 0 & \sigma_b^2 \cdot \Delta t \end{bmatrix}$$
   with acceleration uncertainty $\sigma_a = 0.5\text{ m/s}^2$ and bias drift $\sigma_b = 0.005\text{ m/s}^2/\sqrt{\text{s}}$.
4. **Observation & Latency Lead:**
   $$z_{\text{comp}} = v_{\text{GPS}} + a_{\text{long}} \cdot \tau_{\text{lead}} \quad (\tau_{\text{lead}} = 0.16\text{s})$$
5. **Innovation Gating:**
   $$y = z_{\text{comp}} - \hat{v}, \quad S = P_{00} + R, \quad d^2 = \frac{y^2}{S}$$
   Outliers exceeding $4\sigma$ ($d^2 > 16.0$) with physical divergence $>4.0\text{ m/s}$ are soft-clamped to $3\sqrt{S}$ to prevent satellite multipath jumps from corrupting metrics.
6. **Sub-Sample Milestone Timing:** Linear interpolation calculates exact threshold crossing timestamps between discrete samples:
   $$t_{\text{milestone}} = t_1 + \frac{v_{\text{threshold}} - v_1}{v_2 - v_1} \cdot (t_2 - t_1)$$

---

## 🛠️ Deep-Dive: RAG AI Master Mechanic

Rather than relying on ungrounded language model generation, OmniDrive implements a strict **Domain-Specific RAG Architecture**:

```
                       User Diagnostic Query
                                │
                                ▼
         Google Generative AI: `gemini-embedding-2`
                    (768 Dimensions, Task: Retrieval)
                                │
                                ▼
         Supabase PostgreSQL (`match_documents` RPC)
         Cosine Similarity Search: 1 - (embedding <=> query_vec) > 0.70
                                │
                                ▼
         Verified Technical Context Retrieved (Max 3 Chunks)
                                │
                                ▼
         XML-Demarcated Defensive System Prompt Injection
         <technical_documentation>{context}</technical_documentation>
         <user_question>{query}</user_question>
                                │
                                ▼
         Google Gemini 3.5 Flash Model Synthesis
         (Automatic Fallback: 3.5-flash-lite ➔ flash-lite-latest)
                                │
                                ▼
         Structured, Safe Diagnostic Guidance Rendered in Markdown
```

---

## 🛒 Deep-Dive: Multi-Tenant Marketplace & Security

### Four-Role Access Matrix
- **Customer:** Email/Password, Google OAuth, Apple Sign-In (iOS). Auto-approved (`is_approved = true`).
- **Vendor:** Verified credentials only (social sign-in disabled). Gated (`is_approved = false`) until shop location and license are reviewed by Admin.
- **Rider:** Driver credentials collected. Gated (`is_approved = false`) until Admin verification.
- **Admin:** Universal privileged authentication with TOTP Multi-Factor Authentication (MFA) support. Full dashboard access to approve/reject vendors and riders in 1 tap.

### Database Concurrency Protection
1. **Atomic Rider Claim Lock (`marketplace_service.dart:637`):**
   ```dart
   final updated = await _sb
       .from('orders')
       .update({
         'rider_id': currentUserId,
         'status': 'dispatched',
         'updated_at': DateTime.now().toIso8601String(),
       })
       .eq('id', orderId)
       .isFilter('rider_id', null)
       .eq('status', 'ready')
       .select();

   if (updated.isEmpty) {
     throw Exception('This order was just claimed by another rider.');
   }
   ```
   PostgreSQL executes this as an atomic write lock. Only the first arriving query matches `rider_id IS NULL`; concurrent requests return empty and receive an instant user alert.
2. **Atomic Inventory Decrement:** Handled via PostgreSQL RPC `decrement_stock()` executing `SELECT ... FOR UPDATE` row locks to prevent overselling inventory.
3. **Multi-Vendor Cart Conflict Detection:** The customer cart enforces shop isolation. Adding items from a competing vendor triggers an interactive confirmation modal offering to keep the current cart or start a new order.

---

## 🚀 DevOps, CI/CD & Cloud Infrastructure

### 1. Mobile Pipeline (`.github/workflows/flutter_ci_cd.yml`)
- Triggers on push/PR to `main` and release tags (`v*`).
- Sets up Java 17 and Flutter stable.
- Runs `flutter analyze --no-fatal-infos` (0 errors, 0 warnings).
- Runs `flutter test` (all 7 sensor fusion test cases).
- Builds production Android Release APK (`flutter build apk --release`).
- Publishes `app-release.apk` (60.8 MB) as an downloadable artifact and GitHub Release.

### 2. Backend Pipeline (`.github/workflows/api_ci_cd.yml`)
- Triggers on updates to `api/**`.
- Validates syntax via `python -m py_compile`.
- Executes 10 automated unit tests via `pytest tests/ -v`.
- Verifies OCI container image builds.

### 3. Keep-Alive Uptime Daemon (`.github/workflows/keep_alive.yml`)
- Executes every 14 minutes via GitHub Actions cron (`*/14 * * * *`).
- Dispatches custom-agent heartbeats to `https://omnidrive.onrender.com/health`.
- Keeps the free-tier container warm 24/7, reducing mobile scanner response times from **~50s down to ~2–3s**.

### 4. Containerization (Podman & Docker)
Fully compatible with **Podman** and Docker runtimes:
```bash
# Build with Podman
podman build -t omnidrive-api -f api/Containerfile api/

# Run container locally
podman run -d -p 7860:7860 --env-file api/.env omnidrive-api
```

---

## 🧪 Verification & Empirical Test Evidence

### 1. Automated Test Suites
- **Sensor Fusion Test Suite** (`car_parts_scanner/test/sensor_fusion_test.dart`):
  - `Initial state is at zero velocity`: **PASSED**
  - `Zero Velocity Update (ZUPT) prevents stationary drift under vibration`: **PASSED**
  - `Smoothly tracks a 0 to 100 km/h acceleration pull`: **PASSED**
  - `Deceleration and braking naturally drops speed without sign hack`: **PASSED**
  - `Innovation gating suppresses GPS multipath spikes`: **PASSED**
  - `Accelerometer bias convergence`: **PASSED**
  - `PerformanceRunService Milestone Timing Precision (sub-sample interpolation)`: **PASSED**
  - **Result: 7 of 7 passed (100%).**
- **FastAPI Test Suite** (`api/tests/test_api.py`):
  - `test_health_check_get`: **PASSED**
  - `test_health_check_post`: **PASSED**
  - `test_predict_requires_file`: **PASSED**
  - `test_predict_rejects_non_image`: **PASSED**
  - `test_predict_rejects_corrupted_image`: **PASSED**
  - `test_predict_valid_synthetic_image`: **PASSED**
  - `test_ingest_data_fail_closed_unauthorized`: **PASSED**
  - `test_predict_concurrent_requests`: **PASSED**
  - `test_chat_requires_body`: **PASSED**
  - `test_chat_empty_query_rejected`: **PASSED**
  - **Result: 10 of 10 passed (100%).**
- **Static Analysis:**
  - `flutter analyze` completed with **0 issues, 0 warnings, 0 errors**.

---

## 👨‍💻 Project Metadata & Team

- **Lead Engineer:** Ammar Akbar | FAST-NUCES ([@blackmangoo](https://github.com/blackmangoo))
- **Advisor:** Department of Artificial Intelligence, FAST-NUCES
- **Degree Program:** Bachelor of Science in Artificial Intelligence (FYP 2026)
- **Repository:** [https://github.com/blackmangoo/OmniDrive](https://github.com/blackmangoo/OmniDrive)

---
<div align="center">
<sub>Engineered with precision using Flutter · FastAPI · YOLO11 · PyTorch · Supabase · Google Gemini</sub>
</div>
