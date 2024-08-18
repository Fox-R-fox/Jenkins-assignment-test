pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
    }
    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: '670be704-04a6-4619-b231-fa7c149d2320', url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                sh """
                    which aws || exit 1
                    which aws-iam-authenticator || exit 1
                    echo 'AWS CLI and IAM Authenticator are installed'
                """
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
                script {
                    def clusterName = sh(script: 'terraform output -raw eks_cluster_name', returnStdout: true).trim()
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws']]) {
                        sh """
                        aws sts get-caller-identity
                        aws eks update-kubeconfig --name ${clusterName} --region ${AWS_REGION}
                        kubectl config use-context arn:aws:eks:${AWS_REGION}:339712721384:cluster/${clusterName}
                        """
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                // Add your Docker build steps here
            }
        }
        stage('Deploy Docker Image to Kubernetes') {
            steps {
                // Add your deployment steps here
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
