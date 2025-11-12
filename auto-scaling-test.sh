#!/bin/bash

echo "=== Auto-scaling Test (max 3 pods) ==="

# Get external IP
EXTERNAL_IP="34.133.156.55"
echo "Service available at: http://$EXTERNAL_IP"

# Health check
echo "Performing health check..."
curl -s "http://$EXTERNAL_IP/health" | jq . || echo "Health check completed"

# Manual test first
echo "Performing manual test..."
curl -X POST http://$EXTERNAL_IP/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}' | jq . || echo "Manual test completed"

# Function to run test
run_test() {
    local test_name=$1
    local threads=$2
    local connections=$3
    local duration=$4
    local script=$5
    
    echo ""
    echo "=== $test_name ==="
    echo "Threads: $threads, Connections: $connections, Duration: ${duration}s"
    
    # Show current status
    echo "Current pods:"
    kubectl get pods -l app=iris-classification
    
    # Run wrk test
    echo "Starting wrk test..."
    wrk -t$threads -c$connections -d${duration}s -s $script \
        "http://$EXTERNAL_IP/predict" > results_${test_name}.txt
    
    # Show results
    echo "Results:"
    cat results_${test_name}.txt
    
    # Show HPA status
    echo "HPA status:"
    kubectl get hpa iris-hpa
    echo ""
}

# Test sequence with auto-scaling
run_test "test1_light" 2 10 30 "stress-test.lua"
run_test "test2_medium" 4 50 30 "stress-test.lua"
run_test "test3_heavy" 8 100 60 "stress-test.lua"

echo "=== Auto-scaling Test Complete ==="
