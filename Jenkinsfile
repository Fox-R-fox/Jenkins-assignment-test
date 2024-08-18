pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1' // Change this to your region
        AWS_CREDENTIALS_ID = 'aws'       // This is the ID of your AWS credentials in Jenkins
    }

    stages {
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                script {
                    // Check if AWS CLI is already installed
                    def checkAWSCLI = sh(script: "which aws || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSCLI == 'Not installed') {
                        echo 'Installing AWS CLI...'
                        sh '''
                            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                            unzip awscliv2.zip
                            ./aws/install
                        '''
                    } else {
                        echo "AWS CLI is already installed"
                    }

                    // Check if AWS IAM Authenticator is installed
                    def checkAWSIAMAuthenticator = sh(script: "which aws-iam-authenticator || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSIAMAuthenticator == 'Not installed') {
                        echo 'Installing AWS IAM Authenticator...'
                        sh '''
                            curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator
                            chmod +x ./aws-iam-authenticator
                            mv aws-iam-authenticator ${WORKSPACE}/aws-iam-authenticator
                        '''
                        env.PATH = "${env.WORKSPACE}:${env.PATH}" // Add the directory to the PATH
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
                        sh 'aws eks update-kubeconfig --name game-library-cluster'
                    }
                }
            }
        }

        // Other stages...
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
