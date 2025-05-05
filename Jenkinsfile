pipeline {
    agent any

    environment {
        PROJECT_ID = 'personal-409116'
        REGION = 'us-central1'
        DOCKER_IMAGE = "${REGION}-docker.pkg.dev/${PROJECT_ID}/wordle/wordle:latest"
        PATH = "/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Google Cloud') {
            steps {    
                sh '''
                    gcloud config set project ${PROJECT_ID}
                    gcloud auth configure-docker ${REGION}-docker.pkg.dev
                '''      
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build --platform linux/amd64 -t wordle .
                    docker tag wordle ${DOCKER_IMAGE}
                '''
            }
        }

        stage('Push to Artifact Registry') {
            steps {
                sh "docker push ${DOCKER_IMAGE}"
            }
        }

        stage('Deploy with Ansible') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        # Set the credentials JSON as an environment variable
                        export GOOGLE_APPLICATION_CREDENTIALS_JSON=$(cat ${GOOGLE_APPLICATION_CREDENTIALS})
                        
                        # Install Ansible if not present
                        if ! command -v ansible-playbook &> /dev/null; then
                            pip install ansible
                        fi
                        
                        # Run the Ansible playbook
                        ansible-playbook -i ansible/inventory.ini ansible/deploy.yml
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    # Wait for a few seconds to ensure the application is up
                    sleep 30
                    
                    # Test both web servers
                    for server in $(grep "ansible_host" ansible/inventory.ini | awk "{print \$2}"); do
                        echo "Testing server: $server"
                        curl -I http://$server:8080 || true
                    done
                '''
            }
        }
    }

    post {
        always {
            sh '''
                # Clean up Docker images
                docker rmi wordle ${DOCKER_IMAGE} || true
            '''
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
} 