#!/bin/bash

# Retrieve Docker Hub credentials from Jenkins Credentials
DOCKERHUB_USERNAME="foxe03"  # Replace with your Docker Hub username

# Login to Docker Hub using Jenkins-stored PAT
docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PAT"

# Set the image name correctly
IMAGE_NAME="$DOCKERHUB_USERNAME/your-app-image:latest"

# Build Docker Image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$IMAGE_NAME"
