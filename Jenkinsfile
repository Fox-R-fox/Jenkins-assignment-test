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
                    def checkAWSCLI = sh(script: "which aws || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSCLI == 'Not installed') {
                        error "AWS CLI not installed."
                    } else {
                        echo "AWS CLI is already installed"
                    }

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
                        // Ensure AWS credentials are available
                        sh 'aws sts get-caller-identity'

                        // Update kubeconfig for the cluster
                        sh 'aws eks update-kubeconfig --name game-library-cluster'

                        // Switch context and verify auth
                        sh 'kubectl config use-context arn:aws:eks:us-east-1:339712721384:cluster/game-library-cluster'
                        sh 'kubectl get nodes' // Try fetching nodes again
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
                        - rolearn: arn:aws:iam::339712721384:role/eks-worker-role
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
                        // Re-authenticate with EKS after kubeconfig update
                        sh 'kubectl config view'
                        sh 'kubectl apply -f aws-auth.yaml'
                    }
                }
            }
        }

        stage('Check Worker Node Status') {
            steps {
                script {
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
