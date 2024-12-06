#!/bin/bash

# Variables
REPO_URL="https://github.com/SyedAhmed-Coder/k8s.git"
BASE_DIR="../argocd/applications"  # Root directory for applications
NAMESPACES=("dev" "stage" "prod")  # Environments/namespaces
MICROSERVICES=("user1")  # List of microservices

# Create Base Directory if it doesn't exist
mkdir -p $BASE_DIR

# Generate Application YAMLs
for service in "${MICROSERVICES[@]}"; do
  # Create a subdirectory for each microservice
  SERVICE_DIR="$BASE_DIR/$service"
  mkdir -p $SERVICE_DIR

  for env in "${NAMESPACES[@]}"; do
    # Define file path
    FILE_PATH="$SERVICE_DIR/${service}-${env}.yaml"

    # Set targetRevision based on the namespace
    TARGET_REVISION=$env

    # Generate YAML content
    cat <<EOF > "$FILE_PATH"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${service}-${env}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: $TARGET_REVISION
    path: helm-charts/${service}/helm-chart
    helm:
      valueFiles:
        - values-${env}.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: ${env}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

    echo "Generated: $FILE_PATH"
  done
done


