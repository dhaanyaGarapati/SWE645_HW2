//Supraja Naraharisetty(G01507868)
//Trinaya Kodavati (G01506073)
//Lasya Reddy Mekala (G01473683)
//Dhaanya S Garapati (G01512900)
pipeline {
  agent any
  triggers { githubPush() }  
  environment {
    PROJECT   = 'swe645-a2'
    LOCATION  = 'us-central1-a' 
    LOC_FLAG  = '--zone'         
    CLUSTER   = 'swe645-cluster'

    NAMESPACE = 'swe645'
    DEPLOY    = 'swe645-app'
    IMAGE     = 'trinaya11/survey-web-app'
    TAG       = "${env.BUILD_NUMBER}"
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'ls -la'       
      }
    }
    stage('Build Docker image') {
      steps {
        sh '''
          set -eu
          docker build -t ${IMAGE}:${TAG} .
        '''
      }
    }
    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub',
                                          usernameVariable: 'U',
                                          passwordVariable: 'TOKEN')]) {
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
            gcloud container clusters get-credentials ${CLUSTER} ${LOC_FLAG} ${LOCATION} --project ${PROJECT}
            kubectl version --client=true
          '''
        }
      }
    }
    stage('Deploy to Kubernetes (3 replicas)') {
      steps {
        sh '''
          set -eu
          # Ensure namespace and service exist (idempotent)
          kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
          (kubectl -n ${NAMESPACE} apply -f k8s-service.yaml) || true
          # Create or update deployment
          if kubectl -n ${NAMESPACE} get deploy/${DEPLOY} >/dev/null 2>&1; then
            kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} ${DEPLOY}=${IMAGE}:${TAG} \
              || kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} web=${IMAGE}:${TAG}
            kubectl -n ${NAMESPACE} scale deploy/${DEPLOY} --replicas=3
          else
            kubectl -n ${NAMESPACE} apply -f k8s-deployment.yaml
            kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} ${DEPLOY}=${IMAGE}:${TAG} \
              || kubectl -n ${NAMESPACE} set image deploy/${DEPLOY} web=${IMAGE}:${TAG}
            kubectl -n ${NAMESPACE} scale deploy/${DEPLOY} --replicas=3
          fi
          kubectl -n ${NAMESPACE} rollout status deploy/${DEPLOY} --timeout=180s
          echo "----- Service status -----"
          kubectl -n ${NAMESPACE} get svc -o wide
        '''
      }
    }
  }
  post {
    success {
      echo "Deployed ${IMAGE}:${TAG} to namespace ${NAMESPACE}"
    }
    failure {
      echo "Build/Deploy failed — see the failing stage logs"
    }
  }
}
