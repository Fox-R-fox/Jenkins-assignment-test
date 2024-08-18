pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws'
    }

    stages {
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                script {
                    def checkAWSCLI = sh(script: "which aws || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSCLI == 'Not installed') {
                        echo 'Installing AWS CLI...'
                        // Install AWS CLI commands here
                    } else {
                        echo "AWS CLI is already installed"
                    }

                    def checkIAMAuth = sh(script: "which aws-iam-authenticator || echo 'Not installed'", returnStdout: true).trim()
                    if (checkIAMAuth == 'Not installed') {
                        echo 'Installing AWS IAM Authenticator...'
                        // Install IAM Authenticator here
                    } else {
                        echo "AWS IAM Authenticator is already installed"
                    }
                }
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        sh 'aws sts get-caller-identity'
                        sh 'aws eks update-kubeconfig --name game-library-cluster'
                        sh 'kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster'
                    }
                }
            }
        }

        stage('Debug Kubernetes Credentials') {
            steps {
                script {
                    // Print detailed Kubernetes config and credentials
                    sh 'kubectl config view'
                    sh 'kubectl config get-contexts'
                    sh 'kubectl config current-context'
                }
            }
        }

        stage('Apply aws-auth ConfigMap') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        sh 'kubectl apply -f aws-auth.yaml || echo "Failed to apply ConfigMap"'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}
