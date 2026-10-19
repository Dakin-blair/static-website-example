pipeline {
    agent none

    // Variables à adapter selon l'environnement
    environment {
        ID_DOCKER = 'dakinblair'
        IMAGE_NAME = 'static-website'
        IMAGE_TAG = 'latest'
        HOST_IP = '172.17.0.1'
        TEST_PORT = '8000'
        REVIEW_PORT = '82'
        STAGING_PORT = '81'
        PRODUCTION_PORT = '80'
        SLACK_ENABLED = 'true'
    }

    stages {
        // CI : construction de l'image
        stage('Build') {
            agent any
            steps {
                sh 'docker build -t $ID_DOCKER/$IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        // CI : analyse du Dockerfile
        stage('Code quality') {
            agent any
            steps {
                sh 'docker run --rm -i hadolint/hadolint hadolint --failure-threshold error - < Dockerfile'
            }
        }

        // CI : test du site dans un conteneur temporaire
        stage('Tests') {
            agent any
            steps {
                sh '''
                    docker rm -f test-$IMAGE_NAME 2>/dev/null || true
                    docker run -d --name test-$IMAGE_NAME -p $TEST_PORT:80 $ID_DOCKER/$IMAGE_NAME:$IMAGE_TAG
                    sleep 5
                    curl -sf http://$HOST_IP:$TEST_PORT | grep -qi "<html"
                '''
            }
            post {
                always {
                    sh 'docker rm -f test-$IMAGE_NAME || true'
                }
            }
        }

        // CI : envoi de l'image sur Docker Hub (branche master)
        stage('Package') {
            when { expression { env.GIT_BRANCH == 'origin/master' } }
            agent any
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push $ID_DOCKER/$IMAGE_NAME:$IMAGE_TAG
                        docker logout
                    '''
                }
            }
        }

        // CD : environnement de revue (autres branches)
        stage('Review') {
            when { expression { env.GIT_BRANCH != 'origin/master' } }
            agent any
            steps {
                sh '''
                    docker rm -f review-$IMAGE_NAME 2>/dev/null || true
                    docker run -d --name review-$IMAGE_NAME --restart unless-stopped -p $REVIEW_PORT:80 $ID_DOCKER/$IMAGE_NAME:$IMAGE_TAG
                    sleep 5
                    curl -sf http://$HOST_IP:$REVIEW_PORT | grep -qi "<html"
                '''
            }
        }

        // CD : déploiement et test en staging (branche master)
        stage('Staging') {
            when { expression { env.GIT_BRANCH == 'origin/master' } }
            agent any
            steps {
                sh '''
                    docker rm -f staging-$IMAGE_NAME 2>/dev/null || true
                    docker run -d --name staging-$IMAGE_NAME --restart unless-stopped -p $STAGING_PORT:80 $ID_DOCKER/$IMAGE_NAME:$IMAGE_TAG
                    sleep 5
                    curl -sf http://$HOST_IP:$STAGING_PORT | grep -qi "<html"
                '''
            }
        }

        // CD : déploiement et test en production (branche master)
        stage('Production') {
            when { expression { env.GIT_BRANCH == 'origin/master' } }
            agent any
            steps {
                sh '''
                    docker rm -f production-$IMAGE_NAME 2>/dev/null || true
                    docker run -d --name production-$IMAGE_NAME --restart unless-stopped -p $PRODUCTION_PORT:80 $ID_DOCKER/$IMAGE_NAME:$IMAGE_TAG
                    sleep 5
                    curl -sf http://$HOST_IP:$PRODUCTION_PORT | grep -qi "<html"
                '''
            }
        }
    }

    // Notification Slack facultative via la shared library
    post {
        always {
            script {
                if (env.SLACK_ENABLED == 'true') {
                    library 'shared-library'
                    slackNotifier currentBuild.currentResult
                }
            }
        }
    }
}
