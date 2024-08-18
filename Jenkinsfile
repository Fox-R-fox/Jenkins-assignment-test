pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        AWS_CREDENTIALS_ID = 'aws'
        EKS_WORKER_ROLE_ARN = 'arn:aws:iam::339712721384:role/eksssttooooo'
    }

    stages {
        stage('Install AWS CLI') {
            steps {
                script {
                    def checkAWSCLI = sh(script: "which aws || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSCLI == 'Not installed') {
                        echo 'Installing AWS CLI...'
                        sh '''
                            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                            unzip awscliv2.zip
                            sudo ./aws/install
                        '''
                    } else {
                        echo "AWS CLI is already installed"
                    }
                }
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        // Authenticate with the EKS cluster
                        sh "aws eks update-kubeconfig --name <cluster-name> --region ${env.AWS_DEFAULT_REGION}"
                    }
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    sh """
                    cat <<EOF > aws-auth.yaml
                    apiVersion: v1
                    kind: ConfigMap
                    metadata:
                      name: aws-auth
                      namespace: kube-system
                    data:
                      mapRoles: |
                        - rolearn: ${env.EKS_WORKER_ROLE_ARN}
                          username: system:node:{{EC2PrivateDNSName}}
                          groups:
                            - system:bootstrappers
                            - system:nodes
                    EOF
                    """
                    echo "aws-auth.yaml file created"
                }
            }
        }

        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        sh 'kubectl apply -f aws-auth.yaml'
                        echo "aws-auth ConfigMap applied to EKS Cluster"
                    }
                }
            }
        }

        stage('Check Worker Node Status') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        sh 'kubectl get nodes'
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
