# ==========================================
# SENTINEL Backend — Production Dockerfile
# ==========================================
# Base Image: Lightweight Python 3.11 slim image
FROM python:3.11-slim

# Set environment variables for optimized python container execution
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ENV=production

# Set the working directory inside the container
WORKDIR /app

# Install lightweight system dependencies (curl for container healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy only the requirements first to leverage Docker layer caching
COPY backend/requirements.txt /app/backend/requirements.txt

# Install python packages
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

# Copy the shared mock datasets (needed by the Ingestion Agent at runtime)
COPY mock-data /app/mock-data

# Copy all backend logic and schemas into the backend directory
COPY backend /app/backend

# Ensure persistent directories are ready
RUN mkdir -p /app/backend/db /app/backend/traces

# Move context to backend folder for command execution
WORKDIR /app/backend

# Expose default API Port (can be overridden by $PORT env variable at runtime)
EXPOSE 8001

# Start uvicorn server dynamically binding to the Port provided by Railway / Render
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8001}"]
