FROM python:3.9-slim

WORKDIR /app

RUN pip install boto3

COPY s3-app.py .

CMD ["python", "s3-app.py"]
