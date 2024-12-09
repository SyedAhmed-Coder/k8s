# Variables
BASE_DIR="helm-charts"
MICROSERVICES=("user3") # Add more microservices as needed
IMAGE_REPOSITORY="wasti87/exercise-5"

# Function to create Helm chart files
create_helm_files() {
  local service_name=$1
  local namespace=$2
  local base_path="$BASE_DIR/$service_name/helm-chart"

  # Create directories
  mkdir -p "$base_path/templates"

  # Chart.yaml
  cat > "$base_path/Chart.yaml" <<EOF
apiVersion: v2
name: $service_name
description: A Helm chart for deploying the $service_name service
type: application
version: 0.1.0
appVersion: "1.0"
keywords:
  - $service_name
  - service
  - helm
maintainers:
  - name: Syed Ahmed
    email: syed.ahmed@solarinformatics.com
sources:
  - https://github.com/your-repo/$service_name-service
EOF

  # values.yaml
#   cat > "$base_path/values.yaml" <<EOF
# namespace: $namespace
# fullnameOverride: "$service_name-service"

# image:
#   repository: $IMAGE_REPOSITORY
#   tag: $namespace

# name: "$service_name"
# replicas: 2
# containerPort: 3000
# nodeEnv: "development"
# port: 3000

# service:
#   port: 80
#   targetPort: 3000
# EOF

  # ConfigMap
  cat > "$base_path/templates/configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Values.service.name }}-config"
  namespace: "{{ .Values.namespace }}"
data:
  NODE_ENV: "{{ .Values.nodeapp.nodeEnv }}"
  PORT: "{{ .Values.nodeapp.port }}"
EOF

  # Secret
  cat > "$base_path/templates/secret.yaml" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: "{{ .Values.service.name }}-secret"
  namespace: "{{ .Values.namespace }}"
type: Opaque
data:
  data-value-key: bW9uZ29kYitzcnY6Ly9zeWVkYWhtZWR3Om9DVjZMUzFUNlJmMUZ1ZjRAY2x1c3RlcjAuejJ1bnkubW9uZ29kYi5uZXQvP3JldHJ5V3JpdGVzPXRydWUmdz1tYWpvcml0eSZhcHBOYW1lPUNsdXN0ZXIw
EOF

  # Deployment
  cat > "$base_path/templates/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "{{ .Values.service.name }}-deployment"
  namespace: "{{ .Values.namespace }}"
spec:
  replicas: {{ .Values.containerconfig.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.service.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.service.name }}
    spec:
      containers:
      - name: {{ .Values.service.name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: {{ .Values.containerconfig.containerPort }}
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: "{{ .Values.service.name }}-config"
              key: NODE_ENV
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: "{{ .Values.service.name }}-config"
              key: PORT
        - name: data-value
          valueFrom:
            secretKeyRef:
              name: "{{ .Values.service.name }}-secret"
              key: data-value-key
EOF

  # Service
  cat > "$base_path/templates/service.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.name }}
  namespace: {{ .Values.namespace }}
spec:
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  selector:
    app: {{ .Values.service.name }}
EOF

  # Environment-specific values files
  for env in dev stage preprod prod; do
    cat > "$base_path/values-$env.yaml" <<EOF
namespace: $env

image:
  repository: $IMAGE_REPOSITORY
  tag: $env

ContainerConfig:
  replicas: 2
  containerPort: 3000

service:
  name: "$service_name"  
  port: 80
  targetPort: 3000

nodeapp:
  nodeEnv: "$env"
  port: 3000

EOF
  done
}

# Main script logic
echo "Creating Helm chart directory structure..."

for service in "${MICROSERVICES[@]}"; do
  create_helm_files "$service" "dev" # Default namespace can be overridden if needed
  echo "Helm chart created for service: $service"
done

echo "Helm charts generated successfully in $BASE_DIR."