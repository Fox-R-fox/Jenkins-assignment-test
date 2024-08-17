pipeline {
    agent any

    environment {
        GITHUB_PAT = credentials('github-pat')  // Reference to your stored GitHub token
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Use the GitHub PAT in the repository URL
                git url: "https://$GITHUB_PAT@github.com/Fox-R-fox/Jenkins-assignment-test.git", branch: 'master'
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
