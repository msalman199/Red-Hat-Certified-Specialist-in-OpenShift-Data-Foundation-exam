#!/bin/bash

NAMESPACE="performance-benchmark"
STORAGE_CLASS="ocs-storagecluster-ceph-rbd-high-perf"

echo "=== ODF Performance Benchmark ==="
echo "Starting benchmark at: $(date)"

# Create namespace
oc create namespace $NAMESPACE 2>/dev/null || true

# Deploy benchmark pod
cat << YAML | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: benchmark-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: $STORAGE_CLASS
---
apiVersion: v1
kind: Pod
metadata:
  name: benchmark-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: benchmark
    image: quay.io/openshift/origin-tests:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do sleep 3600; done"]
    volumeMounts:
    - name: benchmark-volume
      mountPath: /benchmark
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
  volumes:
  - name: benchmark-volume
    persistentVolumeClaim:
      claimName: benchmark-pvc
YAML

# Wait for pod to be ready
echo "Waiting for benchmark pod to be ready..."
oc wait --for=condition=Ready pod/benchmark-pod -n $NAMESPACE --timeout=300s

echo "Running performance tests..."

# Random read/write test
echo "--- Random Read/Write Test ---"
oc exec -n $NAMESPACE benchmark-pod -- fio \
  --name=random-rw \
  --ioengine=libaio \
  --rw=randrw \
  --rwmixread=70 \
  --bs=4k \
  --numjobs=4 \
  --size=5G \
  --runtime=120 \
  --directory=/benchmark \
  --group_reporting \
  --output-format=json > random_rw_results.json

# Sequential read test
echo "--- Sequential Read Test ---"
oc exec -n $NAMESPACE benchmark-pod -- fio \
  --name=sequential-read \
  --ioengine=libaio \
  --rw=read \
  --bs=1M \
  --numjobs=1 \
  --size=10G \
  --runtime=60 \
  --directory=/benchmark \
  --group_reporting \
  --output-format=json > sequential_read_results.json

# Sequential write test
echo "--- Sequential Write Test ---"
oc exec -n $NAMESPACE benchmark-pod -- fio \
  --name=sequential-write \
  --ioengine=libaio \
  --rw=write \
  --bs=1M \
  --numjobs=1 \
  --size=10G \
  --runtime=60 \
  --directory=/benchmark \
  --group_reporting \
  --output-format=json > sequential_write_results.json

echo "Benchmark completed at: $(date)"
echo "Results saved to: random_rw_results.json, sequential_read_results.json, sequential_write_results.json"

# Cleanup
echo "Cleaning up benchmark resources..."
oc delete namespace $NAMESPACE

