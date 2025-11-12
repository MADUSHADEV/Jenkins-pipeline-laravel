def sendDiscordNotification(String buildStatus, String colorCode, String title, Map details = [:]) {
    withCredentials([string(credentialsId: 'discord-webhook-url', variable: 'WEBHOOK_URL')]) {
        def fields = []

        // Add build information
        fields.add([
            name: '📦 Build',
            value: "${currentBuild.fullDisplayName}",
            inline: true
        ])

        fields.add([
            name: '🌿 Branch/Tag',
            value: "${env.BRANCH_NAME ?: env.TAG_NAME ?: 'N/A'}",
            inline: true
        ])

        fields.add([
            name: '⏱️ Duration',
            value: "${currentBuild.durationString.replace(' and counting', '')}",
            inline: true
        ])

        // Add stage information if failed
        if (buildStatus == 'FAILURE' && env.STAGE_NAME) {
            fields.add([
                name: '❌ Failed Stage',
                value: "${env.STAGE_NAME}",
                inline: false
            ])
        }

        // Add custom details passed to the function
        details.each { key, value ->
            fields.add([
                name: key,
                value: value,
                inline: false
            ])
        }

        // Add error details if available
        if (buildStatus == 'FAILURE' && currentBuild.rawBuild.getLog(10)) {
            def logLines = currentBuild.rawBuild.getLog(10).join('\n')
            def truncatedLog = logLines.length() > 1000 ? logLines.substring(0, 1000) + '...' : logLines
            fields.add([
                name: '📋 Error Log (Last 10 lines)',
                value: "```${truncatedLog}```",
                inline: false
            ])
        }

        // Add links
        fields.add([
            name: '🔗 Links',
            value: "[Build Console](${env.BUILD_URL}console) | [Changes](${env.BUILD_URL}changes)",
            inline: false
        ])

        def payload = """
        {
          "embeds": [{
            "title": "${title}",
            "url": "${env.BUILD_URL}",
            "color": "${colorCode}",
            "fields": ${groovy.json.JsonOutput.toJson(fields)},
            "footer": {
              "text": "Jenkins CI/CD Pipeline"
            },
            "timestamp": "${new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))}"
          }]
        }
        """

        sh """
            curl -X POST -H 'Content-Type: application/json' \
            -d '${payload.replaceAll("'", "'\\''")}' \
            \${WEBHOOK_URL}
        """
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
        STAGING_URL = 'http://staging.testproject.pipeworker.me/'
        PRODUCTION_URL = 'http://production.testproject.pipeworker.me/'
        // Define the path on the Jenkins controller/agent VM where your Ansible project lives
        ANSIBLE_PROJECT_PATH = '/ansible-files/ansible-projects/laravel-test-project'
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
                echo 'Deploying to Staging...'

                sh "cp -R ${env.ANSIBLE_PROJECT_PATH}/. ."

                // Use the Jenkins credential for the vault password
                withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')]) {
                    sh """
                        echo \$VAULT_PASS > .vault_pass.txt
                        ansible-playbook -i inventory.ini deploy.yml --limit staging --vault-password-file .vault_pass.txt
                        rm .vault_pass.txt
                    """
                }
            }
        }

        stage('Deploy to Production') {
            when {
                tag 'v*.*.*'
            }
            steps {
                input 'Deploy to Production?'
                echo 'Deploying to Production...'

                sh "cp -R ${env.ANSIBLE_PROJECT_PATH}/* ."

                withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')]) {
                    sh """
                        echo \$VAULT_PASS > .vault_pass.txt
                        ansible-playbook -i inventory.ini deploy.yml --limit production --vault-password-file .vault_pass.txt
                        rm .vault_pass.txt
                    """
                }
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
                def message = '✅ Build completed successfully'
                if (env.BRANCH_NAME == env.MAIN_BRANCH_NAME) {
                    message += ' and deployed to staging'
                } else if (env.TAG_NAME) {
                    message += ' and deployed to production'
                }

                sendDiscordNotification(
                    'SUCCESS',
                    '3066993',
                    '✅ Build Successful',
                    [
                        '📝 Status': message
                    ]
                )
            }
        }
        failure {
            script {
                sendDiscordNotification(
                    'FAILURE',
                    '15158332',
                    '❌ Build Failed',
                    [
                        '⚠️ Action Required': 'Please check the build logs and fix the issues'
                    ]
                )
            }
        }
    }
}
