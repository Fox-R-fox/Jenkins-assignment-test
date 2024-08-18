#!/bin/bash

# Variables
IMAGE_NAME="$DOCKERHUB_USERNAME/your-app-image:latest"

# Login to Docker Hub
echo "Logging into Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Build Docker Image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$IMAGE_NAME"
