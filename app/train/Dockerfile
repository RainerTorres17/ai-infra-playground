FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app


COPY requirements.txt .


RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install -r requirements.txt \
 && apt-get update && apt-get install -y git \
 && pip install s3fs boto3


COPY . .


ENTRYPOINT ["python", "-u", "app/train/train.py"]