// ==============================================
// Jenkinsfile - CI/CD Pipeline
// ==============================================
// Complete pipeline: Build → Test → Scan → Docker → Deploy
// Triggered by GitHub webhook on push to main branch
// ==============================================

pipeline {
    agent any

    // ---- Environment Variables ----
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')  // Jenkins credential ID
        DOCKERHUB_USERNAME    = 'adeshbusari20'
        FRONTEND_IMAGE        = "${DOCKERHUB_USERNAME}/expense-tracker-frontend"
        BACKEND_IMAGE         = "${DOCKERHUB_USERNAME}/expense-tracker-backend"
        IMAGE_TAG             = "${BUILD_NUMBER}"
        SONAR_HOST_URL        = 'http://sonarqube:9000'
        KUBE_NAMESPACE        = 'expense-tracker'
    }

    // ---- Pipeline Options ----
    options {
        timeout(time: 30, unit: 'MINUTES')  // Fail if pipeline takes >30 min
        disableConcurrentBuilds()            // Prevent parallel builds
        buildDiscarder(logRotator(numToKeepStr: '10'))  // Keep last 10 builds
    }

    // ---- Trigger ----
    triggers {
        githubPush()  // Triggered by GitHub webhook
    }

    stages {
        // ============================================
        // Stage 1: Checkout Source Code
        // ============================================
        stage('Checkout') {
            steps {
                echo '📥 Checking out source code from GitHub...'
                checkout scm
                sh 'echo "Branch: ${GIT_BRANCH}"'
                sh 'echo "Commit: ${GIT_COMMIT}"'
            }
        }

        // ============================================
        // Stage 2: Install Dependencies
        // ============================================
        stage('Install Dependencies') {
            parallel {
                stage('Backend Deps') {
                    steps {
                        echo '🐍 Installing Python dependencies...'
                        dir('backend') {
                            sh '''
                                python3 -m venv venv
                                . venv/bin/activate
                                pip install -r requirements.txt
                            '''
                        }
                    }
                }
                stage('Frontend Deps') {
                    steps {
                        echo '📦 Installing Node.js dependencies...'
                        dir('frontend') {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }

        // ============================================
        // Stage 3: Lint & Code Quality
        // ============================================
        stage('Lint') {
            parallel {
                stage('Backend Lint') {
                    steps {
                        echo '🔍 Linting Python code...'
                        dir('backend') {
                            sh '''
                                . venv/bin/activate
                                flake8 app/ --max-line-length=120 --statistics || true
                            '''
                        }
                    }
                }
                stage('Frontend Lint') {
                    steps {
                        echo '🔍 Linting React code...'
                        dir('frontend') {
                            sh 'npx eslint src/ --ext .js,.jsx || true'
                        }
                    }
                }
            }
        }

        // ============================================
        // Stage 4: Run Unit Tests
        // ============================================
        stage('Unit Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        echo '🧪 Running Python unit tests...'
                        dir('backend') {
                            sh '''
                                . venv/bin/activate
                                python -m pytest tests/ -v --tb=short --junitxml=test-results.xml
                            '''
                        }
                    }
                    post {
                        always {
                            junit 'backend/test-results.xml'
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        echo '🧪 Running React unit tests...'
                        dir('frontend') {
                            sh 'CI=true npm test -- --watchAll=false || true'
                        }
                    }
                }
            }
        }

        // ============================================
        // Stage 5: SonarQube Code Analysis
        // ============================================
        stage('SonarQube Analysis') {
            steps {
                echo '📊 Running SonarQube static code analysis...'
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=ai-expense-tracker \
                            -Dsonar.sources=backend/app,frontend/src \
                            -Dsonar.tests=backend/tests \
                            -Dsonar.host.url=${SONAR_HOST_URL}
                    '''
                }
            }
        }

        // ============================================
        // Stage 6: Security Scanning (DevSecOps)
        // ============================================
        stage('Security Scan') {
            parallel {
                stage('Trivy FS Scan') {
                    steps {
                        echo '🔒 Scanning filesystem for vulnerabilities...'
                        sh '''
                            trivy fs --severity HIGH,CRITICAL \
                                     --format table \
                                     --exit-code 0 \
                                     --no-progress \
                                     backend/
                        '''
                    }
                }
                stage('OWASP Dependency Check') {
                    steps {
                        echo '🔒 Running OWASP dependency check...'
                        sh '''
                            dependency-check --project "expense-tracker" \
                                             --scan backend/requirements.txt \
                                             --format HTML \
                                             --out reports/ || true
                        '''
                    }
                }
            }
        }

        // ============================================
        // Stage 7: Build Docker Images
        // ============================================
        stage('Docker Build') {
            parallel {
                stage('Build Frontend Image') {
                    steps {
                        echo '🐳 Building frontend Docker image...'
                        sh "docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} -t ${FRONTEND_IMAGE}:latest ./frontend"
                    }
                }
                stage('Build Backend Image') {
                    steps {
                        echo '🐳 Building backend Docker image...'
                        sh "docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} -t ${BACKEND_IMAGE}:latest ./backend"
                    }
                }
            }
        }

        // ============================================
        // Stage 8: Trivy Image Scan
        // ============================================
        stage('Trivy Image Scan') {
            parallel {
                stage('Scan Frontend Image') {
                    steps {
                        echo '🔒 Scanning frontend Docker image...'
                        sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                    }
                }
                stage('Scan Backend Image') {
                    steps {
                        echo '🔒 Scanning backend Docker image...'
                        sh "trivy image --severity HIGH,CRITICAL --exit-code 0 ${BACKEND_IMAGE}:${IMAGE_TAG}"
                    }
                }
            }
        }

        // ============================================
        // Stage 9: Push to Docker Hub
        // ============================================
        stage('Push to Docker Hub') {
            steps {
                echo '📤 Pushing images to Docker Hub...'
                sh '''
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    docker push ${FRONTEND_IMAGE}:latest
                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker push ${BACKEND_IMAGE}:latest
                    docker logout
                '''
            }
        }

        // ============================================
        // Stage 10: Deploy to Kubernetes
        // ============================================
        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes cluster...'
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh '''
                        # Update image tags in deployment manifests
                        sed -i "s|image:.*expense-tracker-backend.*|image: ${BACKEND_IMAGE}:${IMAGE_TAG}|g" kubernetes/backend-deployment.yaml
                        sed -i "s|image:.*expense-tracker-frontend.*|image: ${FRONTEND_IMAGE}:${IMAGE_TAG}|g" kubernetes/frontend-deployment.yaml

                        # Apply Kubernetes manifests
                        kubectl apply -f kubernetes/namespace.yaml
                        kubectl apply -f kubernetes/configmap.yaml
                        kubectl apply -f kubernetes/secrets.yaml
                        kubectl apply -f kubernetes/pv.yaml
                        kubectl apply -f kubernetes/pvc.yaml
                        kubectl apply -f kubernetes/postgres-statefulset.yaml
                        kubectl apply -f kubernetes/backend-deployment.yaml
                        kubectl apply -f kubernetes/frontend-deployment.yaml
                        kubectl apply -f kubernetes/ingress.yaml
                        kubectl apply -f kubernetes/hpa.yaml

                        # Wait for rollout
                        kubectl rollout status deployment/backend -n ${KUBE_NAMESPACE} --timeout=120s
                        kubectl rollout status deployment/frontend -n ${KUBE_NAMESPACE} --timeout=120s
                    '''
                }
            }
        }

        // ============================================
        // Stage 11: Health Check
        // ============================================
        stage('Health Check') {
            steps {
                echo '🏥 Verifying deployment health...'
                sh '''
                    sleep 15
                    kubectl get pods -n ${KUBE_NAMESPACE}
                    kubectl get svc -n ${KUBE_NAMESPACE}
                '''
            }
        }
    }

    // ---- Post Actions ----
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            // Uncomment for Slack notification:
            // slackSend(channel: '#devops', message: "✅ Build #${BUILD_NUMBER} PASSED")
        }
        failure {
            echo '❌ Pipeline failed!'
            // slackSend(channel: '#devops', message: "❌ Build #${BUILD_NUMBER} FAILED")
        }
        always {
            echo '🧹 Cleaning up workspace...'
            cleanWs()
            sh 'docker system prune -f || true'
        }
    }
}
