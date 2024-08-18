pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1' // Make sure this is your correct region
        AWS_CREDENTIALS_ID = 'aws'       // This should be your AWS credentials ID in Jenkins
        DOCKER_CREDENTIALS_ID = 'jenkins-docker' // Docker credentials ID
    }

    stages {
        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                script {
                    def checkAWSCLI = sh(script: "which aws || echo 'Not installed'", returnStdout: true).trim()
                    if (checkAWSCLI == 'Not installed') {
                        echo 'Installing AWS CLI...'
                        // Commands to install AWS CLI
                    } else {
                        echo "AWS CLI is already installed"
                    }

                    def checkIAMAuth = sh(script: "which aws-iam-authenticator || echo 'Not installed'", returnStdout: true).trim()
                    if (checkIAMAuth == 'Not installed') {
                        echo 'Installing AWS IAM Authenticator...'
                        // Commands to install IAM Authenticator
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

        stage('Terraform Init & Apply') {
            steps {
                script {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        sh 'docker build -t stewiedocker46/game-library-app:latest .'
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        sh 'docker push stewiedocker46/game-library-app:latest'
                    }
                }
            }
        }

        stage('Deploy Docker Image to Kubernetes') {
            steps {
                script {
                    sh '''
                    kubectl create deployment game-library-app --image=stewiedocker46/game-library-app:latest || kubectl set image deployment/game-library-app game-library-app=stewiedocker46/game-library-app:latest
                    kubectl expose deployment game-library-app --type=LoadBalancer --port=80 --target-port=5000 || echo "Service already exposed"
                    '''
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    // Generate aws-auth.yaml file dynamically
                    sh '''
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
                    '''
                    echo "aws-auth.yaml file created"
                }
            }
        }

        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: AWS_CREDENTIALS_ID]]) {
                    script {
                        sh 'kubectl apply -f aws-auth.yaml || echo "Failed to apply ConfigMap"'
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
