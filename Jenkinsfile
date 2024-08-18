pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws'
        PATH = "${env.WORKSPACE}/bin:${env.PATH}"
    }

    stages {
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                script {
                    // Ensure AWS CLI is installed
                    def checkAWSCLI = sh(script: "which aws || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSCLI == 'Not installed') {
                        error "AWS CLI not installed. Please install it."
                    } else {
                        echo "AWS CLI is already installed"
                    }

                    // Ensure aws-iam-authenticator is installed
                    def checkIAMAuth = sh(script: "which aws-iam-authenticator || echo 'Not installed'", returnStdout: true).trim()
                    if (checkIAMAuth == 'Not installed') {
                        echo "Installing AWS IAM Authenticator..."
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
                        // Update kubeconfig for the cluster
                        sh 'aws eks update-kubeconfig --name game-library-cluster'
                        // Debug step: Check Kubernetes context and nodes
                        sh 'kubectl config view'
                        sh 'kubectl get nodes'
                    }
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    // Generate aws-auth.yaml
                    sh '''
                    cat <<EOF > aws-auth.yaml
                    apiVersion: v1
                    kind: ConfigMap
                    metadata:
                      name: aws-auth
                      namespace: kube-system
                    data:
                      mapRoles: |
                        - rolearn: ${EKS_WORKER_ROLE_ARN}
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
                        // Apply the aws-auth.yaml to the cluster
                        sh 'kubectl apply -f aws-auth.yaml'
                    }
                }
            }
        }

        stage('Check Worker Node Status') {
            steps {
                script {
                    // Check if worker nodes are ready
                    sh 'kubectl get nodes'
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
