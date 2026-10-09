from flask import Flask, request, render_template_string, redirect, url_for
import boto3
import os
from botocore.exceptions import ClientError

app = Flask(__name__)

def get_s3_client():
    return boto3.client(
        's3',
        endpoint_url=f"https://{os.environ['BUCKET_HOST']}",
        aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'],
        region_name='us-east-1'
    )

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>ODF Object Storage Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .upload-form { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .file-list { background: #fff; border: 1px solid #ddd; padding: 20px; border-radius: 5px; }
        input[type="file"] { margin: 10px 0; }
        button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 3px; cursor: pointer; }
        button:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>OpenShift Data Foundation Object Storage Demo</h1>
        
        <div class="upload-form">
            <h2>Upload File</h2>
            <form method="post" enctype="multipart/form-data">
                <input type="file" name="file" required>
                <br>
                <button type="submit">Upload to Object Storage</button>
            </form>
        </div>
        
        <div class="file-list">
            <h2>Files in Object Storage</h2>
            {% if files %}
                <ul>
                {% for file in files %}
                    <li>{{ file.name }} ({{ file.size }} bytes) - {{ file.modified }}</li>
                {% endfor %}
                </ul>
            {% else %}
                <p>No files found in the bucket.</p>
            {% endif %}
        </div>
        
        {% if message %}
            <div style="background: #d4edda; color: #155724; padding: 10px; border-radius: 3px; margin: 10px 0;">
                {{ message }}
            </div>
        {% endif %}
    </div>
</body>
</html>
'''

@app.route('/', methods=['GET', 'POST'])
def index():
    message = None
    
    if request.method == 'POST':
        file = request.files['file']
        if file and file.filename:
            try:
                s3 = get_s3_client()
                bucket_name = os.environ['BUCKET_NAME']
                s3.upload_fileobj(file, bucket_name, file.filename)
                message = f"File '{file.filename}' uploaded successfully!"
            except Exception as e:
                message = f"Error uploading file: {str(e)}"
    
    # List files
    files = []
    try:
        s3 = get_s3_client()
        bucket_name = os.environ['BUCKET_NAME']
        response = s3.list_objects_v2(Bucket=bucket_name)
        if 'Contents' in response:
            for obj in response['Contents']:
                files.append({
                    'name': obj['Key'],
                    'size': obj['Size'],
                    'modified': obj['LastModified'].strftime('%Y-%m-%d %H:%M:%S')
                })
    except Exception as e:
        message = f"Error listing files: {str(e)}"
    
    return render_template_string(HTML_TEMPLATE, files=files, message=message)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
