#!/bin/bash

# Docker Hub credentials passed as positional parameters
DOCKERHUB_USERNAME=$1
DOCKERHUB_PASSWORD=$2

# Check if Docker is installed, if not, install it
if ! [ -x "$(command -v docker)" ]; then
  echo "Docker is not installed. Installing Docker..."
  sudo yum update -y
  sudo yum install docker -y
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $(whoami)
  echo "Docker installed successfully."
else
  echo "Docker is already installed."
fi

# Check if Terraform is installed, if not, install it
if ! [ -x "$(command -v terraform)" ]; then
  echo "Terraform is not installed. Installing Terraform..."
  sudo yum install -y yum-utils
  sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
  sudo yum -y install terraform
  echo "Terraform installed successfully."
else
  echo "Terraform is already installed."
fi

# Check if Kubernetes CLI (kubectl) is installed, if not, install it
if ! [ -x "$(command -v kubectl)" ]; then
  echo "Kubectl is not installed. Installing kubectl..."
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
  echo "Kubectl installed successfully."
else
  echo "Kubectl is already installed."
fi

# Docker logic for building and pushing images
IMAGE_NAME="$DOCKERHUB_USERNAME/gamelib:latest"
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .
echo "Pushing Docker image to Docker Hub..."
echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
docker push "$IMAGE_NAME"

# Terraform logic for provisioning infrastructure
echo "Running Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

# Kubernetes logic for deploying to the cluster
echo "Deploying to Kubernetes..."
cd ../kubernetes
kubectl apply -f deployment.yaml
