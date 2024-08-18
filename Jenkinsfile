pipeline {
    agent any

    environment {
        DOCKERHUB_CREDS = credentials('docker-hub-creds')
        PATH = "/usr/local/bin:$PATH" // Ensure Docker, Terraform, and kubectl are in the PATH
    }

    stages {
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
                script {
                    // Ensure Terraform is installed and available
                    sh 'terraform --version'
                    dir('terraform') {
                        sh '''
                        terraform init
                        terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        sh '''
                        export KUBECONFIG=$KUBECONFIG
                        kubectl apply -f deployment.yaml
                        '''
                    }
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
