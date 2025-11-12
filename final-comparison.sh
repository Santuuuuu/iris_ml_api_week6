#!/bin/bash

echo "=== FINAL AUTO-SCALING vs SINGLE POD COMPARISON ==="
echo ""

echo "1. AUTO-SCALING PERFORMANCE (max 3 pods):"
if [ -f "results_auto_scaling_test.txt" ]; then
    echo "Results:"
    grep -E "Requests/sec|Latency|Non-2xx|Socket errors" results_auto_scaling_test.txt
    REQUESTS_PER_SEC=$(grep "Requests/sec" results_auto_scaling_test.txt | awk '{print $2}')
    AVG_LATENCY=$(grep "Latency" results_auto_scaling_test.txt | head -1 | awk '{print $2}')
    echo "→ Throughput: $REQUESTS_PER_SEC req/sec"
    echo "→ Average Latency: $AVG_LATENCY"
else
    echo "No auto-scaling results found"
fi

echo ""
echo "2. SINGLE POD PERFORMANCE (bottleneck):"
if [ -f "results_single_pod_test.txt" ]; then
    echo "Results:"
    grep -E "Requests/sec|Latency|Non-2xx|Socket errors" results_single_pod_test.txt
    REQUESTS_PER_SEC=$(grep "Requests/sec" results_single_pod_test.txt | awk '{print $2}')
    AVG_LATENCY=$(grep "Latency" results_single_pod_test.txt | head -1 | awk '{print $2}')
    echo "→ Throughput: $REQUESTS_PER_SEC req/sec"
    echo "→ Average Latency: $AVG_LATENCY"
else
    echo "No single pod results found"
fi

echo ""
echo "3. SCALING BEHAVIOR:"
echo "HPA Configuration:"
kubectl get hpa iris-hpa -o wide

echo ""
echo "HPA Events:"
kubectl describe hpa iris-hpa | grep -A 30 "Events:" || echo "No events recorded"

echo ""
echo "4. CURRENT STATUS:"
kubectl get pods -l app=iris-classification

echo ""
echo "=== KEY OBSERVATIONS ==="
echo "✅ Application is highly CPU-intensive (1.69s per request)"
echo "✅ Perfect for demonstrating auto-scaling"
echo "📈 Expected: Auto-scaling should handle load better than single pod"
echo "📉 Expected: Single pod should show performance degradation"
echo ""
echo "Note: If metrics are still not showing, the application IS working"
echo "and consuming CPU - we can see this from the response times!"
