import boto3
import os
from botocore.exceptions import ClientError

def create_s3_client():
    """Create S3 client using environment variables"""
    return boto3.client(
        's3',
        endpoint_url=f"https://{os.environ['BUCKET_HOST']}",
        aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'],
        region_name='us-east-1'
    )

def upload_file(s3_client, bucket_name, file_name, object_name=None):
    """Upload a file to S3 bucket"""
    if object_name is None:
        object_name = file_name
    
    try:
        s3_client.upload_file(file_name, bucket_name, object_name)
        print(f"File {file_name} uploaded successfully to {bucket_name}/{object_name}")
        return True
    except ClientError as e:
        print(f"Error uploading file: {e}")
        return False

def list_objects(s3_client, bucket_name):
    """List objects in S3 bucket"""
    try:
        response = s3_client.list_objects_v2(Bucket=bucket_name)
        if 'Contents' in response:
            print(f"Objects in bucket {bucket_name}:")
            for obj in response['Contents']:
                print(f"  - {obj['Key']} (Size: {obj['Size']} bytes)")
        else:
            print(f"No objects found in bucket {bucket_name}")
    except ClientError as e:
        print(f"Error listing objects: {e}")

if __name__ == "__main__":
    # Create S3 client
    s3 = create_s3_client()
    bucket_name = os.environ['BUCKET_NAME']
    
    # Create a sample file
    with open('app-data.txt', 'w') as f:
        f.write('This is data from my application!\n')
        f.write('Stored in OpenShift Data Foundation Object Storage.\n')
    
    # Upload file
    upload_file(s3, bucket_name, 'app-data.txt')
    
    # List objects
    list_objects(s3, bucket_name)
