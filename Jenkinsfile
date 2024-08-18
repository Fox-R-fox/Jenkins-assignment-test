pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('docker-hub-creds')
        PATH = "/usr/local/bin:$PATH" // Ensure Docker and kubectl are in the PATH
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: "https://github.com/Fox-R-fox/Jenkins-assignment-test.git", branch: 'master'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    sh '''
                    # Ensure the script is executable
                    chmod +x build_push.sh
                    
                    # Execute the build and push script with Docker Hub credentials
                    ./build_push.sh $DOCKERHUB_CREDS_USR $DOCKERHUB_CREDS_PSW
                    '''
                }
            }
        }

        stage('Provision Infrastructure with Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                    # Initialize and apply Terraform configurations
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                dir('kubernetes') {
                    sh '''
                    # Apply Kubernetes deployment configurations
                    kubectl apply -f deployment.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo 'Pipeline succeeded.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
