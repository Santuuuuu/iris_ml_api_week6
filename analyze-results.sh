#!/bin/bash

echo "=== Stress Test Analysis ==="
echo "Project: warm-access-473514-i7"
echo "Location: us-central1"
echo "Service IP: 34.133.156.55"
echo ""

echo "With Auto-scaling (max 3 pods):"
echo "-----------------------------"
for test in test1_light test2_medium test3_heavy; do
    if [ -f "results_${test}.txt" ]; then
        echo "$test:"
        grep -E "Requests/sec|Transfer/sec|Latency|Non-2xx|Socket errors" results_${test}.txt
        echo ""
    fi
done

echo "With Single Pod Restriction:"
echo "---------------------------"
for test in single_1000 single_2000; do
    if [ -f "results_${test}.txt" ]; then
        echo "$test:"
        grep -E "Requests/sec|Transfer/sec|Latency|Non-2xx|Socket errors" results_${test}.txt
        echo ""
    fi
done

echo "=== Scaling Events ==="
kubectl describe hpa iris-hpa | grep -A 20 "Events:" || echo "No events found"

echo "=== Final Status ==="
kubectl get all -l app=iris-classification
