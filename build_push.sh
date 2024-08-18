#!/bin/bash

# Docker Hub credentials passed from Jenkins
DOCKERHUB_USERNAME=$1
DOCKERHUB_PASSWORD=$2

# Check if Docker is installed, if not, install it
if ! [ -x "$(command -v docker)" ]; then
  echo "Docker is not installed. Installing Docker..."
  
  # Install Docker for Amazon Linux 2 (or adjust for your Linux distribution)
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

# Check if the repository exists in Docker Hub
REPO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://hub.docker.com/v2/repositories/$DOCKERHUB_USERNAME/gamelib/)

if [ "$REPO_RESPONSE" -ne 200 ]; then
    echo "Repository does not exist. Creating repository in Docker Hub..."

    # Create the repository using Docker Hub API
    curl -X POST https://hub.docker.com/v2/repositories/ \
    -u "$DOCKERHUB_USERNAME:$DOCKERHUB_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "gamelib", "is_private": false}'

    echo "Repository creation request sent."
else
    echo "Repository already exists."
fi

# Login to Docker Hub using Jenkins-stored credentials non-interactively
echo "Logging into Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin

# Build Docker Image
echo "Building Docker image..."
docker build -t "$DOCKERHUB_USERNAME/gamelib:latest" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$DOCKERHUB_USERNAME/gamelib:latest"
