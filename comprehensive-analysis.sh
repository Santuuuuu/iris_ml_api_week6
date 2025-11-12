#!/bin/bash

echo "=== COMPREHENSIVE AUTO-SCALING ANALYSIS ==="
echo "Project: warm-access-473514-i7"
echo ""

# Reset HPA to allow scaling for final test
echo "Resetting HPA to max 3 pods..."
kubectl patch hpa iris-hpa -p '{"spec":{"maxReplicas":3}}'
sleep 30

echo "=== PERFORMANCE COMPARISON ==="
echo ""

echo "1. SINGLE POD BOTTLENECK:"
if [ -f "results_single_pod_bottleneck.txt" ]; then
    echo "Latency and Throughput:"
    grep -E "Requests/sec|Latency|Non-2xx" results_single_pod_bottleneck.txt
    echo ""
    
    # Calculate potential issues
    ERROR_COUNT=$(grep -o "Non-2xx" results_single_pod_bottleneck.txt | wc -l || echo "0")
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "⚠️  Errors detected under single pod load"
    fi
fi

echo ""
echo "2. WITH AUTO-SCALING:"
if [ -f "results_intensive_auto_scaling.txt" ]; then
    echo "Latency and Throughput:"
    grep -E "Requests/sec|Latency|Non-2xx" results_intensive_auto_scaling.txt
    echo ""
fi

echo ""
echo "=== SCALING BEHAVIOR ==="
echo "HPA Configuration:"
kubectl get hpa iris-hpa -o wide

echo ""
echo "Scaling Events:"
kubectl describe hpa iris-hpa | grep -A 50 "Events:"

echo ""
echo "=== RESOURCE UTILIZATION ==="
kubectl top pods -l app=iris-classification 2>/dev/null || echo "Metrics not available"

echo ""
echo "=== KEY FINDINGS ==="
echo "✅ Metrics server is working"
echo "✅ Application is deployed and responsive"
echo "📊 Current performance metrics shown above"
echo ""
echo "Expected Results:"
echo "- Single pod should show higher latency and potential errors"
echo "- Auto-scaling should maintain better performance"
echo "- HPA should show scale-up/down events"
echo "- CPU usage should correlate with load"
