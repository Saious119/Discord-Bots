# Discord Bots Kubernetes Deployment - Quick Start

A quick reference guide for deploying your Discord bots to k3s.

## 🚀 5-Minute Quick Start

```bash
# 1. Build all Docker images
chmod +x build-all.sh
./build-all.sh

# 2. Deploy everything to k3s
cd kubernetes
chmod +x deploy-all.sh
./deploy-all.sh

# 3. Check status
kubectl get pods -n discord-bots
```

## 📋 Prerequisites Checklist

- [ ] k3s installed and running
- [ ] kubectl configured (`~/.kube/config`)
- [ ] Docker installed and running
- [ ] Local Docker registry running on port 5000

### Quick Setup

```bash
# Start local Docker registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Configure kubectl for k3s
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Verify
kubectl get nodes
```

## 🤖 Your Bots

**Total: 18 Discord Bots**

| Language | Count | Bots |
|----------|-------|------|
| Go       | 3     | AndyBot, PirateBot, WSB |
| C#       | 5     | BrainCellBot, DickJohnson, HouseMog, MangaNotifier, MovieNightBot |
| Node.js  | 8     | OwOBot, OyVeyBot, RedditSimBot, TarotBot, UwUBot, JailBot, JonTronBot, TerryDavisBot |
| Python   | 2     | ScribeBot, PurpleHaroBot |

## 📝 Common Commands

### Deployment Commands

```bash
# Deploy all bots
cd kubernetes && ./deploy-all.sh

# Deploy a single bot
kubectl apply -f kubernetes/deployments/andybot.yaml

# Generate deployment manifests
cd kubernetes && ./generate-deployments.sh
```

### Monitoring Commands

```bash
# View all bots
kubectl get pods -n discord-bots

# Watch pods in real-time
kubectl get pods -n discord-bots -w

# View logs for a bot
kubectl logs -n discord-bots -l app=andybot

# Follow logs in real-time
kubectl logs -n discord-bots -l app=andybot -f

# View all deployments
kubectl get deployments -n discord-bots
```

### Management Commands

```bash
# Restart a bot
kubectl rollout restart deployment/andybot -n discord-bots

# Restart all bots
kubectl rollout restart deployment -n discord-bots

# Delete a bot
kubectl delete deployment andybot -n discord-bots

# Delete everything
kubectl delete namespace discord-bots
```

### Resource Monitoring

```bash
# Check resource usage
kubectl top pods -n discord-bots
kubectl top nodes

# Describe a pod
kubectl describe pod <pod-name> -n discord-bots
```

## 🛠️ Bot Manager Helper

Use the bot manager script for easier management:

```bash
cd kubernetes
chmod +x bot-manager.sh

# View help
./bot-manager.sh help

# Common operations
./bot-manager.sh status andybot       # Check status
./bot-manager.sh logs andybot         # View logs
./bot-manager.sh logs andybot -f      # Follow logs
./bot-manager.sh restart andybot      # Restart bot
./bot-manager.sh rebuild andybot      # Rebuild & redeploy
./bot-manager.sh shell andybot        # Open shell in container
./bot-manager.sh list                 # List deployed bots
./bot-manager.sh list-all             # List all available bots
```

## 🔧 Updating a Bot

After making code changes:

```bash
# Option 1: Use bot-manager
cd kubernetes
./bot-manager.sh rebuild andybot

# Option 2: Manual
cd AndyBot
docker build -t localhost:5000/andybot:latest .
docker push localhost:5000/andybot:latest
kubectl rollout restart deployment/andybot -n discord-bots
```

## 🐛 Troubleshooting Quick Fixes

### Bot won't start (ImagePullBackOff)

```bash
# Rebuild and push image
cd AndyBot
docker build -t localhost:5000/andybot:latest .
docker push localhost:5000/andybot:latest

# Delete pod to force new pull
kubectl delete pod -n discord-bots -l app=andybot
```

### Bot crashes (CrashLoopBackOff)

```bash
# Check logs for errors
kubectl logs -n discord-bots -l app=andybot

# Check if secret exists
kubectl get secret andybot-secret -n discord-bots

# Recreate secret
kubectl delete secret andybot-secret -n discord-bots
kubectl create secret generic andybot-secret \
  --from-file=auth.json=AndyBot/auth.json \
  --namespace=discord-bots
```

### Check if auth file is mounted

```bash
# Get pod name
POD=$(kubectl get pods -n discord-bots -l app=andybot -o jsonpath='{.items[0].metadata.name}')

# Check file
kubectl exec -it $POD -n discord-bots -- cat /app/auth.json
```

### View pod events

```bash
kubectl get events -n discord-bots --sort-by='.lastTimestamp'
kubectl describe pod <pod-name> -n discord-bots
```

## 📦 File Structure

```
Discord-Bots/
├── build-all.sh                    # Build all Docker images
├── kubernetes/
│   ├── README.md                   # Full documentation
│   ├── namespace.yaml              # Namespace definition
│   ├── deploy-all.sh               # Deploy all bots
│   ├── generate-deployments.sh     # Generate YAML files
│   ├── bot-manager.sh              # Bot management helper
│   ├── deployments/                # Generated deployment files
│   │   ├── andybot.yaml
│   │   ├── piratebot.yaml
│   │   └── ...
│   └── secrets/
│       └── README.md               # Secret management guide
└── [BotName]/
    ├── Dockerfile                  # Container definition
    └── auth.json / auth.txt        # Bot credentials
```

## 🔐 Managing Secrets

### Create secrets from auth files

```bash
# For bots with auth.json (Node.js bots)
kubectl create secret generic owobot-secret \
  --from-file=auth.json=OwOBot/auth.json \
  --namespace=discord-bots

# For bots with auth.txt (Go, C#, and Python bots)
kubectl create secret generic andybot-secret \
  --from-file=auth.txt=AndyBot/auth.txt \
  --namespace=discord-bots

kubectl create secret generic housemog-secret \
  --from-file=auth.txt=HouseMog/auth.txt \
  --namespace=discord-bots
```

### View secrets

```bash
# List all secrets
kubectl get secrets -n discord-bots

# View secret details
kubectl describe secret andybot-secret -n discord-bots

# Decode secret content
kubectl get secret andybot-secret -n discord-bots -o jsonpath='{.data.auth\.json}' | base64 -d
```

## 💾 Resource Requirements

**Per Bot:**
- Go: 64Mi-128Mi RAM, 50m-200m CPU
- C#: 128Mi-256Mi RAM, 100m-500m CPU
- Node.js: 128Mi-256Mi RAM, 50m-300m CPU
- Python: 128Mi-256Mi RAM, 50m-300m CPU

**Total (all 18 bots):**
- ~3-4 GB RAM
- ~5-6 CPU cores (under load)

## 📊 Useful One-Liners

```bash
# Count running bots
kubectl get pods -n discord-bots --field-selector=status.phase=Running --no-headers | wc -l

# Find pods that aren't running
kubectl get pods -n discord-bots --field-selector=status.phase!=Running

# Delete all failed pods
kubectl delete pods -n discord-bots --field-selector=status.phase=Failed

# Restart all bots at once
kubectl rollout restart deployment -n discord-bots

# Export all deployments
kubectl get deployments -n discord-bots -o yaml > backup-deployments.yaml

# Export all secrets
kubectl get secrets -n discord-bots -o yaml > backup-secrets.yaml
```

## 🎯 Next Steps

1. **Read the full guide**: `kubernetes/README.md`
2. **Set up monitoring**: Install metrics-server
3. **Configure persistence**: For bots that need data storage
4. **Set up CI/CD**: Automate builds and deployments
5. **Add health checks**: Implement liveness/readiness probes

## 📚 Additional Resources

- Full Documentation: `kubernetes/README.md`
- Secret Management: `kubernetes/secrets/README.md`
- k3s Docs: https://docs.k3s.io/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

## ⚡ Pro Tips

1. Use `./bot-manager.sh` for easier bot management
2. Always check logs first when debugging: `kubectl logs -n discord-bots -l app=botname`
3. Set `imagePullPolicy: Always` to ensure latest images are pulled
4. Discord bots should run with 1 replica (not multiple)
5. Use `kubectl get events` to see what's happening in your cluster
6. Tag images with version numbers in production (not just `latest`)
7. Monitor resource usage regularly with `kubectl top pods -n discord-bots`
8. Keep auth files secure and never commit them to git

---

**Ready to deploy? Run `./build-all.sh` to get started! 🚀**