pipeline {
    agent any
    environment {
        AWS_CREDENTIALS_ID = 'aws'
        GIT_CREDENTIALS_ID = '670be704-04a6-4619-b231-fa7c149d2320'
        DOCKER_HUB_CREDENTIALS_ID = 'docker-hub-creds'
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
                if ! command -v aws &> /dev/null
                then
                    echo "Installing AWS CLI..."
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip awscliv2.zip
                    sudo ./aws/install
                fi

                if ! command -v aws-iam-authenticator &> /dev/null
                then
                    echo "Installing AWS IAM Authenticator..."
                    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator
                    chmod +x ./aws-iam-authenticator
                    sudo mv aws-iam-authenticator /usr/local/bin/
                fi

                echo "AWS CLI and IAM Authenticator are installed"
                '''
            }
        }
        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    script {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    script {
                        sh '''
                        aws sts get-caller-identity
                        aws eks update-kubeconfig --name game-library-cluster --region us-east-1
                        kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster
                        '''
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS_ID}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh '''
                    docker build -t ${DOCKER_USERNAME}/your-image:latest .
                    echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                    docker push ${DOCKER_USERNAME}/your-image:latest
                    '''
                }
            }
        }
        stage('Deploy Docker Image to Kubernetes') {
            steps {
                script {
                    sh 'kubectl apply -f kubernetes/deployment.yaml'
                    sh 'kubectl apply -f kubernetes/service.yaml'
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
