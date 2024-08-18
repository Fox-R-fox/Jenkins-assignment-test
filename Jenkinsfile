pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS = credentials('aws')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/Fox-R-fox/Jenkins-assignment-test.git'
            }
        }

        stage('Install AWS CLI and IAM Authenticator') {
            steps {
                sh '''
                    if ! which aws > /dev/null; then
                        echo "AWS CLI is not installed, installing now..."
                        sudo apt-get update
                        sudo apt-get install -y awscli
                    fi

                    if ! which aws-iam-authenticator > /dev/null; then
                        echo "AWS IAM Authenticator is not installed, installing now..."
                        curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
                        chmod +x ./aws-iam-authenticator
                        sudo mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
                    fi

                    echo "AWS CLI and IAM Authenticator are installed"
                '''
            }
        }

        stage('Authenticate with Kubernetes') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws']]) {
                    sh '''
                        aws sts get-caller-identity
                        aws eks update-kubeconfig --name game-library-cluster --region $AWS_REGION
                        kubectl config use-context arn:aws:eks:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):cluster/game-library-cluster
                    '''
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    script {
                        sh '''
                            terraform init
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-creds') {
                        def app = docker.build("stewiedocker46/my-app:${env.BUILD_ID}")
                        app.push()
                    }
                }
            }
        }

        stage('Deploy Docker Image to Kubernetes') {
            steps {
                script {
                    sh '''
                        kubectl apply -f kubernetes/deployment.yaml
                        kubectl apply -f kubernetes/service.yaml
                    '''
                }
            }
        }

        stage('Create aws-auth ConfigMap') {
            steps {
                script {
                    sh '''
                        kubectl get configmap -n kube-system aws-auth -o yaml > aws-auth.yaml || echo 'aws-auth ConfigMap does not exist, creating...'
                        cat <<EOF >> aws-auth.yaml
                        mapRoles: |
                          - rolearn: $(terraform output -raw worker_role_arn)
                            username: system:node:{{EC2PrivateDNSName}}
                            groups:
                              - system:bootstrappers
                              - system:nodes
                        EOF
                        kubectl apply -f aws-auth.yaml
                    '''
                }
            }
        }

        stage('Check Worker Node Status') {
            steps {
                script {
                    sh '''
                        kubectl get nodes
                    '''
                }
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
