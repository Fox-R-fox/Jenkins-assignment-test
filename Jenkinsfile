pipeline {
    agent any

    environment {
        AWS_CREDENTIALS_ID = 'aws' // Replace with your Jenkins AWS credentials ID
        GIT_CREDENTIALS_ID = '670be704-04a6-4619-b231-fa7c149d2320' // Replace with your Jenkins Git credentials ID
        DOCKER_CREDENTIALS_ID = 'docker-hub-creds' // Replace with your Jenkins Docker credentials ID
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: "${GIT_CREDENTIALS_ID}", url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }

        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                sh '''
                which aws || (curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install)
                which aws-iam-authenticator || curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator && chmod +x ./aws-iam-authenticator && sudo mv ./aws-iam-authenticator /usr/local/bin/
                echo "AWS CLI and IAM Authenticator are installed"
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh '''
                    aws sts get-caller-identity
                    aws eks update-kubeconfig --name game-library-cluster --region us-east-1
                    kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster
                    '''
                }
            }
        }

        stage('Apply RBAC Config') {
            steps {
                sh 'kubectl apply -f cluster-role.yaml'
                sh 'kubectl apply -f cluster-role-binding.yaml'
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh '''
                    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                    docker build -t stewiedocker46/game-library:latest .
                    docker push stewiedocker46/game-library:latest
                    '''
                }
            }
        }

        stage('Deploy Docker Image to Kubernetes') {
            steps {
                sh 'kubectl apply -f deployment.yaml'
                sh 'kubectl apply -f service.yaml'
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
