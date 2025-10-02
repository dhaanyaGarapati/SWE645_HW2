pipeline {
  agent any

  environment {
    // ---------- EDIT THESE TO MATCH YOUR ENV ----------
    REPO    = 'dhaanyaGarapati/SWE645_HW2'   // GitHub org/repo
    BRANCH  = 'main'                         // branch to build

    PROJECT = 'swe645-a2'                    // GCP project
    REGION  = 'us-central1-a'                  // GKE region
    CLUSTER = 'swe645-cluster'               // GKE cluster name

    NAMESPACE = 'swe645'                     // K8s namespace to use/create
    DEPLOY    = 'swe645-app'                 // Deployment name in your YAML
    IMAGE     = 'trinaya11/survey-web-app'   // Docker Hub repo
    TAG       = "${env.BUILD_NUMBER}"        // image tag per build
    // ---------------------------------------------------
  }

  stages {

    stage('Checkout from GitHub (PAT)') {
      steps {
        withCredentials([string(credentialsId: 'github-token', variable: 'GHTOKEN')]) {
          sh '''
            set -eu
            rm -rf repo
            git --version
            git clone https://${GHTOKEN}@github.com/${REPO}.git repo
            cd repo && git checkout ${BRANCH}
            ls -la
          '''
        }
      }
    }

    stage('Build Docker image') {
      steps {
        sh '''
          set -eu
          cd repo
          docker build -t ${IMAGE}:${TAG} .
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'U', passwordVariable: 'TOKEN')]) {
          sh '''
            set -eu
            echo "$TOKEN" | docker login -u "$U" --password-stdin
            docker push ${IMAGE}:${TAG}
            docker logout
          '''
        }
      }
    }

    stage('GCP auth & connect to GKE') {
      steps {
        withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -eu
            gcloud --version
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project ${PROJECT}
            gcloud container clusters get-credentials ${CLUSTER} --region ${REGION} --project ${PROJECT}
            kubectl version --client=true
          '''
        }
      }
    }

    stage('Deploy to Kubernetes (3 replicas)') {
      steps {
        sh '''
          set -eu
          cd repo

          # Ensure namespace and service exist (idempotent)
          kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
          (kubectl -n ${NAMESPACE} apply -f k8s-service.yaml) || true

          # Create or update deployment
          if kubectl -n ${NAMESPACE} get deploy/${DEPLOY} >/dev/null 2>&1; then
            # Update image on existing deployment (try common container names)
            kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} ${DEPLOY}=${IMAGE}:${TAG} \
              || kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} web=${IMAGE}:${TAG}
            # Enforce at least 3 replicas
            kubectl -n ${NAMESPACE} scale deploy/${DEPLOY} --replicas=3
          else
            # First-time apply; if your YAML already has an image, we still set the new tag below
            kubectl -n ${NAMESPACE} apply -f k8s-deployment.yaml
            kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} ${DEPLOY}=${IMAGE}:${TAG} \
              || kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} web=${IMAGE}:${TAG}
            kubectl -n ${NAMESPACE} scale deploy/${DEPLOY} --replicas=3
          fi

          kubectl -n ${NAMESPACE} rollout status deploy/${DEPLOY} --timeout=180s

          # Show Service external IP if using LoadBalancer
          echo "----- Service status -----"
          kubectl -n ${NAMESPACE} get svc -o wide
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Deployed ${IMAGE}:${TAG} to namespace ${NAMESPACE}"
      echo "Tip: If your Service is type LoadBalancer, open the EXTERNAL-IP from 'kubectl get svc'."
    }
    failure {
      echo "❌ Build/Deploy failed — check the failed stage log for details."
    }
  }
}
