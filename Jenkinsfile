pipeline {
    agent any

    environment {
        PROJECT_ID = 'personal-409116'
        REGION = 'us-central1'
        DOCKER_IMAGE = "${REGION}-docker.pkg.dev/${PROJECT_ID}/wordle/wordle:latest"
        PATH = "/usr/local/bin:${env.PATH}"
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

        stage('Initialize Terraform') {
            steps {
                sh '''
                    terraform init
                '''
            }
        }

        stage('Apply Terraform') {
            steps {
                sh '''
                    terraform apply -auto-approve \
                        -var="project_id=${PROJECT_ID}" \
                        -var="region=${REGION}"
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    # Wait for Cloud Run service to be ready
                    gcloud run services describe wordle \
                        --region ${REGION} \
                        --format="get(status.url)"
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