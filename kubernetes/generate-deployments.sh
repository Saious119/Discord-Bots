#!/bin/bash

# Script to generate Kubernetes deployment manifests for all Discord bots
# This creates deployment YAML files for each bot with appropriate configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENTS_DIR="$SCRIPT_DIR/deployments"

# Create deployments directory if it doesn't exist
mkdir -p "$DEPLOYMENTS_DIR"

# Function to generate deployment for Go bots
generate_go_deployment() {
    local BOT_NAME=$1
    local IMAGE_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]')

    cat > "$DEPLOYMENTS_DIR/${IMAGE_NAME}.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
  labels:
    app: ${IMAGE_NAME}
    language: go
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${IMAGE_NAME}
  template:
    metadata:
      labels:
        app: ${IMAGE_NAME}
        language: go
    spec:
      containers:
      - name: ${IMAGE_NAME}
        image: localhost:5000/${IMAGE_NAME}:latest
        imagePullPolicy: Always
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        volumeMounts:
        - name: auth
          mountPath: /app/auth.txt
          subPath: auth.txt
          readOnly: true
      volumes:
      - name: auth
        secret:
          secretName: ${IMAGE_NAME}-secret
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
spec:
  selector:
    app: ${IMAGE_NAME}
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    echo "Generated: ${IMAGE_NAME}.yaml"
}

# Function to generate deployment for C# bots
generate_csharp_deployment() {
    local BOT_NAME=$1
    local IMAGE_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]')

    cat > "$DEPLOYMENTS_DIR/${IMAGE_NAME}.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
  labels:
    app: ${IMAGE_NAME}
    language: csharp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${IMAGE_NAME}
  template:
    metadata:
      labels:
        app: ${IMAGE_NAME}
        language: csharp
    spec:
      containers:
      - name: ${IMAGE_NAME}
        image: localhost:5000/${IMAGE_NAME}:latest
        imagePullPolicy: Always
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        volumeMounts:
        - name: auth
          mountPath: /app/auth.txt
          subPath: auth.txt
          readOnly: true
      volumes:
      - name: auth
        secret:
          secretName: ${IMAGE_NAME}-secret
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
spec:
  selector:
    app: ${IMAGE_NAME}
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    echo "Generated: ${IMAGE_NAME}.yaml"
}

# Function to generate deployment for Node.js bots
generate_nodejs_deployment() {
    local BOT_NAME=$1
    local IMAGE_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]')

    cat > "$DEPLOYMENTS_DIR/${IMAGE_NAME}.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
  labels:
    app: ${IMAGE_NAME}
    language: nodejs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${IMAGE_NAME}
  template:
    metadata:
      labels:
        app: ${IMAGE_NAME}
        language: nodejs
    spec:
      containers:
      - name: ${IMAGE_NAME}
        image: localhost:5000/${IMAGE_NAME}:latest
        imagePullPolicy: Always
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "300m"
        volumeMounts:
        - name: auth
          mountPath: /app/auth.json
          subPath: auth.json
          readOnly: true
      volumes:
      - name: auth
        secret:
          secretName: ${IMAGE_NAME}-secret
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
spec:
  selector:
    app: ${IMAGE_NAME}
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    echo "Generated: ${IMAGE_NAME}.yaml"
}

# Function to generate deployment for Python bots
generate_python_deployment() {
    local BOT_NAME=$1
    local IMAGE_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]')
    local AUTH_FILE=$2

    cat > "$DEPLOYMENTS_DIR/${IMAGE_NAME}.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
  labels:
    app: ${IMAGE_NAME}
    language: python
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${IMAGE_NAME}
  template:
    metadata:
      labels:
        app: ${IMAGE_NAME}
        language: python
    spec:
      containers:
      - name: ${IMAGE_NAME}
        image: localhost:5000/${IMAGE_NAME}:latest
        imagePullPolicy: Always
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "300m"
        volumeMounts:
        - name: auth
          mountPath: /app/${AUTH_FILE}
          subPath: ${AUTH_FILE}
          readOnly: true
      volumes:
      - name: auth
        secret:
          secretName: ${IMAGE_NAME}-secret
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name: ${IMAGE_NAME}
  namespace: discord-bots
spec:
  selector:
    app: ${IMAGE_NAME}
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
    echo "Generated: ${IMAGE_NAME}.yaml"
}

# Generate deployments for all bots
echo "Generating Kubernetes deployment manifests..."
echo ""

# Go Bots
echo "=== Go Bots ==="
generate_go_deployment "AndyBot"
generate_go_deployment "PirateBot"
generate_go_deployment "WSB"
echo ""

# C# Bots
echo "=== C# Bots ==="
generate_csharp_deployment "BrainCellBot"
generate_csharp_deployment "DickJohnson"
generate_csharp_deployment "HouseMog"
generate_csharp_deployment "MangaNotifier"
generate_csharp_deployment "MovieNightBot"
echo ""

# Node.js Bots
echo "=== Node.js Bots ==="
generate_nodejs_deployment "OwOBot"
generate_nodejs_deployment "OyVeyBot"
generate_nodejs_deployment "RedditSimBot"
generate_nodejs_deployment "TarotBot"
generate_nodejs_deployment "UwUBot"
generate_nodejs_deployment "JailBot"
generate_nodejs_deployment "JonTronBot"
generate_nodejs_deployment "TerryDavisBot"
echo ""

# Python Bots
echo "=== Python Bots ==="
generate_python_deployment "ScribeBot" "auth.txt"
generate_python_deployment "PurpleHaroBot" "auth.txt"
echo ""

echo "All deployment manifests generated successfully!"
echo "Files created in: $DEPLOYMENTS_DIR"
