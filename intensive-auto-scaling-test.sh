#!/bin/bash

EXTERNAL_IP="34.133.156.55"
echo "=== INTENSIVE AUTO-SCALING DEMONSTRATION ==="

# Show initial state
echo "=== INITIAL STATE ==="
kubectl get hpa iris-hpa
kubectl get pods -l app=iris-classification
echo "Resource usage:"
kubectl top pods -l app=iris-classification

echo ""
echo "Starting intensive stress test in 10 seconds..."
sleep 10

# Function to monitor scaling in real-time
start_monitoring() {
    echo "=== STARTING MONITORING ==="
    
    # Monitor HPA every 3 seconds
    while true; do
        clear
        echo "=== REAL-TIME MONITORING ==="
        echo "Timestamp: $(date)"
        echo ""
        echo "HPA STATUS:"
        kubectl get hpa iris-hpa
        echo ""
        echo "PODS:"
        kubectl get pods -l app=iris-classification
        echo ""
        echo "RESOURCE USAGE:"
        kubectl top pods -l app=iris-classification 2>/dev/null || echo "Collecting metrics..."
        echo ""
        echo "Press Ctrl+C to stop monitoring"
        sleep 3
    done
}

# Start monitoring in background
start_monitoring &
MONITOR_PID=$!

# Run very intensive stress test
echo "=== STARTING INTENSIVE STRESS TEST ==="
echo "Configuration: 20 threads, 500 connections, 120 seconds duration"
echo "This should trigger auto-scaling..."

wrk -t20 -c500 -d120s -s high-concurrency-test.lua \
    "http://$EXTERNAL_IP/predict" > results_intensive_auto_scaling.txt

# Stop monitoring
kill $MONITOR_PID

echo ""
echo "=== STRESS TEST COMPLETE ==="
echo "Results:"
cat results_intensive_auto_scaling.txt

echo ""
echo "=== FINAL STATE ==="
kubectl get hpa iris-hpa
kubectl get pods -l app=iris-classification
kubectl top pods -l app=iris-classification

# Wait a bit and check scale-down
echo ""
echo "=== CHECKING SCALE-DOWN (waiting 60 seconds) ==="
sleep 60
echo "After scale-down period:"
kubectl get hpa iris-hpa
kubectl get pods -l app=iris-classification
