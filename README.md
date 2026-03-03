# Initial software product/solution demonstration

# AgroInsight Edge AI: Coffee Disease Diagnostic Model

## 📌 Description
This project is an Edge-AI machine learning pipeline designed to detect and classify coffee leaf diseases (specifically Leaf Rust and Leaf Miner) for smallholder farmers in Rutsiro, Rwanda. Built as a Capstone project, it utilizes a deeply optimized MobileNetV3 neural network trained on the JMuBEN dataset. The model is compressed via Post-Training Quantization (TFLite) to run efficiently on low-power, disconnected hardware (Raspberry Pi Zero 2 W) directly in the coffee fields, providing real-time diagnostic insights without requiring an internet connection.

## 🔗 Notebook Link
* **Google Colab Notebook:** [Click here](https://colab.research.google.com/drive/1H3Bt8o7bCTW6ImWP1zTfGbhgimX-4LIf?usp=sharing)

## ⚙️ How to Set Up the Environment and Project

### 1. Cloud Training & API Testing Environment (Google Colab)
To reproduce the training pipeline or test the live API mockup:
1. Open the linked Google Colab notebook.
2. Ensure your runtime is set to a GPU (e.g., T4, V100, or A100).
3. Run the notebook sequentially from top to bottom. The notebook will automatically download the JMuBEN dataset via the Kaggle API.
4. The final cell will launch a background FastAPI server and provide a secure link to access the interactive **Swagger UI** for testing image uploads.

### 2. Edge Hardware Environment (Raspberry Pi Zero 2 W)
To deploy the exported `.tflite` model to the physical diagnostic probe:
1. Flash a microSD card with Raspberry Pi OS Lite (64-bit).
2. Connect the Raspberry Pi Camera Rev 1.3 (with manual macro-focus modification) and a 12x12mm tactile button to GPIO 17.
3. Install the lightweight inference dependencies:
   `pip install tflite-runtime gpiozero Pillow numpy`
4. Place the exported `agroinsight_mobilenetv3_quantized.tflite` model and the `field_scanner.py` script into your project directory and execute the script.

## 📊 Breakdown of the ML Track Requirements

### 1. Data Visualization and Data Engineering
The model is trained on a refined subset of the JMuBEN dataset, specifically targeting the diseases most relevant to our deployment scope in Rwanda.
* **Data Pipeline:** Utilizes TensorFlow's `tf.data` API with aggressive prefetching and shuffling to stream data efficiently without overloading system RAM.
* **Distributions:** The dataset is strictly balanced across the three target classes (`Healthy`, `Leaf rust`, and `Miner`) to prevent majority-class bias.

### 2. Model Architecture

* **Base Model:** `MobileNetV3` (Chosen specifically for its low parameter count and high efficiency on ARM-based edge CPUs).
* **Preprocessing:** Leverages MobileNetV3's native internal rescaling layer (handling raw 0-255 pixel inputs directly).
* **Custom Top Layers:** * `GlobalAveragePooling2D()` to flatten the feature maps.
  * A dense output layer with a `Softmax` activation function to generate multi-class probability scores.
* **Optimization:** Compiled with the `Adam` optimizer and a categorical cross-entropy loss function. Early Stopping callbacks are injected to prevent overfitting.

### 3. Initial Performance Metrics
After training, the model was evaluated against a dedicated validation split. 
* **Metrics Tracked:** The notebook outputs a detailed classification report encompassing **Accuracy, Precision, Recall, and F1-Scores** across all individual classes.
* **Visual Evaluation:** A Confusion Matrix is generated to visualize false-positive and false-negative rates, proving the model's reliability in distinguishing between Rust and Miner damage.

### 4. Deployment Option: Mockup / MVP
For the MVP deployment requirement, this project features an **API UI (Swagger UI)** mockup.
* **Architecture:** Built using `FastAPI` and deployed directly within the Colab environment using dynamic port forwarding. 
* **Functionality:** The Swagger UI provides an interactive web interface where users can upload raw `.jpg` images of coffee leaves. The API receives the multipart file, applies the exact native MobileNetV3 mathematical preprocessing used during training, feeds it into the model residing in RAM, and returns a formatted JSON response detailing the diagnosis and confidence score.

---

## 📈 Model Results & Visualizations

To ensure the model is learning the true physiological differences between coffee leaf diseases rather than memorizing background noise, we generated several visualizations throughout the data pipeline and training process.

### 1. Dataset Class Distribution (Bar Graph)
Before training, it is critical to understand the mathematical composition of the dataset.
* **The Bar Graph:** This visualization displays the exact number of images representing `Healthy`, `Leaf rust`, and `Miner` leaves in our training set. 
* **Why it matters:** Ensuring a relatively balanced distribution prevents the neural network from developing a "majority class bias." If the dataset was overwhelmingly healthy leaves, the model could achieve high accuracy by simply guessing "Healthy" every time, which would make the hardware probe useless in actual Rwandan coffee fields.

![Image](https://github.com/user-attachments/assets/342cc737-e257-4668-a415-bf13cfd69b63)

### 2. Preprocessed Coffee Leaf Data (3x3 Grid)
We must verify that the TensorFlow data pipeline correctly loads, scales, and maps the raw JMuBEN images to their respective class labels before feeding them into the model.
* **3x3 Image Grid:** This displays a random batch of data exactly as the neural network sees it at the 224x224 input resolution.
* **Visual Markers:** It confirms that the distinct pathologies—such as the yellow/orange powdery lesions of **Leaf rust** and the irregular, necrotic serpentine trails of the **Miner**—are clearly visible, distinct from one another, and correctly labeled by the algorithm.

![Image](https://github.com/user-attachments/assets/940ab199-8658-4d75-9cde-91d4796d1848)

### 3. Training History: Accuracy & Loss
The model's learning process was tracked across multiple epochs to monitor for convergence and evaluate how well it generalizes to unseen data.
* **Accuracy Curve:** The upward trajectory of the training and validation accuracy graphs proves the optimized MobileNetV3 architecture is successfully extracting the relevant visual feature maps from the leaves.
* **Loss Curve:** The validation loss steadily decreases alongside the training loss. The exact point where the validation loss stops decreasing and flattens out is where the `EarlyStopping` callback automatically halted the training loop. This perfectly locks in the best weights and prevents the model from overfitting the training data.

![Image](https://github.com/user-attachments/assets/329f4996-c220-43c7-96cf-5af12b151d1a)

### 4. Validation Performance: Confusion Matrix
Raw accuracy is not sufficient for an agricultural diagnostic tool. To truly understand the model's real-world viability, we generated a Confusion Matrix evaluating the model against the isolated validation dataset.
* **The Diagonal:** The heavily weighted (darker) diagonal running across the matrix represents correct, high-confidence predictions.
* **Misclassifications:** By examining the off-diagonal squares, we can identify exact failure points—for instance, measuring how often the model mistakenly identifies early-stage Leaf rust as a Healthy leaf. This matrix visually backs up our Precision, Recall, and F1-scores, proving the mathematical reliability of the model prior to compressing it for the Raspberry Pi hardware.

![Image](https://github.com/user-attachments/assets/1bdbb89a-b49a-4a73-bab5-0bc515d2e50a)

---

## 🚀 Deployment Plan

While the Swagger UI serves as the software MVP, the final production deployment is strictly Edge-based.
1. **Quantization:** The trained Keras model is converted to `.tflite` format using dynamic range quantization, reducing its memory footprint to fit the Pi Zero 2 W's 512MB RAM constraints.
2. **Hardware Integration:** The model will execute locally on a custom handheld probe. 
3. **Execution:** A farmer presses a tactile button, triggering `libcamera` to capture a macro-focused image. A lightweight Python script runs the image through the `.tflite` interpreter and communicates the diagnosis back to the user without needing cloud connectivity.

## 🎥 Link to Demo Video
* **Watch the Demo:** [Google Drive Link Here](https://drive.google.com/file/d/1QqgHVNTGd_F8X0vIQfMuJUI8mruOS52t/view?usp=sharing)

