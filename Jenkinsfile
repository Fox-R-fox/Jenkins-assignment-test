pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_CREDENTIALS_ID = 'aws'
        DOCKER_CREDENTIALS_ID = 'docker-hub-creds'
        GITHUB_CREDENTIALS_ID = '670be704-04a6-4619-b231-fa7c149d2320'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: "${GITHUB_CREDENTIALS_ID}", url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }

        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                script {
                    def awsInstalled = sh(script: "which aws", returnStatus: true) == 0
                    def iamAuthInstalled = sh(script: "which aws-iam-authenticator", returnStatus: true) == 0
                    if (!awsInstalled) {
                        error('AWS CLI is not installed.')
                    }
                    if (!iamAuthInstalled) {
                        echo 'Installing AWS IAM Authenticator...'
                        sh '''
                            mkdir -p /var/lib/jenkins/workspace/admin/bin
                            curl -o /var/lib/jenkins/workspace/admin/bin/aws-iam-authenticator https://amazon-eks.s3.us-east-1.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator
                            chmod +x /var/lib/jenkins/workspace/admin/bin/aws-iam-authenticator
                        '''
                    } else {
                        echo "AWS IAM Authenticator is already installed"
                    }
                }
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
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
                dir('terraform') {  // Ensure the directory containing your Terraform files
                    script {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        sh '''
                            docker build -t $DOCKER_USER/game-library:latest .
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push $DOCKER_USER/game-library:latest
                        '''
                    }
                }
            }
        }

        stage('Deploy Docker Image to Kubernetes') {
            steps {
                dir('kubernetes') {  // Ensure the directory containing your Kubernetes yaml files
                    script {
                        sh 'kubectl apply -f deployment.yaml'
                        sh 'kubectl apply -f service.yaml'
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
                }
            }
        }

        stage('Apply aws-auth ConfigMap to EKS Cluster') {
            steps {
                script {
                    sh 'kubectl apply -f aws-auth.yaml'
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
