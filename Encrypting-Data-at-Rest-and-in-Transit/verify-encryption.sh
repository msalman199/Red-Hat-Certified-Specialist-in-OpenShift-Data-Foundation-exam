#!/bin/bash

echo "=== Encryption Verification Script ==="
echo

echo "1. Checking encrypted PVC status:"
oc get pvc encrypted-data-pvc -o wide

echo
echo "2. Checking encrypted storage class:"
oc get storageclass ocs-storagecluster-ceph-rbd-encrypted

echo
echo "3. Verifying data is being written to encrypted volume:"
POD_NAME=$(oc get pods -l app=encrypted-data-app -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POD_NAME" ]; then
    echo "Pod: $POD_NAME"
    oc exec $POD_NAME -- wc -l /data/test.txt
else
    echo "No encrypted data app pod found"
fi

echo
echo "4. Checking TLS secret:"
oc get secret secure-app-tls -o yaml | grep -A 2 -B 2 "tls.crt\|tls.key"

echo
echo "5. Verifying secure application:"
SECURE_POD=$(oc get pods -l app=secure-web-app -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$SECURE_POD" ]; then
    echo "Secure pod: $SECURE_POD"
    oc exec $SECURE_POD -- nginx -t
else
    echo "No secure web app pod found"
fi

echo
echo "6. Testing internal HTTPS connectivity:"
oc run curl-test --image=curlimages/curl:latest --rm --restart=Never -- curl -k -s -o /dev/null -w "%{http_code}" https://secure-app-service.default.svc.cluster.local/health

echo
echo "=== Verification Complete ==="
