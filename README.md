# AgroInsight Edge AI: Coffee Disease Diagnostic System

End-to-end capstone project for smallholder farmers in Rutsiro, Rwanda: a **MobileNetV3** model (trained on JMuBEN) exported to **quantized TFLite**, a **Raspberry Pi** field probe, and a **Flutter** Android app for scans, farm registration, heatmaps, history, and optional **Firebase Firestore** sync when online.

---

## What’s in this repository

| Path | Purpose |
|------|--------|
| `Machine_Learning_Pipeline/` | Local copy of the training notebook (`Capstone_Project.ipynb`). Primary workflow is still the linked **Google Colab** notebook below. |
| `App/agroinsight/` | **Flutter** mobile app (**AgroInsight Edge**): onboarding, dashboard, BLE link to the probe, SQLite storage, sector math, farm heatmap, Firestore sync. |
| `Hardware_Intergration/` | `field_scanner.py` — button-triggered capture on the Pi, **TFLite** inference, console diagnosis (GPIO + `libcamera-jpeg`). |
| `Final_Version.md` | Capstone write-up: objectives, testing narrative, performance table, recommendations, and future work. |

The quantized model file (`agroinsight_mobilenetv3_quantized.tflite`) and `labels.txt` are produced by the training notebook and should be placed where your Pi script and deployment expect them (see **Hardware probe**).

---

## Quick links

- **Google Colab (training + FastAPI / Swagger MVP):** [Open notebook](https://colab.research.google.com/drive/1H3Bt8o7bCTW6ImWP1zTfGbhgimX-4LIf?usp=sharing)
- **Demo video:** [Google Drive](https://drive.google.com/file/d/1QqgHVNTGd_F8X0vIQfMuJUI8mruOS52t/view?usp=sharing)

---

## Machine learning pipeline

### Description

Edge-AI pipeline to detect and classify coffee leaf diseases (**Leaf Rust**, **Leaf Miner**, **Healthy**) using a compact **MobileNetV3** network, with **post-training quantization** to **TFLite** for low-power ARM devices (e.g. Raspberry Pi Zero 2 W) without requiring cloud inference.

### Cloud training and API mockup (Google Colab)

1. Open the Colab link above.
2. Used a GPU runtime (T4 and A100).
3. Run cells in order; the notebook pulls **JMuBEN** via the Kaggle API.
4. The final cells can expose a **FastAPI** service with **Swagger UI** for multipart image upload and JSON diagnosis (same preprocessing as training).

### Local notebook

You can also open `Machine_Learning_Pipeline/Capstone_Project.ipynb` in Jupyter or VS Code for offline inspection; full GPU training is still easiest in Colab.

### ML track requirements (summary)

1. **Data:** `tf.data` with prefetch/shuffle; balanced classes (**Healthy**, **Leaf rust**, **Miner**).
2. **Model:** MobileNetV3, **GlobalAveragePooling2D**, dense **Softmax** head; **Adam** + categorical cross-entropy; **EarlyStopping**.
3. **Evaluation:** Classification report (accuracy, precision, recall, F1) and confusion matrix on a validation split.
4. **MVP:** FastAPI + Swagger in Colab for upload → preprocess → predict → JSON.

### Model results and visualizations

**Class distribution** — balanced training set to reduce majority-class bias.

![Dataset class distribution](https://github.com/user-attachments/assets/342cc737-e257-4668-a415-bf13cfd69b63)

**Preprocessed batch (224×224)** — confirms labels and visible pathology cues.

![Preprocessed samples](https://github.com/user-attachments/assets/940ab199-8658-4d75-9cde-91d4796d1848)

**Training curves** — accuracy/loss; early stopping when validation loss plateaus.

![Training history](https://github.com/user-attachments/assets/342cc737-e220-43c7-96cf-5af12b151d1a)

**Confusion matrix** — diagonal mass vs off-diagonal confusions (e.g. early rust vs healthy).

![Confusion matrix](https://github.com/user-attachments/assets/1bdbb89a-b49a-4a73-ab5b-0bc515d2e50a)

---

## Flutter mobile app (`App/agroinsight`)

Android-focused **Material 3** UI (**AgroInsight Edge**): onboarding flow, dashboard with **SCAN LEAF** (BLE-triggered probe), farm registration, **farm heatmap**, **sector overview**, **history**, and **Sync offline records** when the device has connectivity.

### Main technologies

- **State / UI:** Flutter, Provider, Google Fonts, custom Flutter Flow–style widgets under `lib/flutter_flow/`.
- **Local data:** **SQLite** (`sqflite`) — farms and `disease_records` with optional `is_synced` flag.
- **Probe link:** **Bluetooth LE** (`flutter_blue_plus`) — looks for a peripheral named **`AgroInsight-Probe`** and uses the GATT service/characteristics defined in `lib/services/ble_ingestion_service.dart`.
- **Location:** **Geolocator** + sector logic in `lib/core/geo/sector_math.dart`.
- **Cloud (optional):** **Firebase Core** + **Cloud Firestore** — `FirebaseSyncService` uploads pending rows to the **`farm_scans`** collection in batches; requires a valid Firebase Android setup.

### Run the app (development)

Prerequisites: [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=3.0.0 <4.0.0`), Android SDK, and a device or emulator.

```bash
cd App/agroinsight
flutter pub get
flutter run
```

### Firebase on Android

1. Create a Firebase project and add an Android app with package **`com.example.agroinsight`** (or change `applicationId` in `android/app/build.gradle` to match your Firebase app).
2. Download **`google-services.json`** into `android/app/` (this file is **not** committed in public repos if it contains secrets; team members add their own).
3. The app calls `Firebase.initializeApp()` in `lib/main.dart` inside a **try/catch** so the UI still runs if Firebase is missing or misconfigured; **Firestore sync** only works when initialization succeeds.

### Web note

BLE and native Firebase paths are not fully wired for **web**; the dashboard guards some flows so the project can still be opened in Chrome for UI checks.

More capstone-oriented install and testing narrative lives in **`Final_Version.md`** (e.g. APK distribution, field testing).

---

## Hardware probe (`Hardware_Intergration/field_scanner.py`)

Standalone Pi workflow: **GPIO button** (default pin **17**) triggers **`libcamera-jpeg`** to save **`captures/current_scan.jpg`** at **224×224**, then **TFLite** inference with labels from **`labels.txt`**.

### Pi setup (summary)

1. Raspberry Pi OS Lite (64-bit) on SD card.
2. Camera (e.g. Pi Camera Rev 1.3) and tactile button on **GPIO 17** (as in script).
3. Install dependencies:

   `pip install tflite-runtime gpiozero Pillow numpy`

4. Ensure **`libcamera-jpeg`** is available on the system.
5. Place **`agroinsight_mobilenetv3_quantized.tflite`** under **`models/`** (or adjust `MODEL_PATH`) and **`labels.txt`** next to the script.

The **Flutter** app’s BLE integration expects a companion firmware/service on the probe that matches the UUIDs in `ble_ingestion_service.dart`; `field_scanner.py` is the **local button + inference** reference path. A separate **WiFi / HTTP** probe server is described in **`Final_Version.md`** as an alternative architecture for demos.

---

## Offline data and Firestore sync

- **SQLite tables:** `farms` (name + bounding box), `disease_records` (farm, disease, confidence, lat/lng, `sector_id`, `device_id`, `recorded_at`, `is_synced`).
- **Sync:** When online, pending records (`is_synced = 0`) are written to Firestore **`farm_scans`** with document IDs derived from the local integer id for idempotent retries; see `lib/services/firebase_sync_service.dart`.

---

## Deployment plan

1. **Quantization:** Export Keras → **TFLite** with dynamic range quantization for a small footprint on **512MB** class devices.
2. **Edge inference:** Run the interpreter on the Pi (or equivalent) with field capture pipeline.
3. **Phone:** Acts as UI, BLE client, and local/optional cloud logger rather than running the heavy model on-device in the current design.

Representative latency comparison (from **`Final_Version.md`**):

| Environment | RAM | Model | Approx. inference |
|-------------|-----|--------|-------------------|
| Cloud GPU (T4) | ~16GB | FP32 Keras | ~0.2s |
| Raspberry Pi Zero 2 W | 512MB | INT8 TFLite | ~1.8s |

---

## Recommendations and future work (summary)

- **Cooperatives:** Share a small pool of probes among lead farmers rather than one device per household.
- **Model:** Extend to additional crops or pests; iterate on multi-pathology images.
- **Hardware:** Optional drone or canopy-mounted capture (see **`Final_Version.md`**).

---

## Further reading

- **`Final_Version.md`** — full product narrative, testing strategies, objectives vs results, and repository notes (including references to `probe_server.py` / APK artifacts that may live outside this git tree).
- **`App/agroinsight/README.md`** — default Flutter starter text; **this root README** is the main project entry point.
