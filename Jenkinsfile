pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git', credentialsId: '670be704-04a6-4619-b231-fa7c149d2320'
            }
        }

        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                sh '''
                if ! which aws > /dev/null; then
                    echo "AWS CLI is not installed"
                    exit 1
                else
                    echo "AWS CLI is installed"
                fi

                if ! which aws-iam-authenticator > /dev/null; then
                    echo "AWS IAM Authenticator is not installed"
                    exit 1
                else
                    echo "AWS IAM Authenticator is installed"
                fi
                '''
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws']]) {
                    sh '''
                    aws sts get-caller-identity
                    aws eks update-kubeconfig --name game-library-cluster
                    kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster
                    '''
                }
            }
        }

        stage('Terraform Init & Apply') {
            dir('terraform') {
                steps {
                    script {
                        // Initialize Terraform
                        sh 'terraform init'

                        // Import existing IAM roles if they exist
                        sh '''
                        set +e
                        aws iam get-role --role-name eks-cluster-role
                        if [ $? -eq 0 ]; then
                            terraform import aws_iam_role.eks_cluster_role eks-cluster-role || true
                        fi

                        aws iam get-role --role-name eks-worker-role
                        if [ $? -eq 0 ]; then
                            terraform import aws_iam_role.eks_worker_role eks-worker-role || true
                        fi
                        set -e
                        '''

                        // Apply the Terraform plan
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image here
                    echo 'Building Docker image...'
                    // Add your Docker build commands
                }
            }
        }

        stage('Deploy Docker Image to Kubernetes') {
            steps {
                script {
                    // Deploy Docker image to Kubernetes
                    echo 'Deploying Docker image to Kubernetes...'
                    // Add your Kubernetes deployment commands
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    // Code to create the aws-auth ConfigMap
                    echo 'Creating aws-auth ConfigMap...'
                    // Add your kubectl or AWS CLI commands
                }
            }
        }

        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            steps {
                script {
                    // Apply the aws-auth ConfigMap
                    echo 'Applying aws-auth ConfigMap to EKS Cluster...'
                    // Add your kubectl apply commands
                }
            }
        }

        stage('Check Worker Node Status') {
            steps {
                script {
                    // Check worker node status
                    echo 'Checking Worker Node Status...'
                    // Add your kubectl get nodes commands
                }
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
