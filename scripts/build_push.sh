#!/bin/bash

# Retrieve Docker Hub credentials from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-east-1:339712721384:secret:docker-us-JYDQoe --query SecretString --output text)
DOCKERHUB_USERNAME=$(echo $SECRET_JSON | jq -r '.dockerhub_username')
DOCKERHUB_PASSWORD=$(echo $SECRET_JSON | jq -r '.dockerhub_password')

# Login to Docker Hub
echo "Logging into Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Build Docker Image
echo "Building Docker image..."
docker build -t "$DOCKERHUB_USERNAME/your-app-image:latest" .

# Push Docker Image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push "$DOCKERHUB_USERNAME/your-app-image:latest"
