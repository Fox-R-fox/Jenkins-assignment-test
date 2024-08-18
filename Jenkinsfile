pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws'
        EKS_CLUSTER_NAME = 'game-library-cluster'
    }

    stages {
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                script {
                    // Install AWS CLI if missing
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

                    // Install AWS IAM Authenticator if missing
                    def checkAWSIAMAuthenticator = sh(script: "which aws-iam-authenticator || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSIAMAuthenticator == 'Not installed') {
                        echo 'Installing AWS IAM Authenticator...'
                        sh '''
                            curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator
                            chmod +x ./aws-iam-authenticator
                            sudo mv aws-iam-authenticator /usr/local/bin
                        '''
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
                        sh "aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_DEFAULT_REGION}"
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
                        - rolearn: arn:aws:iam::339712721384:role/eksssttooooo
                          username: system:node:{{EC2PrivateDNSName}}
                          groups:
                            - system:bootstrappers
                            - system:nodes
                    EOF
                    """
                }
            }
        }

        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        sh 'kubectl apply -f aws-auth.yaml'
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
