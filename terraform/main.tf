provider "aws" {
  region = "us-east-1"
}

# Data Source for AWS Availability Zones
data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Subnet
resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "private-subnet"
  }
}

# Security Group for EKS Workers
resource "aws_security_group" "eks_worker_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "eks-worker-sg"
  }
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_policy.json
}

# EKS Worker IAM Role
resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role"
  assume_role_policy = data.aws_iam_policy_document.eks_worker_policy.json
}

# IAM Role Policy Attachments for EKS Cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "game_library_cluster" {
  name     = "game-library-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private_subnets.id]
  }

  tags = {
    Name = "game-library-cluster"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "game_library_nodes" {
  cluster_name    = aws_eks_cluster.game_library_cluster.name
  node_group_name = "game-library-nodes"
  node_role_arn   = aws_iam_role.eks_worker_role.arn
  subnet_ids      = [aws_subnet.private_subnets.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  tags = {
    Name = "game-library-nodes"
  }
}

# Outputs
output "eks_cluster_name" {
  value = aws_eks_cluster.game_library_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.game_library_cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.game_library_cluster.certificate_authority[0].data
}
