pipeline {
    agent any

    environment {
        // Referencing the credentials in Jenkins
        DOCKERHUB_CREDS = credentials('docker-hub-creds')
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Checkout code from GitHub
                git url: "https://github.com/Fox-R-fox/Jenkins-assignment-test.git", branch: 'master'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Run the shell script to build and push Docker image
                    sh '''
                    chmod +x build_push.sh
                    ./build_push.sh $DOCKERHUB_CREDS_USR $DOCKERHUB_CREDS_PSW
                    '''
                }
            }
        }

        stage('Provision Infrastructure with Terraform') {
            steps {
                dir('terraform') {
                    // Initialize and apply Terraform configuration
                    sh '''
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                dir('kubernetes') {
                    // Apply Kubernetes configurations
                    sh 'kubectl apply -f deployment.yaml'
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
