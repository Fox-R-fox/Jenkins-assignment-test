#!/bin/bash

# Variables
IMAGE_NAME="yourdockerhubusername/your-app-image:latest"
DOCKERHUB_USERNAME="yourdockerhubusername"

# Login to Docker Hub
echo "Logging into Docker Hub..."
docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"

# Build Docker Image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$IMAGE_NAME"
