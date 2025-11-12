#!/bin/bash
# Simple monitoring script
while true; do
    clear
    echo "=== AUTO-SCALING MONITOR ==="
    echo "Time: $(date)"
    echo ""
    echo "HPA STATUS:"
    kubectl get hpa iris-hpa 2>/dev/null || echo "HPA not found"
    echo ""
    echo "PODS:"
    kubectl get pods -l app=iris-classification
    echo ""
    echo "METRICS:"
    kubectl top pods -l app=iris-classification 2>/dev/null || echo "Metrics loading..."
    echo ""
    echo "Press Ctrl+C to stop"
    sleep 5
done
