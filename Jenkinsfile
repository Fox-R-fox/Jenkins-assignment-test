pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-creds')
    }
    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Verify Docker and Kubernetes Installation') {
            steps {
                sh '''
                docker --version || echo "Docker is not installed."
                kubectl version --client || echo "kubectl is not installed."
                '''
            }
        }
        stage('Authenticate with Kubernetes') {
            steps {
                withAWS(credentials: 'aws', region: 'us-east-1') {
                    sh '''
                    aws sts get-caller-identity
                    aws eks update-kubeconfig --name game-library-cluster --region us-east-1
                    kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster
                    '''
                }
            }
        }
        stage('Apply aws-auth ConfigMap') {
            steps {
                dir('terraform') {
                    sh 'kubectl apply -f aws-auth.yaml'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build('your-docker-image')
                }
            }
        }
        stage('Deploy Docker Image to Kubernetes') {
            steps {
                sh 'kubectl apply -f deployment.yaml'
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
