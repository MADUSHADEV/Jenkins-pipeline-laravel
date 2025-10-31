def sendDiscordNotification(String buildStatus, String colorCode, String message) {
    withCredentials([string(credentialsId: 'discord-webhook-url', variable: 'WEBHOOK_URL')]) {
        def payload = """
        {
          "embeds": [{
            "title": "Build ${buildStatus}: ${currentBuild.fullDisplayName}",
            "url": "${env.BUILD_URL}",
            "color": "${colorCode}",
            "fields": [
              {
                "name": "Stage Failed",
                "value": "${env.STAGE_NAME}",
                "inline": true
              },
              {
                "name": "Message",
                "value": "${message}",
                "inline": false
              }
            ],
            "footer": {
              "text": "Jenkins Build Notifier"
            }
          }]
        }
        """
        // Use sh to send the notification via curl
        sh "curl -X POST -H 'Content-Type: application/json' -d '${payload}' ${WEBHOOK_URL}"
    }
}

pipeline {
    agent {
        label 'laravel'
    }

    environment {
        DB_CONNECTION = 'sqlite'
        DB_DATABASE = 'database/database.sqlite'
        MAIN_BRANCH_NAME = 'main'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code from branch'
                checkout scm
            }
        }
        stage('Prepare Laravel Environment') {
            steps {
                echo 'Setting up Laravel environment...'
                sh 'composer install --no-interaction --prefer-dist --optimize-autoloader'

                echo 'Generating env file...'
                sh 'cp .env.example .env'

                echo 'Generating application key...'
                sh 'php artisan key:generate'

                echo 'Installing Node.js dependencies and building frontend...'
                sh 'npm install'
            }
        }

        stage('code quality check') {
            steps {
                echo 'Running Laravel Pint...'
                sh './vendor/bin/pint --test'

                echo 'Running ESLint...'
                sh 'npm run lint'
            }
        }

        stage('Build frontend') {
            steps {
                echo 'Building frontend assets...'
                sh 'npm run build'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Preparing database for testing...'
                sh 'touch database/database.sqlite'
                sh 'php artisan migrate --force'

                echo 'Running tests and generating JUnit report...'
                sh 'php artisan test --log-junit test-results.xml'
            }
        }

        stage('Build Docker Image') {
            when {
                branch "${MAIN_BRANCH_NAME}"
            }

            steps {
                script {
                    // Define Docker image name and tag
                    def imageName = 'madushadev/alg-30-buslinker'
                    def imageTag = env.BUILD_NUMBER ?: 'latest'

                    // Full image name with tag
                    def fullImageName = "${imageName}:${imageTag}"

                    // Build the Docker image
                    sh "docker build -t ${fullImageName} ."

                    // Store the full image name in the environment for later stages
                    env.IMAGE_NAME_WITH_TAG = fullImageName
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            when {
                branch "${MAIN_BRANCH_NAME}"
            }

            steps {
                script {
                    echo "Attempting to log in to Docker Hub and push image: ${env.IMAGE_NAME_WITH_TAG}"

                    // Log in to Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                        echo 'Credentials retrieved. Attempting Docker login...'
                        sh "echo ${DOCKERHUB_PASSWORD} | docker login -u ${DOCKERHUB_USERNAME} --password-stdin"
                        echo 'Docker login successful. Attempting Docker push...'

                        // Push the image
                        sh "docker push ${env.IMAGE_NAME_WITH_TAG}"
                        echo "Docker image ${env.IMAGE_NAME_WITH_TAG} pushed to Docker Hub."
                    }
                    echo 'Docker Hub push process finished.'
                }
            }

            post {
                always {
                    // Always logout after push attempt for this stage
                    echo 'Logging out from Docker Hub...'
                    sh 'docker logout'
                }
            }
        }

        stage('Deploy to Development') {
            when {
                branch 'development'
            }
            steps {
                echo 'Deploying to Development Server...'
            // Add your deployment commands here
            }
        }

        stage('Deploy to Staging') {
            when {
                branch "${MAIN_BRANCH_NAME}"
            }
            steps {
                echo "Deploying image ${env.IMAGE_NAME_WITH_TAG} to Staging Server..."

                echo 'Copying Ansible files from VM to workspace...'
                // --- NEW STEP ---
                // Copy Ansible files from the VM's home directory into the current workspace
                sh 'cp /ansible-files/deploy.yml . && cp /ansible-files/inventory.ini .'

                // Add your deployment commands here
                sh "ansible-playbook -i inventory.ini deploy.yml --extra-vars 'image_tag_from_jenkins=${env.IMAGE_NAME_WITH_TAG}'"
            }
        }

        stage('Deploy to Production') {
            when {
                tag 'v*.*.*'
            }
            steps {
                input 'Deploy to Production?'
                echo 'Deploying to the Production server...'
            }
        }
    }
    post {
        always {
            echo 'Build completed. Archiving reports...'
            archiveArtifacts artifacts: 'test-results.xml', allowEmptyArchive: true

            junit 'test-results.xml'

            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            script {
                sendDiscordNotification('SUCCESS', '3066993', 'The build completed successfully.')
            }
        }
        failure {
            script {
                sendDiscordNotification('FAILURE', '15158332', 'The build failed.')
            }
        }
    }
}
