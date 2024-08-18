#!/bin/bash

# Docker Hub credentials passed as positional parameters
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

  # Add the user to the Docker group (this is specific to the user running the script)
  sudo usermod -aG docker $(whoami)
  
  echo "Docker installed successfully."
else
  echo "Docker is already installed."
fi

# Check if the repository exists in Docker Hub
REPO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://hub.docker.com/v2/repositories/$DOCKERHUB_USERNAME/gamelib/)

if [ "$REPO_RESPONSE" -ne 200 ]; then
    echo "Repository does not exist. Creating repository in Docker Hub..."

    # Create the repository using Docker Hub API with the passed credentials
    REPO_CREATE_RESPONSE=$(curl -X POST https://hub.docker.com/v2/repositories/ \
    -u "$DOCKERHUB_USERNAME:$DOCKERHUB_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "gamelib", "is_private": false}')

    echo "Repository creation request sent. Response: $REPO_CREATE_RESPONSE"
else
    echo "Repository already exists."
fi

# Login to Docker Hub using the passed credentials
echo "Logging into Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin

# Build Docker Image with a valid tag
IMAGE_NAME="$DOCKERHUB_USERNAME/gamelib:latest"
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$IMAGE_NAME"
