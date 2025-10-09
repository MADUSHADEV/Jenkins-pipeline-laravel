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

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/MADUSHADEV/Jenkins-pipeline-laravel.git'
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
            }
        }
        stage('Build frontend') {
            steps {
                echo 'Installing Node.js dependencies and building frontend...'
                sh 'npm install'

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
    }
    post {
        always {
            echo 'Build completed. Archiving reports...'
            archiveArtifacts artifacts: 'test-results.xml', allowEmptyArchive: true

            junit 'test-results.xml'
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
