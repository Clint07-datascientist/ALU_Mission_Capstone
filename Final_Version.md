# AgroInsight Edge AI: Final Product Solution

## 📌 Project Overview
AgroInsight is an offline, Edge-AI agricultural diagnostic tool designed for smallholder farmers. By combining a quantized MobileNetV3 neural network, a Raspberry Pi Zero 2 W hardware probe, and a Flutter mobile application, this solution provides real-time detection of Coffee Leaf Rust and Leaf Miner pathologies completely offline via a localized Wi-Fi hotspot.

## 🔗 Essential Links
* **🎥 5-Minute Product Demo Video:** [Insert YouTube/Drive Link Here] *(Focuses on offline hardware connection, live leaf scanning, actionable insights, and the farm heatmap).*
* **📱 Download Deployed App (APK):** [Insert Link to app-release.apk Here]

---

## 📥 Installation & Setup Instructions

### 1. Mobile App Setup (Android)
1. Download the `app-release.apk` file from the link above.
2. Transfer the APK to your Android device.
3. In your phone's settings, ensure "Install from Unknown Sources" is enabled.
4. Tap the APK file to install the **AgroInsight** app.

### 2. Hardware Probe Setup (Raspberry Pi Zero 2 W)
1. Ensure the Raspberry Pi is powered on and running the `probe_server.py` script.
2. The Pi will broadcast a local offline Wi-Fi hotspot (e.g., `AgroInsight_Probe`).
3. Connect your Android phone to this Wi-Fi network. *(Note: Your phone will warn you that there is no internet connection. This is expected).*
4. Open the AgroInsight app and tap **"SCAN LEAF"** to trigger the physical hardware.

---

## 🧪 Testing Results & Demonstrations

### 1. Functionality Under Different Testing Strategies
To ensure robustness in the field, the system was tested across multiple levels:
* **Unit Testing (UI):** Verified that the Flutter interface smoothly transitions between the Dashboard, Diagnostic Results, and Heatmap screens without lag.
* **Integration Testing (API):** Confirmed the successful HTTP handshake between the Flutter app and the offline Raspberry Pi server.
* **Field/System Testing:** Simulated real-world usage by having the app remotely trigger the Pi's `libcamera` hardware, process the image, and return the JSON payload.
*[Insert Screenshot of the app showing a successful scan result]*

### 2. Functionality With Different Data Values
The Edge AI model was tested against various real-world input conditions to evaluate the limits of its confidence scores:
* **Ideal Inputs:** Clear, macro-focused leaves returned >95% confidence for specific diseases.
* **Edge Case 1 (Blurry/Out-of-focus):** The model correctly dropped its confidence score, preventing false positives.
* **Edge Case 2 (Multiple Pathologies):** When presented with a leaf showing both Rust and Miner damage, the model successfully weighted the more dominant/critical threat (Leaf Rust).
*[Insert 2 Screenshots: One showing a high-confidence prediction and one showing a lower-confidence blurry leaf prediction]*

### 3. Hardware & Software Performance Analysis
Deploying a neural network to a low-power CPU required significant optimization. We tested the model's inference time across different hardware:

| Hardware Specification | RAM | Model Format | Average Inference Time | Environment |
| :--- | :--- | :--- | :--- | :--- |
| **Cloud GPU (T4)** | 16GB | Standard 32-bit Keras | ~0.2 seconds | Google Colab |
| **Raspberry Pi Zero 2 W**| 512MB | INT8 Quantized `.tflite` | ~1.8 seconds | Offline Field Edge |

**Conclusion:** The 1.8-second latency on the Raspberry Pi is an incredible success. By applying Post-Training Quantization, we sacrificed less than 2% model accuracy to gain complete offline independence on a $15 microcomputer.

---

## 📊 Analysis: Objectives vs. Results
Our primary proposal objective was to build a tool that bypassed the lack of reliable 4G internet in rural farming sectors. 
* **Achieved:** We successfully implemented a local Wi-Fi hotspot architecture, allowing the smartphone to act strictly as a UI remote control while the Pi handles the heavy computational lifting. 
* **Achieved:** The inclusion of the "Actionable Insights" and the "Farm Heatmap" successfully elevated the project from a simple classifier to a comprehensive farm management system.
* **Missed/Adapted:** Initially, we considered running the model directly on the phone. However, moving the model to a dedicated, offline hardware probe (Raspberry Pi) proved far more reliable, ensuring consistent camera focus and freeing up smartphone battery life.

---

## 💬 Discussion: Milestones & Impact
This project required hitting three critical milestones: Data Engineering/Model Training, UI/UX Mobile Development, and IoT Hardware Integration. 

The impact of combining these three milestones is significant. By eliminating the need for cloud computing, we removed recurring data costs for the farmers. Real-time, localized data allows Lead Farmers to isolate Leaf Rust outbreaks immediately—protecting not just their crop yield, but the financial stability of the surrounding cooperative.

---

## 🚀 Recommendations & Future Work

**Recommendations for the Community:**
* **Shared Cooperative Hardware:** Individual smallholder farmers do not need to purchase their own probes. Agricultural cooperatives should pool resources to build a few shared diagnostic probes that can be checked out by Lead Farmers for weekly sector sweeps.

**Future Work:**
1. **Multi-Crop Expansion:** The current pipeline can be easily scaled. Future iterations will expand the model architecture to identify pests and diseases in other staple crops, such as building out detection for tomato blights.
2. **Aerial Hardware Integration:** Currently, the probe is handheld. Future work could involve mounting the lightweight Raspberry Pi camera system onto a low-cost drone. By integrating standard smartphone gyroscope and accelerometer data for stabilization, the system could autonomously scan the upper canopies of the trees where handheld probes cannot reach.

---

## 📁 Repository Structure & Related Files
* `/lib/` - Contains the complete Dart/Flutter source code for the mobile app UI.
* `/models/` - Contains the optimized `agroinsight_mobilenetv3_quantized.tflite` Edge AI model.
* `probe_server.py` - The FastAPI Python script that runs locally on the Raspberry Pi.
* `app-release.apk` - The compiled, installable Android application.
