import os
import time
import subprocess
import numpy as np
from PIL import Image
from gpiozero import Button
from tflite_runtime.interpreter import Interpreter

# ---------------------------------------------------------
# HARDWARE & MODEL CONFIGURATION
# ---------------------------------------------------------
BUTTON_PIN = 17
MODEL_PATH = "models/agroinsight_mobilenetv3_quantized.tflite"
LABELS_PATH = "labels.txt"
IMAGE_PATH = "captures/current_scan.jpg"

# Initialize the 12x12mm tactile button (using internal pull-up resistor)
scan_button = Button(BUTTON_PIN, pull_up=True, bounce_time=0.1)

def load_labels(filename):
    with open(filename, 'r') as f:
        return [line.strip() for line in f.readlines()]

def capture_image():
    print("\n📸 Button pressed! Capturing leaf image...")
    # Use libcamera-jpeg to take a fast, hardware-accelerated photo
    # Force it to 224x224 to save the CPU from having to resize a massive 5MP image
    command = [
        "libcamera-jpeg", 
        "-o", IMAGE_PATH, 
        "--width", "224", 
        "--height", "224", 
        "--nopreview", 
        "-t", "1000" # 1 second warmup for auto-exposure
    ]
    subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("✅ Image captured.")

def run_inference(interpreter, labels):
    print("🧠 Analyzing leaf pathology...")
    
    # 1. Load and preprocess the image mathematically 
    img = Image.open(IMAGE_PATH).convert('RGB')
    img_array = np.array(img, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=0)
    
    # (Since MobileNetV3 handles its own scaling internally as we discovered earlier, 
    #  Pass the raw 0-255 pixels directly to the TFLite interpreter!)

    # 2. Feed the image into the Edge AI model
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    
    # 3. Extract the prediction
    predictions = interpreter.get_tensor(output_details[0]['index'])[0]
    predicted_index = np.argmax(predictions)
    confidence = predictions[predicted_index]
    
    # If the model was fully quantized to INT8, we must de-quantize the output 
    # to get a readable percentage.
    if output_details[0]['dtype'] == np.uint8 or output_details[0]['dtype'] == np.int8:
        scale, zero_point = output_details[0]['quantization']
        confidence = (confidence - zero_point) * scale

    print("-----------------------------------------")
    print(f"DIAGNOSIS: {labels[predicted_index]}")
    print(f"CONFIDENCE: {confidence * 100:.2f}%")
    print("-----------------------------------------")
    print("Ready for next scan. Waiting for button press...\n")

# ---------------------------------------------------------
# MAIN EXECUTION LOOP
# ---------------------------------------------------------
if __name__ == "__main__":
    print("Initializing AgroInsight Hardware Probe...")
    
    # Load labels and the TFLite model into the Pi's RAM
    class_names = load_labels(LABELS_PATH)
    tflite_interpreter = Interpreter(model_path=MODEL_PATH)
    tflite_interpreter.allocate_tensors()
    
    print("✅ System Ready. Waiting for tactile button press...")
    
    try:
        while True:
            # Wait continuously until the Lead Farmer presses the physical button
            scan_button.wait_for_press()
            
            capture_image()
            run_inference(tflite_interpreter, class_names)
            
            # Prevent accidental double-clicks from running the model twice
            time.sleep(2) 
            
    except KeyboardInterrupt:
        print("\nSystem shutting down.")