# Initial software product/solution demonstration

# AgroInsight Edge AI: Coffee Disease Diagnostic Model

## 📌 Description
This project is an Edge-AI machine learning pipeline designed to detect and classify coffee leaf diseases (specifically Leaf Rust and Leaf Miner) for smallholder farmers in Rwanda. Built as a Capstone project, it utilizes a deeply optimized MobileNetV3 neural network trained on the JMuBEN dataset. The model is compressed via Post-Training Quantization (TFLite) to run efficiently on low-power, disconnected hardware (Raspberry Pi Zero 2 W) directly in the coffee fields, providing real-time diagnostic insights without requiring an internet connection.

## 🔗 Notebook Link
* **Google Colab Notebook:** [Insert Link to your public/shared Colab Notebook here]

## ⚙️ How to Set Up the Environment and Project

### 1. Cloud Training & API Testing Environment (Google Colab)
To reproduce the training pipeline or test the live API mockup:
1. Open the linked Google Colab notebook.
2. Ensure your runtime is set to a GPU (e.g., T4, V100, or A100).
3. Run the notebook sequentially from top to bottom. The notebook will automatically download the JMuBEN dataset via the Kaggle API.
4. The final cell will launch a background FastAPI server and provide a secure `ngrok`/`colab` link to access the interactive **Swagger UI** for testing image uploads.

### 2. Edge Hardware Environment (Raspberry Pi Zero 2 W)
To deploy the exported `.tflite` model to the physical diagnostic probe:
1. Flash a microSD card with Raspberry Pi OS Lite (64-bit).
2. Connect the Raspberry Pi Camera Rev 1.3 (with manual macro-focus modification) and a 12x12mm tactile button to GPIO 17.
3. Install the lightweight inference dependencies:
   `pip install tflite-runtime gpiozero Pillow numpy`
4. Place the exported `agroinsight_mobilenetv3_quantized.tflite` model and the `field_scanner.py` script into your project directory and execute the script.

## 📊 Breakdown of the ML Track Requirements

### 1. Data Visualization and Data Engineering
The model is trained on a refined subset of the JMuBEN dataset, specifically targeting the diseases most relevant to our deployment scope in Rutsiro.
* **Data Pipeline:** Utilizes TensorFlow's `tf.data` API with aggressive prefetching and shuffling to stream data efficiently without overloading system RAM.
* **Distributions:** The notebook includes Matplotlib bar charts detailing the exact distribution of the three target classes: `Healthy`, `Leaf rust`, and `Miner`, ensuring class balance before training.

### 2. Model Architecture
* **Base Model:** `MobileNetV3` (Chosen specifically for its low parameter count and high efficiency on ARM-based edge CPUs).
* **Preprocessing:** Leverages MobileNetV3's native internal rescaling layer (handling raw 0-255 pixel inputs directly).
* **Custom Top Layers:** * `GlobalAveragePooling2D()` to flatten the feature maps.
  * A dense output layer with a `Softmax` activation function to generate multi-class probability scores.
* **Optimization:** Compiled with the `Adam` optimizer and a categorical cross-entropy loss function. Early Stopping callbacks are injected to prevent overfitting during training.

### 3. Initial Performance Metrics
After training, the model was evaluated against a dedicated validation split. 
* **Metrics Tracked:** The notebook outputs a detailed classification report encompassing **Accuracy, Precision, Recall, and F1-Scores** across all individual classes.
* **Visual Evaluation:** A Seaborn heatmap Confusion Matrix is generated to visualize false-positive and false-negative rates, proving the model's reliability in distinguishing between Rust and Miner damage.

### 4. Deployment Option: Mockup / MVP
For the MVP deployment requirement, this project features an **API UI (Swagger UI)** mockup.
* **Architecture:** Built using `FastAPI` and deployed directly within the Colab environment using dynamic port forwarding. 
* **Functionality:** The Swagger UI provides an interactive web interface where users can upload raw `.jpg` images of coffee leaves. The API receives the multipart file, applies the exact mathematical preprocessing used during training, feeds it into the trained model residing in RAM, and returns a formatted JSON response detailing the diagnosis and confidence score.

## 🚀 Deployment Plan

While the Swagger UI serves as the software MVP, the final production deployment is strictly Edge-based.
1. **Quantization:** The trained Keras model is converted to `.tflite` format using dynamic range quantization, reducing its memory footprint to fit the Pi Zero 2 W's 512MB RAM constraints.
2. **Hardware Integration:** The model will execute locally on a 3D-printed handheld probe. 
3. **Execution:** A farmer presses a tactile button, triggering `libcamera` to capture a macro-focused image. A lightweight Python script runs the image through the `.tflite` interpreter and communicates the diagnosis back to the user without needing cloud connectivity.

## 🎥 Link to Demo Video
* **Watch the Demo:** [Insert YouTube/Google Drive Link Here]
*(Note: This video demonstrates the model training process, the Swagger UI image upload test, and the successful JSON inference output).*
