pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws'
        PATH = "${WORKSPACE}/bin:${env.PATH}"  // Add a custom bin directory to PATH
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
                            sudo ./aws/install
                        '''
                    } else {
                        echo "AWS CLI is already installed"
                    }

                    // Install AWS IAM Authenticator in Jenkins workspace
                    def checkIAMAuthenticator = sh(script: "which aws-iam-authenticator || echo 'Not installed'", returnStdout: true).trim()
                    if (checkIAMAuthenticator == 'Not installed') {
                        echo 'Installing AWS IAM Authenticator...'
                        sh '''
                            mkdir -p ${WORKSPACE}/bin
                            curl -o ${WORKSPACE}/bin/aws-iam-authenticator https://amazon-eks.s3.us-east-1.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator
                            chmod +x ${WORKSPACE}/bin/aws-iam-authenticator
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
                        sh 'aws eks update-kubeconfig --name game-library-cluster'
                    }
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    sh '''
                    cat <<EOF > aws-auth.yaml
                    apiVersion: v1
                    kind: ConfigMap
                    metadata:
                      name: aws-auth
                      namespace: kube-system
                    data:
                      mapRoles: |
                        - rolearn: arn:aws:iam::<YOUR-AWS-ACCOUNT-ID>:role/<YOUR-WORKER-ROLE-NAME>
                          username: system:node:{{EC2PrivateDNSName}}
                          groups:
                            - system:bootstrappers
                            - system:nodes
                    EOF
                    '''
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
