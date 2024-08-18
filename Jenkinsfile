pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: '670be704-04a6-4619-b231-fa7c149d2320', url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }

        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                sh '''
                if ! command -v aws &> /dev/null; then
                    echo "Installing AWS CLI"
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip awscliv2.zip
                    sudo ./aws/install
                fi

                if ! command -v aws-iam-authenticator &> /dev/null; then
                    echo "Installing AWS IAM Authenticator"
                    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.18.9/2021-01-05/bin/linux/amd64/aws-iam-authenticator
                    chmod +x ./aws-iam-authenticator
                    sudo mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
                fi

                echo "AWS CLI and IAM Authenticator installed"
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    script {
                        // Initialize Terraform
                        sh 'terraform init'

                        // Import existing IAM roles if they exist
                        sh '''
                        set +e
                        aws iam get-role --role-name eks-cluster-role && terraform import aws_iam_role.eks_cluster_role eks-cluster-role
                        aws iam get-role --role-name eks-worker-role && terraform import aws_iam_role.eks_worker_role eks-worker-role
                        set -e
                        '''

                        // Apply Terraform configuration
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws']]) {
                    script {
                        // Authenticate and configure Kubernetes
                        sh '''
                        aws sts get-caller-identity
                        aws eks update-kubeconfig --name game-library-cluster
                        kubectl config use-context arn:aws:eks:${AWS_REGION}:339712721384:cluster/game-library-cluster
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Add your Docker build steps here
                echo 'Building Docker Image...'
            }
        }

        stage('Deploy Docker Image to Kubernetes') {
            steps {
                // Add your Kubernetes deployment steps here
                echo 'Deploying Docker Image to Kubernetes...'
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                // Add your aws-auth ConfigMap creation steps here
                echo 'Creating aws-auth ConfigMap...'
            }
        }

        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            steps {
                // Apply the aws-auth ConfigMap to allow worker nodes to join the cluster
                echo 'Applying aws-auth ConfigMap to EKS Cluster...'
            }
        }

        stage('Check Worker Node Status') {
            steps {
                // Check the status of the worker nodes in the cluster
                echo 'Checking Worker Node Status...'
            }
        }
    }

    post {
        always {
            cleanWs()
            echo 'Pipeline finished.'
        }

        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}
