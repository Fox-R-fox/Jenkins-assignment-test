pipeline {
    agent any
    environment {
        AWS_CREDENTIALS_ID = 'aws'
        GITHUB_CREDENTIALS_ID = '670be704-04a6-4619-b231-fa7c149d2320'
        DOCKER_CREDENTIALS_ID = 'docker-hub-creds'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: "${GITHUB_CREDENTIALS_ID}", url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }
        stage('Install Docker and Kubernetes') {
            steps {
                sh '''
                # Install Docker
                sudo apt-get update
                sudo apt-get install -y docker.io
                sudo systemctl start docker
                sudo systemctl enable docker

                # Install kubectl
                sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

                # Verify installations
                docker --version
                kubectl version --client
                '''
            }
        }
        stage('Authenticate with Kubernetes') {
            environment {
                AWS_ACCESS_KEY_ID = credentials("${AWS_CREDENTIALS_ID}")
                AWS_SECRET_ACCESS_KEY = credentials("${AWS_CREDENTIALS_ID}")
            }
            steps {
                sh '''
                aws eks update-kubeconfig --name game-library-cluster --region us-east-1
                kubectl get nodes
                '''
            }
        }
        stage('Apply aws-auth ConfigMap') {
            steps {
                sh '''
                cat <<EOF | kubectl apply -f -
                apiVersion: v1
                kind: ConfigMap
                metadata:
                  name: aws-auth
                  namespace: kube-system
                data:
                  mapRoles: |
                    - rolearn: arn:aws:iam::339712721384:role/YOUR_WORKER_NODE_ROLE
                      username: system:node:{{EC2PrivateDNSName}}
                      groups:
                        - system:bootstrappers
                        - system:nodes
                EOF
                '''
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDENTIALS_ID}") {
                        def image = docker.build('stewiedocker46/game-library')
                        image.push('latest')
                    }
                }
            }
        }
        stage('Deploy Docker Image to Kubernetes') {
            steps {
                sh '''
                kubectl apply -f k8s/deployment.yaml
                kubectl apply -f k8s/service.yaml
                '''
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
