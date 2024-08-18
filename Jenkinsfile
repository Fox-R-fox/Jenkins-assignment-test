pipeline {
    agent any

    environment {
        DOCKERHUB_PAT = credentials('docker-hub-pat')  // Reference to your stored Docker Hub PAT
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
                // Run the shell script to build and push Docker image
                script {
                    sh 'chmod +x build_push.sh'
                    sh './build_push.sh'
                }
            }
        }
    }
}
