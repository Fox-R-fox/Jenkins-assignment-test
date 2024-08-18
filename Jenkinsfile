pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('docker-hub-creds')
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                    # Install Terraform
                    if ! [ -x "$(command -v terraform)" ]; then
                      echo "Installing Terraform..."
                      curl -LO "https://releases.hashicorp.com/terraform/1.3.1/terraform_1.3.1_linux_amd64.zip"
                      unzip terraform_1.3.1_linux_amd64.zip
                      mv terraform /usr/local/bin/
                    fi

                    # Install kubectl
                    if ! [ -x "$(command -v kubectl)" ]; then
                      echo "Installing kubectl..."
                      curl -LO "https://dl.k8s.io/release/v1.26.3/bin/linux/amd64/kubectl"
                      chmod +x ./kubectl
                      mv ./kubectl /usr/local/bin/kubectl
                    fi
                    '''
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git url: "https://github.com/Fox-R-fox/Jenkins-assignment-test.git", branch: 'master'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    sh '''
                    chmod +x build_push.sh
                    ./build_push.sh $DOCKERHUB_CREDS_USR $DOCKERHUB_CREDS_PSW
                    '''
                }
            }
        }

        stage('Provision Infrastructure with Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init && terraform apply -auto-approve'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                dir('kubernetes') {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo 'Pipeline succeeded.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
