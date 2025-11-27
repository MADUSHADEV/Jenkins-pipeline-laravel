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
        }

        // --- Recipient List ---
        def recipientList = "${commitEmail},${env.STAKEHOLDER_EMAILS}"
        echo "Preparing to send email to: ${recipientList}"

        // Determine colors based on status
        def statusColor = buildStatus == 'SUCCESS' ? '#10b981' : '#ef4444'
        def statusBgColor = buildStatus == 'SUCCESS' ? '#d1fae5' : '#fee2e2'
        def statusIcon = buildStatus == 'SUCCESS' ? '✅' : '❌'

        // Create error details section
        def errorDetails = ''
        if (buildStatus == 'FAILURE') {
            try {
                def logLines = currentBuild.rawBuild.getLog(15).join('\n')
                def truncatedLog = logLines.length() > 1000 ? logLines.substring(0, 1000) + '...' : logLines
                def safeLog = truncatedLog.replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;')

                errorDetails = """
                <div style="margin-top: 20px; padding: 15px; background-color: #fee2e2; border-left: 4px solid #ef4444; border-radius: 4px;">
                    <h3 style="margin-top: 0; color: #991b1b; font-size: 14px;">Error Log</h3>
                    <pre style="background-color: #ffffff; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 11px; line-height: 1.4; color: #374151; white-space: pre-wrap; word-wrap: break-word;"><code>${safeLog}</code></pre>
                </div>
                """
            } catch (Exception e) {
                echo "Could not retrieve error logs: ${e.message}"
            }
        }

        // --- Simplified Email Body ---
        def emailBody = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                </head>
                <body style="margin: 0; padding: 20px; font-family: Arial, sans-serif; background-color: #f5f5f5;">
                    <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                        <!-- Header -->
                        <tr>
                            <td style="background-color: #667eea; padding: 20px; text-align: center;">
                                <h1 style="margin: 0; color: #ffffff; font-size: 24px;">Jenkins CI/CD Pipeline</h1>
                            </td>
                        </tr>

                        <!-- Status Badge -->
                        <tr>
                            <td style="padding: 20px; text-align: center;">
                                <div style="display: inline-block; background-color: ${statusBgColor}; color: ${statusColor}; padding: 10px 20px; border-radius: 4px; font-size: 16px; font-weight: bold;">
                                    ${statusIcon} Build ${buildStatus}
                                </div>
                            </td>
                        </tr>

                        <!-- Content -->
                        <tr>
                            <td style="padding: 0 20px 20px 20px;">
                                <p style="margin: 0 0 15px 0; color: #666666; font-size: 14px;">
                                    Pipeline: <strong>${currentBuild.fullDisplayName}</strong>
                                </p>

                                <!-- Build Info -->
                                <table width="100%" cellpadding="8" cellspacing="0" style="background-color: #f9fafb; border-radius: 4px; margin-bottom: 15px;">
                                    <tr>
                                        <td colspan="2" style="padding: 10px; border-bottom: 1px solid #e5e7eb;">
                                            <strong style="color: #111827;">Build Information</strong>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280; width: 40%;">Status:</td>
                                        <td style="color: #111827;"><strong>${buildStatus}</strong></td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280;">Build Number:</td>
                                        <td style="color: #111827;">#${currentBuild.number}</td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280;">Branch/Tag:</td>
                                        <td style="color: #111827;">${env.BRANCH_NAME ?: env.TAG_NAME ?: 'N/A'}</td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280;">Duration:</td>
                                        <td style="color: #111827;">${currentBuild.durationString.replace(' and counting', '')}</td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280;">Triggered By:</td>
                                        <td style="color: #111827;">${jenkinsUser}</td>
                                    </tr>
                                </table>

                                <!-- Commit Info -->
                                <table width="100%" cellpadding="8" cellspacing="0" style="background-color: #f9fafb; border-radius: 4px; margin-bottom: 15px;">
                                    <tr>
                                        <td colspan="2" style="padding: 10px; border-bottom: 1px solid #e5e7eb;">
                                            <strong style="color: #111827;">Commit Details</strong>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280; width: 40%;">Author:</td>
                                        <td style="color: #111827;">${commitAuthor}</td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280;">Email:</td>
                                        <td style="color: #111827;">${commitEmail}</td>
                                    </tr>
                                    <tr>
                                        <td style="color: #6b7280; vertical-align: top;">Message:</td>
                                        <td style="color: #111827; font-style: italic;">${commitMessage}</td>
                                    </tr>
                                </table>

                                ${errorDetails}

                                <!-- Button -->
                                <div style="text-align: center; margin: 20px 0;">
                                    <a href="${env.BUILD_URL}console" style="display: inline-block; background-color: #667eea; color: #ffffff; text-decoration: none; padding: 10px 24px; border-radius: 4px; font-size: 14px; font-weight: bold;">
                                        View Console Output
                                    </a>
                                </div>

                                <!-- Links -->
                                <div style="text-align: center; margin-top: 15px; font-size: 13px;">
                                    <a href="${env.BUILD_URL}" style="color: #667eea; text-decoration: none; margin: 0 10px;">Build Details</a> |
                                    <a href="${env.BUILD_URL}changes" style="color: #667eea; text-decoration: none; margin: 0 10px;">View Changes</a>
                                </div>
                            </td>
                        </tr>

                        <!-- Footer -->
                        <tr>
                            <td style="background-color: #f9fafb; padding: 15px; text-align: center; border-top: 1px solid #e5e7eb; font-size: 12px; color: #9ca3af;">
                                Jenkins CI/CD Pipeline<br>
                                ${new Date().format('yyyy-MM-dd HH:mm:ss')}
                            </td>
                        </tr>
                    </table>
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

        echo "Email notification sent successfully to: ${recipientList}"
    } catch (Exception e) {
        echo "Warning: Could not send email notification. Error: ${e.message}"
        e.printStackTrace()
    }
}

// ...existing code...

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
        ANSIBLE_BASE_PATH = '/ansible-library'
        PROJECT_DIR = 'laravel-test-project'
        STAGING_HOST_USER = 'azureuser'   // Your Azure VM User
        SENDER_EMAIL = 'pipeworker@algowrite.com'
        STAKEHOLDER_EMAILS = 'armadushapravinda@gmail.com'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
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
                input 'Deploy to Staging?'

                // sshagent provides the SSH key for the ssh and scp commands below
                sshagent(credentials: ['ansible-ssh-key']) {
                    withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')]) {
                        sh """
                            echo \$VAULT_PASS > .vault_pass.txt

                            // Debug: Verify the container can see the specific files
                            sh "ls -la ${ANSIBLE_BASE_PATH}/${PROJECT_DIR}"
                            
                            # Run Ansible pointing to the specific subdirectory

                            ansible-playbook \
                                -i ${ANSIBLE_BASE_PATH}/${PROJECT_DIR}/inventory.ini \
                                ${ANSIBLE_BASE_PATH}/${PROJECT_DIR}/deploy.yml \
                                --limit staging \
                                --vault-password-file .vault_pass.txt

                            rm .vault_pass.txt
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

                sh "cp -a ${env.ANSIBLE_PROJECT_PATH}/. ."

                sshagent(credentials: ['ansible-ssh-key']) {
                    withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')]) {
                        sh """
                            echo \$VAULT_PASS > .vault_pass.txt

                            // Debug: Verify the container can see the specific files
                            sh "ls -la ${ANSIBLE_BASE_PATH}/${PROJECT_DIR}"

                            ansible-playbook \
                                -i ${ANSIBLE_BASE_PATH}/${PROJECT_DIR}/inventory.ini \
                                ${ANSIBLE_BASE_PATH}/${PROJECT_DIR}/deploy.yml \
                                --limit production \
                                --vault-password-file .vault_pass.txt

                            rm .vault_pass.txt
                    """
                    }
                }

                script {
                    sendDiscordNotification(
                        'DEPLOYMENT',
                        '3447003',
                        '🚀 Deployed to Production',
                        [
                            '🌐 Environment': 'Production',
                            '🔗 Application URL': "[Visit Production Site](${env.PRODUCTION_URL})",
                            '✅ Status': 'Deployment completed successfully'
                        ]
                    )
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
