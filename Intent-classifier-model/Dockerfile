# Use a slim official Python image
FROM python:3.10-slim

# Prevent Python from writing .pyc files and enable stdout/stderr flushing
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system deps and Python deps
COPY requirements.txt .

RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc libc-dev \
 && pip install --no-cache-dir -r requirements.txt \
 && apt-get remove -y gcc libc-dev \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# Copy app code and model files
COPY . .

# Train the model and create artifact
RUN python3 model/train.py

# Document the port used by the app
EXPOSE 6000

# Start the app with Gunicorn
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:6000", "app:app"]