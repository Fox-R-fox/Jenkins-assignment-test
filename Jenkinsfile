pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-west-2' // Change this to your region
        AWS_CREDENTIALS_ID = 'aws'       // This is the ID of your AWS credentials in Jenkins
    }

    stages {
        stage('Install AWS CLI') {
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
                }
            }
        }

        stage('Retrieve IAM Role ARN') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        def roleArn = sh(
                            script: "aws iam get-role --role-name eks-worker-node-role --query 'Role.Arn' --output text",
                            returnStdout: true
                        ).trim()
                        echo "Retrieved IAM Role ARN: ${roleArn}"

                        // Store the ARN for use in later stages
                        env.EKS_WORKER_ROLE_ARN = roleArn
                    }
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    // Generate the aws-auth.yaml file dynamically
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
                        // Apply the aws-auth.yaml file to the cluster
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
                        // Check if worker nodes are ready
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
