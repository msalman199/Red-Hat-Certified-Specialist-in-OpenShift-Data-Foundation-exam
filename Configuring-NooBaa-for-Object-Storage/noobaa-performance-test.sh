#!/bin/bash

BUCKET_NAME=$1
ENDPOINT_URL=$2
FILE_SIZE=${3:-1M}
NUM_FILES=${4:-10}

if [ -z "$BUCKET_NAME" ] || [ -z "$ENDPOINT_URL" ]; then
    echo "Usage: $0 <bucket-name> <endpoint-url> [file-size] [num-files]"
    exit 1
fi

echo "Starting performance test..."
echo "Bucket: $BUCKET_NAME"
echo "Endpoint: $ENDPOINT_URL"
echo "File size: $FILE_SIZE"
echo "Number of files: $NUM_FILES"

# Create test files
for i in $(seq 1 $NUM_FILES); do
    dd if=/dev/zero of=test-file-$i.dat bs=$FILE_SIZE count=1 2>/dev/null
done

# Upload test
echo "Starting upload test..."
start_time=$(date +%s)
for i in $(seq 1 $NUM_FILES); do
    aws s3 cp test-file-$i.dat s3://$BUCKET_NAME/ --endpoint-url $ENDPOINT_URL >/dev/null 2>&1
done
end_time=$(date +%s)
upload_duration=$((end_time - start_time))

echo "Upload completed in $upload_duration seconds"

# Download test
echo "Starting download test..."
start_time=$(date +%s)
for i in $(seq 1 $NUM_FILES); do
    aws s3 cp s3://$BUCKET_NAME/test-file-$i.dat downloaded-$i.dat --endpoint-url $ENDPOINT_URL >/dev/null 2>&1
done
end_time=$(date +%s)
download_duration=$((end_time - start_time))

echo "Download completed in $download_duration seconds"

# Cleanup
rm -f test-file-*.dat downloaded-*.dat

echo "Performance test completed!"
