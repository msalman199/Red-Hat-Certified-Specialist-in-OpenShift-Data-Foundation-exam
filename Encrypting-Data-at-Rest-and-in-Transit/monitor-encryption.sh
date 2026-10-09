#!/bin/bash

echo "Starting encryption monitoring..."
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== Encryption Status Monitor ==="
    echo "Time: $(date)"
    echo
    
    echo "Encrypted PVC Status:"
    oc get pvc encrypted-data-pvc --no-headers
    
    echo
    echo "Secure App Pods:"
    oc get pods -l app=secure-web-app --no-headers
    
    echo
    echo "TLS Secret Age:"
    oc get secret secure-app-tls --no-headers
    
    echo
    echo "Data Growth (encrypted volume):"
    POD_NAME=$(oc get pods -l app=encrypted-data-app -o jsonpath='{.items[0].metadata.name}')
    if [ ! -z "$POD_NAME" ]; then
        oc exec $POD_NAME -- du -sh /data/ 2>/dev/null || echo "Data directory not accessible"
    fi
    
    sleep 10
done
