provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "eks_cluster_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_worker_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role-${random_id.random.hex}"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_policy.json
  tags = {
    Name = "eks-cluster-role"
  }
}

resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role-${random_id.random.hex}"
  assume_role_policy = data.aws_iam_policy_document.eks_worker_policy.json
  tags = {
    Name = "eks-worker-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_security_group" "eks_worker_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "eks-worker-sg"
  }
}

resource "aws_eks_cluster" "game_library_cluster" {
  name = "game-library-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    security_group_ids = [aws_security_group.eks_worker_sg.id]
    subnet_ids = aws_subnet.public_subnets[*].id
  }
}

resource "aws_eks_node_group" "game_library_nodes" {
  cluster_name = aws_eks_cluster.game_library_cluster.name
  node_role_arn = aws_iam_role.eks_worker_role.arn
  subnet_ids = aws_subnet.private_subnets[*].id
  scaling_config {
    desired_size = 2
    max_size = 3
    min_size = 1
  }
}

data "aws_availability_zones" "available" {}

output "eks_cluster_name" {
  value = aws_eks_cluster.game_library_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.game_library_cluster.endpoint
}

output "eks_cluster_security_group" {
  value = aws_security_group.eks_worker_sg.id
}
