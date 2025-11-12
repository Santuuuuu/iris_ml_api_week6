#!/bin/bash

echo "=== Single Pod Restriction Test ==="

# Update HPA to single pod only
echo "Restricting HPA to single pod..."
kubectl patch hpa iris-hpa -p '{"spec":{"maxReplicas":1}}'

echo "Waiting for stabilization..."
sleep 30

# Get external IP
EXTERNAL_IP="34.133.156.55"
echo "Testing single pod at: http://$EXTERNAL_IP"

# Monitor resources during test
monitor_resources() {
    local test_duration=$1
    local end_time=$((SECONDS + test_duration))
    
    while [ $SECONDS -lt $end_time ]; do
        echo "=== Resource Usage ==="
        kubectl top pods -l app=iris-classification 2>/dev/null || echo "Metrics not available yet"
        sleep 10
    done
}

# Test with increasing load on single pod
echo ""
echo "=== Test 1: 1000 requests with 50 concurrent connections ==="
monitor_resources 40 &
MONITOR_PID=$!
wrk -t4 -c50 -d30s -s stress-test.lua "http://$EXTERNAL_IP/predict" > results_single_1000.txt
kill $MONITOR_PID 2>/dev/null

echo "Results for 1000 requests:"
cat results_single_1000.txt

echo ""
echo "=== Test 2: 2000 requests with 100 concurrent connections ==="
monitor_resources 40 &
MONITOR_PID=$!
wrk -t8 -c100 -d30s -s stress-test.lua "http://$EXTERNAL_IP/predict" > results_single_2000.txt
kill $MONITOR_PID 2>/dev/null

echo "Results for 2000 requests:"
cat results_single_2000.txt

# Show bottleneck evidence
echo ""
echo "=== Bottleneck Evidence ==="
echo "HPA status:"
kubectl describe hpa iris-hpa

echo "=== Single Pod Test Complete ==="
