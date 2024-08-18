provider "aws" {
  region = "us-east-1"
}

# VPC definition
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Subnets for the EKS cluster (private)
resource "aws_subnet" "private_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false

  tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/game-library-cluster" = "shared"
    Name = "private-subnet-${count.index}"
  }
}

# Security group for EKS worker nodes
resource "aws_security_group" "eks_worker_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-worker-sg"
  }
}

# Fetch existing IAM roles if they exist
data "aws_iam_role" "existing_cluster_role" {
  role_name = "eks-cluster-role"
}

data "aws_iam_role" "existing_worker_role" {
  role_name = "eks-worker-role"
}

# EKS Cluster IAM Role (Create only if not exists)
resource "aws_iam_role" "eks_cluster_role" {
  count = length(data.aws_iam_role.existing_cluster_role.id) == 0 ? 1 : 0

  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# EKS Worker Node IAM Role (Create only if not exists)
resource "aws_iam_role" "eks_worker_role" {
  count = length(data.aws_iam_role.existing_worker_role.id) == 0 ? 1 : 0

  name = "eks-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy Attachments for EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# IAM Policy Attachments for EKS Worker Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_worker_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_worker_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  role       = aws_iam_role.eks_worker_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster Definition
resource "aws_eks_cluster" "game_library_cluster" {
  name     = "game-library-cluster"
  role_arn = aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids = aws_subnet.private_subnets[*].id
    security_group_ids = [aws_security_group.eks_worker_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}

# EKS Node Group Definition
resource "aws_eks_node_group" "game_library_nodes" {
  cluster_name    = aws_eks_cluster.game_library_cluster.name
  node_group_name = "game-library-nodes"
  node_role_arn   = aws_iam_role.eks_worker_role[0].arn
  subnet_ids      = aws_subnet.private_subnets[*].id

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [
    aws_eks_cluster.game_library_cluster,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly
  ]
}

# Data sources to get AWS availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
