pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-creds')
        AWS_CREDENTIALS = credentials('aws')
    }
    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Install Docker and Kubernetes') {
            steps {
                sh '''
                echo YOUR_PASSWORD | sudo -S apt-get update
                echo YOUR_PASSWORD | sudo -S apt-get install -y docker.io
                sudo systemctl start docker
                sudo systemctl enable docker

                # Install kubectl
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

                docker --version
                kubectl version --client
                '''
            }
        }
        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
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
                withCredentials([usernamePassword(credentialsId: 'aws', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraform') {
                        sh '''
                        kubectl apply -f aws-auth.yaml
                        '''
                    }
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
                script {
                    sh 'kubectl apply -f deployment.yaml'
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
