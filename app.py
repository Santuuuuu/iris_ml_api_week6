from flask import Flask, request, jsonify
import numpy as np
import pickle
import os
import time
import logging
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

@app.route('/')
def home():
    return jsonify({
        "message": "IRIS Classification API",
        "endpoints": ["/health", "/metrics", "/predict"],
        "version": "1.0",
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
        
        # Simulate some processing time
        time.sleep(0.01)
        
        prediction = model.predict(features)
        probabilities = model.predict_proba(features)
        
        processing_time = time.time() - start_time
        logger.info(f"Prediction completed in {processing_time:.3f}s")
        
        REQUEST_COUNT.labels('POST', '/predict', '200').inc()
        REQUEST_LATENCY.labels('/predict').observe(processing_time)
        
        response = {
            'prediction': int(prediction),
            'probabilities': probabilities[0].tolist(),
            'processing_time': processing_time,
            'pod': os.environ.get('HOSTNAME', 'unknown')
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        REQUEST_COUNT.labels('POST', '/predict', '500').inc()
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, threaded=True)
