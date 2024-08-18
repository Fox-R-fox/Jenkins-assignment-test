pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws')
        AWS_SECRET_ACCESS_KEY = credentials('aws')
    }
    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: '670be704-04a6-4619-b231-fa7c149d2320', url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                sh 'which aws || echo "AWS CLI is already installed"'
                sh 'which aws-iam-authenticator || echo "AWS IAM Authenticator is already installed"'
            }
        }
        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([aws(credentialsId: 'aws', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh 'aws sts get-caller-identity'
                        sh 'aws eks update-kubeconfig --name game-library-cluster'
                        sh 'kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster'
                    }
                }
            }
        }
        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    script {
                        // Import existing IAM roles to prevent EntityAlreadyExists error
                        sh '''
                        role_exists=$(aws iam get-role --role-name eks-cluster-role 2>/dev/null || echo "false")
                        if [ "$role_exists" != "false" ]; then
                            terraform import aws_iam_role.eks_cluster_role eks-cluster-role
                        fi

                        role_exists=$(aws iam get-role --role-name eks-worker-role 2>/dev/null || echo "false")
                        if [ "$role_exists" != "false" ]; then
                            terraform import aws_iam_role.eks_worker_role eks-worker-role
                        fi
                        '''
                        // Initialize Terraform
                        sh 'terraform init'
                        // Apply Terraform configuration
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
        stage('Build Docker Image') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh 'docker build -t game-library-app .'
            }
        }
        stage('Deploy Docker Image to Kubernetes') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh 'kubectl apply -f kubernetes/deployment.yaml'
                sh 'kubectl apply -f kubernetes/service.yaml'
            }
        }
        stage('Create aws-auth ConfigMap') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                script {
                    sh '''
                    cat <<EOF > aws-auth.yaml
                    # Add the content of your aws-auth.yaml here
                    EOF
                    echo "aws-auth.yaml file created"
                    '''
                }
            }
        }
        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                withCredentials([aws(credentialsId: 'aws', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh 'kubectl apply -f aws-auth.yaml'
                }
            }
        }
        stage('Check Worker Node Status') {
            when {
                expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            }
            steps {
                sh 'kubectl get nodes'
            }
        }
    }
    post {
        always {
            cleanWs()
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}
