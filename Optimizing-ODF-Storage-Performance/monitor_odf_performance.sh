#!/bin/bash

echo "=== ODF Performance Monitoring ==="
echo "Timestamp: $(date)"
echo

# Check cluster health
echo "--- Ceph Cluster Health ---"
TOOLBOX_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')
oc exec -n openshift-storage $TOOLBOX_POD -- ceph health detail

echo
echo "--- Storage Utilization ---"
oc exec -n openshift-storage $TOOLBOX_POD -- ceph df

echo
echo "--- OSD Performance ---"
oc exec -n openshift-storage $TOOLBOX_POD -- ceph osd perf

echo
echo "--- Pool Statistics ---"
oc exec -n openshift-storage $TOOLBOX_POD -- ceph osd pool stats

echo
echo "--- PVC Usage ---"
oc get pvc --all-namespaces | grep -E "(Bound|Pending)"

