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
                      sudo yum install -y yum-utils
                      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
                      sudo yum -y install terraform
                    fi

                    # Install kubectl
                    if ! [ -x "$(command -v kubectl)" ]; then
                      echo "Installing kubectl..."
                      curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
                      chmod +x ./kubectl
                      sudo mv ./kubectl /usr/local/bin/kubectl
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
