#!/bin/bash

EXTERNAL_IP="34.133.156.55"
echo "=== SINGLE POD BOTTLENECK DEMONSTRATION ==="

# Set HPA to max 1 pod
echo "Restricting to single pod..."
kubectl patch hpa iris-hpa -p '{"spec":{"maxReplicas":1}}'

echo "Waiting for stabilization..."
sleep 30

echo "=== INITIAL SINGLE POD STATE ==="
kubectl get hpa iris-hpa
kubectl get pods -l app=iris-classification
kubectl top pods -l app=iris-classification

echo ""
echo "Starting high-load test on single pod in 10 seconds..."
sleep 10

# Monitor during test
start_monitoring() {
    while true; do
        clear
        echo "=== SINGLE POD LOAD MONITORING ==="
        echo "Timestamp: $(date)"
        echo ""
        echo "HPA (max 1 pod):"
        kubectl get hpa iris-hpa
        echo ""
        echo "POD (single):"
        kubectl get pods -l app=iris-classification
        echo ""
        echo "RESOURCE USAGE (should show high CPU):"
        kubectl top pods -l app=iris-classification 2>/dev/null || echo "Collecting metrics..."
        echo ""
        echo "Press Ctrl+C to stop monitoring"
        sleep 3
    done
}

start_monitoring &
MONITOR_PID=$!

# Run high load on single pod
echo "=== RUNNING HIGH LOAD ON SINGLE POD ==="
echo "This will demonstrate the bottleneck..."
wrk -t25 -c600 -d90s -s high-concurrency-test.lua \
    "http://$EXTERNAL_IP/predict" > results_single_pod_bottleneck.txt

kill $MONITOR_PID

echo ""
echo "=== SINGLE POD RESULTS ==="
cat results_single_pod_bottleneck.txt

echo ""
echo "=== BOTTLENECK EVIDENCE ==="
echo "HPA events (should show unable to scale):"
kubectl describe hpa iris-hpa | grep -A 20 "Events:"

echo "Final resource usage:"
kubectl top pods -l app=iris-classification
