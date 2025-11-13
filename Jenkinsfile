def sendDiscordNotification(String buildStatus, String colorCode, String title, Map details = [:]) {
    withCredentials([string(credentialsId: 'discord-webhook-url', variable: 'WEBHOOK_URL')]) {
        def fields = []

        // Get commit author information
        def commitAuthor = 'N/A'
        def commitEmail = 'N/A'
        def commitMessage = 'N/A'
        try {
            commitAuthor = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
            commitEmail = sh(script: "git log -1 --pretty=format:'%ae'", returnStdout: true).trim()
            commitMessage = sh(script: "git log -1 --pretty=format:'%s'", returnStdout: true).trim()
        } catch (Exception e) {
            echo "Could not retrieve git information: ${e.message}"
        }

        // Get Jenkins user who triggered the build
        def triggeredBy = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')
        def jenkinsUser = 'Automated'
        if (triggeredBy) {
            jenkinsUser = triggeredBy[0]?.userId ?: 'Automated'
        } else {
            // Check for SCM trigger
            def scmTrigger = currentBuild.getBuildCauses('hudson.triggers.SCMTrigger$SCMTriggerCause')
            if (scmTrigger) {
                jenkinsUser = 'SCM Change'
            }
            // Check for timer trigger
            def timerTrigger = currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause')
            if (timerTrigger) {
                jenkinsUser = 'Scheduled Build'
            }
        }

        // Add user information
        fields.add([
            name: '👤 Commit Author',
            value: "${commitAuthor}",
            inline: true
        ])

        fields.add([
            name: '🔧 Triggered By',
            value: "${jenkinsUser}",
            inline: true
        ])

        fields.add([
            name: '📧 Email',
            value: "${commitEmail}",
            inline: true
        ])

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

        // Add commit message
        if (commitMessage != 'N/A' && commitMessage.length() > 0) {
            def truncatedMessage = commitMessage.length() > 100 ? commitMessage.substring(0, 100) + '...' : commitMessage
            fields.add([
                name: '💬 Commit Message',
                value: truncatedMessage,
                inline: false
            ])
        }

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

def sendEmailNotification(String buildStatus, String subject) {
    try {
        // --- Information Gathering ---
        def commitAuthor = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
        def commitEmail = sh(script: "git log -1 --pretty=format:'%ae'", returnStdout: true).trim()
        def commitMessage = sh(script: "git log -1 --pretty=format:'%s'", returnStdout: true).trim()

        // --- Recipient List ---
        def recipientList = "${commitEmail},${env.STAKEHOLDER_EMAILS}"
        echo "Preparing to send email to: ${recipientList}"

        // ======================= NEW PART =======================
        // Create a variable to hold our error details. It will be empty on success.
        def errorDetails = ''

        // If the build failed, grab the last 20 lines of the log.
        if (buildStatus == 'FAILURE') {
            def logLines = currentBuild.rawBuild.getLog(20).join('\n')
            def truncatedLog = logLines.length() > 1500 ? logLines.substring(0, 1500) + '...' : logLines

            // IMPORTANT: Escape HTML characters in the log to prevent breaking the email format.
            def safeLog = truncatedLog.replace('<', '&lt;').replace('>', '&gt;')

            // Format the log into a nice HTML block. <pre> preserves whitespace and newlines.
            errorDetails = """
            <h3>📋 Error Log (Last 20 Lines):</h3>
            <pre style="background-color:#f1f1f1; border:1px solid #ccc; padding:10px; border-radius:5px;"><code>${safeLog}</code></pre>
            """
        }
        // ===================== END NEW PART =====================

        // --- Email Body ---
        def emailBody = """
        <html>
        <body>
          <h2>Build Status: <font color="${buildStatus == 'SUCCESS' ? 'green' : 'red'}">${buildStatus}</font></h2>
          <p>
            The pipeline for <b>${currentBuild.fullDisplayName}</b> has completed.
          </p>
          <hr>
          <h3>Build Details:</h3>
          <ul>
            <li><b>Status:</b> ${buildStatus}</li>
            <li><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></li>
            <li><b>Branch/Tag:</b> ${env.BRANCH_NAME ?: env.TAG_NAME ?: 'N/A'}</li>
          </ul>
          <h3>Commit Details:</h3>
          <ul>
            <li><b>Author:</b> ${commitAuthor}</li>
            <li><b>Commit Message:</b> <i>${commitMessage}</i></li>
          </ul>

          <!-- This line will now insert our error block, but only on failure -->
          ${errorDetails}

          <hr>
          <p>
            Please check the <a href="${env.BUILD_URL}console">Console Output</a> for the full logs.
          </p>
        </body>
        </html>
        """

        // --- Send the Email ---
        emailext(
            to: recipientList,
            from: env.SENDER_EMAIL,
            subject: subject,
            body: emailBody,
            mimeType: 'text/html'
        )
    } catch (Exception e) {
        echo "Warning: Could not send email notification. Error: ${e.message}"
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
        STAGING_HOST_IP = '20.244.45.25' // Your Azure VM IP
        STAGING_HOST_USER = 'azureuser'   // Your Azure VM User
        SENDER_EMAIL = 'pipeworker@algowrite.com'
        STAKEHOLDER_EMAILS = 'armadushapravinda@gmail.com'
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

        // need to modify this stage to fit your development deployment strategy
        stage('Deploy to Development') {
            when {
                branch 'development'
            }
            steps {
                echo 'Deploying to Development Server...'

                script {
                    sendDiscordNotification(
                        'DEPLOYMENT',
                        '3447003',
                        '🚀 Deployed to Staging',
                        [
                            '🌐 Environment': 'Staging',
                            '🔗 Application URL': "[Visit Staging Site](${env.STAGING_URL})",
                            '✅ Status': 'Deployment completed successfully'
                        ]
                    )
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch "${MAIN_BRANCH_NAME}"
            }
            steps {
                echo 'Deploying to Staging (Host as Control Node Method)...'

                // sshagent provides the SSH key for the ssh and scp commands below
                sshagent(credentials: ['ansible-ssh-key']) {
                    withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')]) {
                        sh """
                            # --- MODIFICATION ---
                            # Point this variable to your existing, permanent directory.
                            HOST_PROJECT_PATH="/home/${STAGING_HOST_USER}/ansible-projects/laravel-test-project"

                            # Create the vault password file inside the container's workspace
                            echo \$VAULT_PASS > .vault_pass.txt

                            # We don't need to 'mkdir' because the directory already exists.

                            # Copy the files from the container's workspace to the host's permanent directory.
                            # The '/*' ensures we copy the contents into the target directory.
                            # We also copy the vault pass file separately.
                            scp -o StrictHostKeyChecking=no -r * ${STAGING_HOST_USER}@${STAGING_HOST_IP}:\${HOST_PROJECT_PATH}/
                            scp -o StrictHostKeyChecking=no .vault_pass.txt ${STAGING_HOST_USER}@${STAGING_HOST_IP}:\${HOST_PROJECT_PATH}/

                            # SSH to the host and run ansible-playbook FROM your permanent directory
                            ssh -o StrictHostKeyChecking=no ${STAGING_HOST_USER}@${STAGING_HOST_IP} "cd \${HOST_PROJECT_PATH} && ansible-playbook -i inventory.ini deploy.yml --limit staging --vault-password-file .vault_pass.txt"

                            # Clean up the password file from the container's workspace
                            rm .vault_pass.txt

                            # We should NOT clean up the host directory in this case.
                        """
                    }
                }

                script {
                    sendDiscordNotification(
                        'DEPLOYMENT',
                        '3447003',
                        '🚀 Deployed to Staging',
                        [
                            '🌐 Environment': 'Staging',
                            '🔗 Application URL': "[Visit Staging Site](${env.STAGING_URL})",
                            '✅ Status': 'Deployment completed successfully'
                        ]
                    )
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

                sendEmailNotification('SUCCESS', "✅ Success: ${currentBuild.fullDisplayName}")
            }

            echo 'Cleaning up workspace...'
            cleanWs()
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
                sendEmailNotification('FAILURE', "❌ FAILED: ${currentBuild.fullDisplayName}")
            }
            echo 'Cleaning up workspace...'
            cleanWs()
        }
    }
}
