#!/bin/bash

# Variables
DOCKERHUB_USERNAME="foxe03"  # Replace with your Docker Hub username
IMAGE_NAME="$DOCKERHUB_USERNAME/your-app-image:latest"

# Login to Docker Hub using Jenkins-stored PAT
echo "Logging into Docker Hub..."
docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PAT"

# Build Docker Image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$IMAGE_NAME"
