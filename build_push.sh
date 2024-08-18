#!/bin/bash

# Check if Docker is installed, if not, install it
if ! [ -x "$(command -v docker)" ]; then
  echo "Docker is not installed. Installing Docker..."
  
  # Install Docker for Amazon Linux 2 (Adjust for your Linux distribution if needed)
  sudo yum update -y
  sudo yum install docker -y

  # Start Docker service
  sudo systemctl start docker
  sudo systemctl enable docker

  # Add Jenkins user to the Docker group (if running as Jenkins user)
  sudo usermod -aG docker $(whoami)
  
  echo "Docker installed successfully."
else
  echo "Docker is already installed."
fi

# Variables
DOCKERHUB_USERNAME="foxe03"  # Replace with your Docker Hub username
IMAGE_NAME="$DOCKERHUB_USERNAME/gamelib:latest"

# Login to Docker Hub using Jenkins-stored PAT
echo "Logging into Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Build Docker Image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$IMAGE_NAME"
