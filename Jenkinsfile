pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials') // Your DockerHub credentials ID
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
                    withEnv(["DOCKERHUB_PASSWORD=${DOCKERHUB_CREDENTIALS_PSW}"]) {
                        sh './scripts/build_push.sh'
                    }
                }
            }
        }
    }
}
