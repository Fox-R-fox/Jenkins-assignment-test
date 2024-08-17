pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'  // Set your AWS region
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Clone the repository
                git url: 'https://github.com/your/repository.git', branch: 'main'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                // Run the shell script to build and push Docker image
                script {
                    sh 'chmod +x scripts/build_push.sh'
                    sh './scripts/build_push.sh'
                }
            }
        }
    }
}
