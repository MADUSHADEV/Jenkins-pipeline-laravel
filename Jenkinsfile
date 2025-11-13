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
        def commitHash = sh(script: "git log -1 --pretty=format:'%h'", returnStdout: true).trim()

        // Get Jenkins user who triggered the build
        def triggeredBy = currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')
        def jenkinsUser = 'Automated'
        if (triggeredBy) {
            jenkinsUser = triggeredBy[0]?.userId ?: 'Automated'
        } else {
            def scmTrigger = currentBuild.getBuildCauses('hudson.triggers.SCMTrigger$SCMTriggerCause')
            if (scmTrigger) {
                jenkinsUser = 'SCM Change'
            }
            def timerTrigger = currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause')
            if (timerTrigger) {
                jenkinsUser = 'Scheduled Build'
            }
        }

        // --- Recipient List ---
        def recipientList = "${commitEmail},${env.STAKEHOLDER_EMAILS}"
        echo "Preparing to send email to: ${recipientList}"

        // --- Status Color and Icon ---
        def statusColor = buildStatus == 'SUCCESS' ? '#10B981' : '#EF4444'
        def statusBgColor = buildStatus == 'SUCCESS' ? '#D1FAE5' : '#FEE2E2'
        def statusIcon = buildStatus == 'SUCCESS' ? '✅' : '❌'
        def statusText = buildStatus == 'SUCCESS' ? 'Success' : 'Failed'

        // --- Error Details Section ---
        def errorSection = ''
        if (buildStatus == 'FAILURE') {
            def logLines = currentBuild.rawBuild.getLog(20).join('\n')
            def truncatedLog = logLines.length() > 1500 ? logLines.substring(0, 1500) + '...' : logLines
            def safeLog = truncatedLog.replace('<', '&lt;').replace('>', '&gt;')

            errorSection = """
            <div style="margin-top: 30px; background: #FEF2F2; border-left: 4px solid #DC2626; padding: 20px; border-radius: 8px;">
                <h3 style="margin: 0 0 15px 0; color: #991B1B; font-size: 16px; font-weight: 600;">
                    🔍 Error Details
                </h3>
                <pre style="background: #FFF; border: 1px solid #FCA5A5; padding: 15px; border-radius: 6px; overflow-x: auto; margin: 0; font-size: 13px; line-height: 1.6; color: #374151;"><code>${safeLog}</code></pre>
            </div>
            """
        }

        // --- Success Deployment Info ---
        def deploymentSection = ''
        if (buildStatus == 'SUCCESS') {
            def environment = ''
            def deploymentUrl = ''

            if (env.BRANCH_NAME == env.MAIN_BRANCH_NAME) {
                environment = 'Staging'
                deploymentUrl = env.STAGING_URL
            } else if (env.TAG_NAME) {
                environment = 'Production'
                deploymentUrl = env.PRODUCTION_URL
            }

            if (environment) {
                deploymentSection = """
                <div style="margin-top: 30px; background: #ECFDF5; border-left: 4px solid #10B981; padding: 20px; border-radius: 8px;">
                    <h3 style="margin: 0 0 15px 0; color: #065F46; font-size: 16px; font-weight: 600;">
                        🚀 Deployment Information
                    </h3>
                    <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                            <td style="padding: 10px 0; color: #6B7280; font-size: 14px; width: 150px;">
                                <strong>Environment:</strong>
                            </td>
                            <td style="padding: 10px 0; color: #111827; font-size: 14px;">
                                <span style="background: #10B981; color: white; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">
                                    ${environment}
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <td style="padding: 10px 0; color: #6B7280; font-size: 14px;">
                                <strong>Application URL:</strong>
                            </td>
                            <td style="padding: 10px 0; font-size: 14px;">
                                <a href="${deploymentUrl}" style="color: #2563EB; text-decoration: none; font-weight: 500;">
                                    ${deploymentUrl}
                                </a>
                            </td>
                        </tr>
                    </table>
                </div>
                """
            }
        }

        // --- Email Body with Modern Design ---
        def emailBody = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F3F4F6;">
            <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #F3F4F6; padding: 40px 0;">
                <tr>
                    <td align="center">
                        <!-- Main Container -->
                        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #FFFFFF; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;">

                            <!-- Header with Status Banner -->
                            <tr>
                                <td style="background: linear-gradient(135deg, ${statusColor} 0%, ${statusColor}dd 100%); padding: 40px 40px 30px 40px; text-align: center;">
                                    <div style="font-size: 48px; margin-bottom: 10px;">${statusIcon}</div>
                                    <h1 style="margin: 0; color: #FFFFFF; font-size: 28px; font-weight: 700; letter-spacing: -0.5px;">
                                        Build ${statusText}
                                    </h1>
                                    <p style="margin: 10px 0 0 0; color: #FFFFFF; font-size: 16px; opacity: 0.95;">
                                        ${currentBuild.fullDisplayName}
                                    </p>
                                </td>
                            </tr>

                            <!-- Content Section -->
                            <tr>
                                <td style="padding: 40px;">

                                    <!-- Build Status Card -->
                                    <div style="background: ${statusBgColor}; padding: 20px; border-radius: 12px; margin-bottom: 30px; border: 1px solid ${statusColor}33;">
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding: 8px 0;">
                                                    <span style="color: #6B7280; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">Status</span>
                                                </td>
                                                <td align="right" style="padding: 8px 0;">
                                                    <span style="background: ${statusColor}; color: white; padding: 6px 16px; border-radius: 20px; font-size: 13px; font-weight: 600;">
                                                        ${statusText}
                                                    </span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 8px 0;">
                                                    <span style="color: #6B7280; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">Duration</span>
                                                </td>
                                                <td align="right" style="padding: 8px 0;">
                                                    <span style="color: #111827; font-size: 14px; font-weight: 600;">
                                                        ${currentBuild.durationString.replace(' and counting', '')}
                                                    </span>
                                                </td>
                                            </tr>
                                        </table>
                                    </div>

                                    <!-- Build Information -->
                                    <div style="margin-bottom: 30px;">
                                        <h2 style="margin: 0 0 20px 0; color: #111827; font-size: 18px; font-weight: 600; border-bottom: 2px solid #E5E7EB; padding-bottom: 10px;">
                                            📦 Build Information
                                        </h2>
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px; width: 180px;">
                                                    <strong>Branch/Tag:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px;">
                                                    <span style="background: #E0E7FF; color: #3730A3; padding: 4px 12px; border-radius: 6px; font-family: 'Monaco', 'Courier New', monospace; font-size: 13px;">
                                                        ${env.BRANCH_NAME ?: env.TAG_NAME ?: 'N/A'}
                                                    </span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px;">
                                                    <strong>Triggered By:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px; font-weight: 500;">
                                                    ${jenkinsUser}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px;">
                                                    <strong>Build Number:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px; font-weight: 500;">
                                                    #${env.BUILD_NUMBER}
                                                </td>
                                            </tr>
                                        </table>
                                    </div>

                                    <!-- Commit Information -->
                                    <div style="margin-bottom: 30px;">
                                        <h2 style="margin: 0 0 20px 0; color: #111827; font-size: 18px; font-weight: 600; border-bottom: 2px solid #E5E7EB; padding-bottom: 10px;">
                                            💬 Commit Details
                                        </h2>
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px; width: 180px;">
                                                    <strong>Author:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px; font-weight: 500;">
                                                    ${commitAuthor}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px;">
                                                    <strong>Email:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px;">
                                                    <a href="mailto:${commitEmail}" style="color: #2563EB; text-decoration: none;">
                                                        ${commitEmail}
                                                    </a>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px;">
                                                    <strong>Commit Hash:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px;">
                                                    <span style="background: #F3F4F6; padding: 4px 10px; border-radius: 6px; font-family: 'Monaco', 'Courier New', monospace; font-size: 13px;">
                                                        ${commitHash}
                                                    </span>
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style="padding: 12px 0; color: #6B7280; font-size: 14px; vertical-align: top;">
                                                    <strong>Message:</strong>
                                                </td>
                                                <td style="padding: 12px 0; color: #111827; font-size: 14px; line-height: 1.6;">
                                                    <em>"${commitMessage}"</em>
                                                </td>
                                            </tr>
                                        </table>
                                    </div>

                                    <!-- Deployment Section (Success Only) -->
                                    ${deploymentSection}

                                    <!-- Error Section (Failure Only) -->
                                    ${errorSection}

                                    <!-- Action Buttons -->
                                    <div style="margin-top: 40px; text-align: center;">
                                        <table width="100%" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td align="center" style="padding: 0 10px;">
                                                    <a href="${env.BUILD_URL}" style="display: inline-block; background: #2563EB; color: #FFFFFF; padding: 14px 32px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 14px; box-shadow: 0 2px 4px rgba(37, 99, 235, 0.3);">
                                                        📊 View Build Details
                                                    </a>
                                                </td>
                                                <td align="center" style="padding: 0 10px;">
                                                    <a href="${env.BUILD_URL}console" style="display: inline-block; background: #F3F4F6; color: #374151; padding: 14px 32px; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 14px; border: 1px solid #D1D5DB;">
                                                        🖥️ Console Output
                                                    </a>
                                                </td>
                                            </tr>
                                        </table>
                                    </div>

                                </td>
                            </tr>

                            <!-- Footer -->
                            <tr>
                                <td style="background: #F9FAFB; padding: 30px 40px; border-top: 1px solid #E5E7EB;">
                                    <table width="100%" cellpadding="0" cellspacing="0">
                                        <tr>
                                            <td align="center">
                                                <p style="margin: 0 0 8px 0; color: #6B7280; font-size: 13px;">
                                                    Jenkins CI/CD Pipeline
                                                </p>
                                                <p style="margin: 0; color: #9CA3AF; font-size: 12px;">
                                                    ${new Date().format("EEEE, MMMM dd, yyyy 'at' hh:mm a", TimeZone.getDefault())}
                                                </p>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td align="center" style="padding-top: 15px;">
                                                <p style="margin: 0; color: #9CA3AF; font-size: 11px;">
                                                    This is an automated message from Jenkins. Please do not reply to this email.
                                                </p>
                                            </td>
                                        </tr>
                                    </table>
                                </td>
                            </tr>

                        </table>
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
