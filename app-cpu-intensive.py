from flask import Flask, request, jsonify
import numpy as np
import pickle
import os
import time
import logging
import math
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Sample model - replace with your actual IRIS model
class IrisModel:
    def predict(self, features):
        # Simple rule-based model for demo
        if features[0][2] < 2: return 0  # setosa
        elif features[0][2] < 4.8: return 1  # versicolor
        else: return 2  # virginica
    
    def predict_proba(self, features):
        pred = self.predict(features)
        proba = [0.0, 0.0, 0.0]
        proba[pred] = 1.0
        return np.array([proba])

# Initialize model
model = IrisModel()

# Metrics
REQUEST_COUNT = Counter('request_count', 'App Request Count', 
                       ['method', 'endpoint', 'status_code'])
REQUEST_LATENCY = Histogram('request_latency_seconds', 'Request latency', 
                           ['endpoint'])

def cpu_intensive_operation():
    """Perform CPU-intensive calculations to simulate model inference"""
    start_time = time.time()
    
    # Simulate complex model inference with multiple calculations
    result = 0
    for i in range(1000):  # Increased from 100 to 1000 iterations
        # Perform some mathematical operations
        result += math.sqrt(i) * math.sin(i) * math.cos(i)
        result += math.exp(0.01 * i) * math.log(i + 1)
        
        # Matrix multiplication simulation
        matrix_size = 50
        for j in range(matrix_size):
            for k in range(matrix_size):
                result += j * k * 0.001
    
    processing_time = time.time() - start_time
    return result, processing_time

@app.route('/')
def home():
    return jsonify({
        "message": "IRIS Classification API (CPU Intensive)",
        "endpoints": ["/health", "/metrics", "/predict"],
        "version": "2.0",
        "project": "warm-access-473514-i7"
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": time.time(),
        "pod": os.environ.get('HOSTNAME', 'unknown')
    }), 200

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/predict', methods=['POST'])
def predict():
    start_time = time.time()
    
    try:
        data = request.get_json()
        if not data or 'features' not in data:
            REQUEST_COUNT.labels('POST', '/predict', '400').inc()
            return jsonify({'error': 'Missing features in request'}), 400
        
        features = np.array(data['features']).reshape(1, -1)
        
        if features.shape[1] != 4:
            REQUEST_COUNT.labels('POST', '/predict', '400').inc()
            return jsonify({'error': 'Expected 4 features'}), 400
        
        # Perform CPU-intensive operations
        cpu_result, cpu_time = cpu_intensive_operation()
        
        # Get prediction (this also uses some CPU)
        prediction = model.predict(features)
        probabilities = model.predict_proba(features)
        
        total_processing_time = time.time() - start_time
        
        logger.info(f"Prediction completed in {total_processing_time:.3f}s (CPU: {cpu_time:.3f}s)")
        
        REQUEST_COUNT.labels('POST', '/predict', '200').inc()
        REQUEST_LATENCY.labels('/predict').observe(total_processing_time)
        
        response = {
            'prediction': int(prediction),
            'probabilities': probabilities[0].tolist(),
            'processing_time': total_processing_time,
            'cpu_intensive_time': cpu_time,
            'pod': os.environ.get('HOSTNAME', 'unknown'),
            'cpu_calculation_result': round(cpu_result, 4)
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        REQUEST_COUNT.labels('POST', '/predict', '500').inc()
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, threaded=True)
