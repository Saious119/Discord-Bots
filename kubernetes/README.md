# Discord Bots Kubernetes Deployment Guide

This guide will help you deploy all your Discord bots to a k3s Kubernetes cluster.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Managing Deployments](#managing-deployments)
5. [Troubleshooting](#troubleshooting)
6. [Architecture](#architecture)

## Prerequisites

### Required Software

- **k3s** - Lightweight Kubernetes distribution (already installed on your system)
- **kubectl** - Kubernetes command-line tool
- **Docker** - For building container images
- **Bash** - For running deployment scripts

### k3s Setup

If you haven't configured kubectl for k3s yet:

```bash
# k3s kubeconfig is typically at /etc/rancher/k3s/k3s.yaml
# Copy it to your user directory
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Local Docker Registry for k3s

k3s needs access to your Docker images. Set up a local registry:

```bash
# Start a local Docker registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Configure k3s to use the insecure registry
# Edit /etc/rancher/k3s/registries.yaml
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  localhost:5000:
    endpoint:
      - "http://localhost:5000"
configs:
  "localhost:5000":
    tls:
      insecure_skip_verify: true
EOF

# Restart k3s to apply changes
sudo systemctl restart k3s
```

## Quick Start

### Step 1: Build All Docker Images

From the root of the Discord-Bots directory:

```bash
# Make the script executable
chmod +x build-all.sh

# Build and push all images
./build-all.sh
```

This will:
- Build Docker images for all 20 bots
- Tag them with `localhost:5000/botname:latest`
- Push them to your local registry

### Step 2: Generate Deployment Manifests

```bash
cd kubernetes
chmod +x generate-deployments.sh
./generate-deployments.sh
```

This creates Kubernetes YAML files for each bot in the `deployments/` directory.

### Step 3: Deploy Everything

```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

This will:
- Create the `discord-bots` namespace
- Create secrets from your bot auth files
- Deploy all bots to the cluster

### Step 4: Verify Deployment

```bash
# Check if all pods are running
kubectl get pods -n discord-bots

# Watch pods come online
kubectl get pods -n discord-bots -w

# Check deployment status
kubectl get deployments -n discord-bots
```

## Detailed Setup

### Bot Inventory

Your Discord bots organized by language:

#### Go Bots (3)
- **AndyBot** - `localhost:5000/andybot:latest`
- **PirateBot** - `localhost:5000/piratebot:latest`
- **WSB** - `localhost:5000/wsb:latest`

#### C# Bots (5)
- **BrainCellBot** - `localhost:5000/braincellbot:latest`
- **DickJohnson** - `localhost:5000/dickjohnson:latest`
- **HouseMog** - `localhost:5000/housemog:latest`
- **MangaNotifier** - `localhost:5000/manganotifier:latest`
- **MovieNightBot** - `localhost:5000/movienightbot:latest`

#### Node.js Bots (8)
- **OwOBot** - `localhost:5000/owobot:latest`
- **OyVeyBot** - `localhost:5000/oyveybot:latest`
- **RedditSimBot** - `localhost:5000/redditsimbot:latest`
- **TarotBot** - `localhost:5000/tarotbot:latest`
- **UwUBot** - `localhost:5000/uwubot:latest`
- **JailBot** - `localhost:5000/jailbot:latest`
- **JonTronBot** - `localhost:5000/jontronbot:latest`
- **TerryDavisBot** - `localhost:5000/terrydavisbot:latest`

#### Python Bots (2)
- **ScribeBot** - `localhost:5000/scribebot:latest`
- **PurpleHaroBot** - `localhost:5000/purpleharobot:latest`

### Manual Deployment Steps

If you prefer to deploy manually or need more control:

#### 1. Create Namespace

```bash
kubectl apply -f kubernetes/namespace.yaml
```

#### 2. Create Secrets Manually

For bots with `auth.json`:

```bash
kubectl create secret generic andybot-secret \
  --from-file=auth.json=AndyBot/auth.json \
  --namespace=discord-bots
```

For bots with `auth.txt`:

```bash
kubectl create secret generic housemog-secret \
  --from-file=auth.txt=HouseMog/auth.txt \
  --namespace=discord-bots
```

#### 3. Build Individual Bot

```bash
# Example: Build AndyBot
cd AndyBot
docker build -t localhost:5000/andybot:latest .
docker push localhost:5000/andybot:latest
```

#### 4. Deploy Individual Bot

```bash
kubectl apply -f kubernetes/deployments/andybot.yaml
```

### Resource Requirements

Each bot has resource limits configured:

**Go Bots:**
- Requests: 64Mi memory, 50m CPU
- Limits: 128Mi memory, 200m CPU

**C# Bots:**
- Requests: 128Mi memory, 100m CPU
- Limits: 256Mi memory, 500m CPU

**Node.js Bots:**
- Requests: 128Mi memory, 50m CPU
- Limits: 256Mi memory, 300m CPU

**Python Bots:**
- Requests: 128Mi memory, 50m CPU
- Limits: 256Mi memory, 300m CPU

**Total Cluster Requirements (all bots):**
- Memory: ~3-4 GB
- CPU: ~5-6 cores (under load)

## Managing Deployments

### Viewing Bot Status

```bash
# List all pods
kubectl get pods -n discord-bots

# Get detailed pod information
kubectl get pods -n discord-bots -o wide

# View pod details
kubectl describe pod <pod-name> -n discord-bots
```

### Viewing Logs

```bash
# View logs for a specific bot
kubectl logs -n discord-bots -l app=andybot

# Follow logs in real-time
kubectl logs -n discord-bots -l app=andybot -f

# View logs from previous container (if crashed)
kubectl logs -n discord-bots -l app=andybot --previous

# View logs for all bots (not recommended, very verbose)
kubectl logs -n discord-bots --all-containers=true
```

### Scaling Bots

Discord bots typically run as single instances, but you can scale if needed:

```bash
# Scale a bot to 2 replicas (not recommended for Discord bots)
kubectl scale deployment andybot -n discord-bots --replicas=2

# Scale back to 1
kubectl scale deployment andybot -n discord-bots --replicas=1
```

**Note:** Most Discord bots should run with `replicas: 1` to avoid duplicate message handling.

### Restarting Bots

```bash
# Restart a specific bot
kubectl rollout restart deployment/andybot -n discord-bots

# Restart all bots
kubectl rollout restart deployment -n discord-bots
```

### Updating Bot Images

After making code changes:

```bash
# 1. Rebuild the image
cd AndyBot
docker build -t localhost:5000/andybot:latest .
docker push localhost:5000/andybot:latest

# 2. Restart the deployment to pull the new image
kubectl rollout restart deployment/andybot -n discord-bots

# 3. Watch the rollout
kubectl rollout status deployment/andybot -n discord-bots
```

### Deleting Deployments

```bash
# Delete a specific bot
kubectl delete -f kubernetes/deployments/andybot.yaml

# Delete all bots but keep the namespace
kubectl delete deployments --all -n discord-bots

# Delete everything including the namespace
kubectl delete namespace discord-bots
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n discord-bots

# Common statuses and meanings:
# - Pending: Waiting for resources or image pull
# - ImagePullBackOff: Cannot pull Docker image
# - CrashLoopBackOff: Container keeps crashing
# - Running: Bot is running successfully

# Get detailed error information
kubectl describe pod <pod-name> -n discord-bots
```

### ImagePullBackOff Error

This means Kubernetes can't pull the Docker image:

```bash
# Check if image exists in registry
curl http://localhost:5000/v2/_catalog

# Verify image tag
curl http://localhost:5000/v2/andybot/tags/list

# Rebuild and push the image
cd AndyBot
docker build -t localhost:5000/andybot:latest .
docker push localhost:5000/andybot:latest

# Delete the pod to trigger a new pull
kubectl delete pod <pod-name> -n discord-bots
```

### CrashLoopBackOff Error

The bot container is starting but then crashing:

```bash
# View logs to see the error
kubectl logs -n discord-bots -l app=andybot

# Check if secret is mounted correctly
kubectl describe pod <pod-name> -n discord-bots | grep -A 5 "Volumes:"

# Verify secret exists
kubectl get secret andybot-secret -n discord-bots

# Check secret contents (base64 encoded)
kubectl get secret andybot-secret -n discord-bots -o yaml
```

### Secret/Auth File Issues

```bash
# List all secrets
kubectl get secrets -n discord-bots

# View secret details
kubectl describe secret andybot-secret -n discord-bots

# Decode and view secret content
kubectl get secret andybot-secret -n discord-bots -o jsonpath='{.data.auth\.json}' | base64 -d

# Delete and recreate secret
kubectl delete secret andybot-secret -n discord-bots
kubectl create secret generic andybot-secret \
  --from-file=auth.json=../AndyBot/auth.json \
  --namespace=discord-bots
```

### Insufficient Resources

```bash
# Check node resources
kubectl top nodes

# Check pod resource usage
kubectl top pods -n discord-bots

# Describe node to see resource allocation
kubectl describe node <node-name>

# If out of resources, you can:
# 1. Reduce resource limits in deployment files
# 2. Deploy fewer bots
# 3. Add more nodes to your cluster
```

### Network Issues

```bash
# Test DNS resolution inside a pod
kubectl run -it --rm debug --image=busybox --restart=Never -n discord-bots -- nslookup discord.com

# Check if bot can reach Discord API
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n discord-bots -- curl -v https://discord.com/api/v10/gateway
```

### Accessing Pod Shell for Debugging

```bash
# For Alpine-based images (most of our bots)
kubectl exec -it <pod-name> -n discord-bots -- /bin/sh

# Check if auth file is mounted
ls -la /app/auth.json
cat /app/auth.json

# Check environment
env

# Exit the shell
exit
```

## Architecture

### Namespace Structure

```
discord-bots (namespace)
├── Deployments (20 total)
│   ├── andybot
│   ├── piratebot
│   ├── wsb
│   ├── braincellbot
│   ├── dickjohnson
│   ├── housemog
│   ├── manganotifier
│   ├── movienightbot
│   ├── owobot
│   ├── oyveybot
│   ├── redditsimbot
│   ├── tarotbot
│   ├── uwubot
│   ├── jailbot
│   ├── jontronbot
│   ├── terrydavisbot
│   ├── scribebot
│   └── purpleharobot
├── Services (20 total, ClusterIP)
└── Secrets (20 total, one per bot)
```

### Deployment Architecture

Each bot deployment follows this pattern:

```yaml
Deployment
├── 1 Replica (single pod)
├── Resource Limits
├── Volume Mount
│   └── Secret (auth.json or auth.txt)
└── Container
    ├── Image: localhost:5000/botname:latest
    ├── ImagePullPolicy: Always
    └── Non-root user
```

### Image Registry Flow

```
Local Development
    ↓
Docker Build
    ↓
localhost:5000 (Local Registry)
    ↓
k3s Cluster
    ↓
Discord Bots Running
```

## Advanced Configuration

### Using External Registry

If you want to use Docker Hub or another registry:

```bash
# Tag images for Docker Hub
docker tag localhost:5000/andybot:latest yourusername/andybot:latest
docker push yourusername/andybot:latest

# Update deployment YAML
# Change: image: localhost:5000/andybot:latest
# To: image: yourusername/andybot:latest

# Create image pull secret if using private registry
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=yourusername \
  --docker-password=yourpassword \
  --docker-email=your@email.com \
  -n discord-bots

# Add to deployment spec:
# imagePullSecrets:
#   - name: regcred
```

### Persistent Storage

If a bot needs persistent data:

```yaml
# Add to deployment
volumes:
- name: data
  persistentVolumeClaim:
    claimName: botname-pvc
---
# Create PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: botname-pvc
  namespace: discord-bots
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### Health Checks

Add liveness and readiness probes if your bot exposes an HTTP endpoint:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

### Environment Variables

Add environment variables to deployments:

```yaml
env:
- name: NODE_ENV
  value: "production"
- name: LOG_LEVEL
  value: "info"
- name: DISCORD_TOKEN
  valueFrom:
    secretKeyRef:
      name: botname-secret
      key: token
```

## Monitoring

### Basic Monitoring

```bash
# Watch all pods
watch kubectl get pods -n discord-bots

# Monitor resource usage
watch kubectl top pods -n discord-bots

# View events
kubectl get events -n discord-bots --sort-by='.lastTimestamp'
```

### Installing Metrics Server (if not installed)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For k3s, you may need to edit the deployment to add --kubelet-insecure-tls
kubectl edit deployment metrics-server -n kube-system
```

## Backup and Restore

### Backup Secrets

```bash
# Export all secrets
kubectl get secrets -n discord-bots -o yaml > secrets-backup.yaml

# Backup specific secret
kubectl get secret andybot-secret -n discord-bots -o yaml > andybot-secret-backup.yaml
```

### Backup Deployments

```bash
# Export all deployments
kubectl get deployments -n discord-bots -o yaml > deployments-backup.yaml
```

### Restore

```bash
kubectl apply -f secrets-backup.yaml
kubectl apply -f deployments-backup.yaml
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy Bot

on:
  push:
    branches: [ main ]
    paths:
      - 'AndyBot/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Build image
      run: |
        docker build -t localhost:5000/andybot:latest ./AndyBot
        docker push localhost:5000/andybot:latest
    
    - name: Deploy to k3s
      run: |
        kubectl rollout restart deployment/andybot -n discord-bots
```

## Best Practices

1. **One Bot Per Deployment**: Each bot runs independently
2. **Single Replica**: Discord bots should typically run with 1 replica
3. **Resource Limits**: Always set resource limits to prevent resource exhaustion
4. **Non-root Users**: All containers run as non-root for security
5. **Secret Management**: Never commit secrets to git
6. **Image Tags**: Use specific tags in production (not `latest`)
7. **Health Checks**: Implement health endpoints for better reliability
8. **Logging**: Ensure bots log to stdout/stderr for kubectl logs
9. **Graceful Shutdown**: Handle SIGTERM for graceful shutdowns
10. **Monitor Resource Usage**: Watch memory/CPU usage and adjust limits

## Additional Resources

- [k3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Discord Developer Portal](https://discord.com/developers/docs/)

## Support

For issues with:
- **k3s setup**: Check k3s logs with `sudo journalctl -u k3s -f`
- **Docker builds**: Review Dockerfile and build output
- **Bot crashes**: Check bot logs with `kubectl logs`
- **Resource issues**: Monitor with `kubectl top nodes` and `kubectl top pods`

---

**Happy botting! 🤖**