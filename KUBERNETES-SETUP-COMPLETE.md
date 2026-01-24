# ✅ Kubernetes Deployment Setup Complete!

Your Discord bots are now ready to be deployed to your k3s Kubernetes cluster!

## 🎉 What's Been Set Up

### ✅ Dockerfiles Created
All 18 bots now have Dockerfiles:

**Go Bots (3)**
- ✅ AndyBot/Dockerfile
- ✅ PirateBot/Dockerfile  
- ✅ WSB/Dockerfile

**C# Bots (5)**
- ✅ BrainCellBot/Dockerfile
- ✅ DickJohnson/Dockerfile
- ✅ HouseMog/Dockerfile (NEW)
- ✅ MangaNotifier/Dockerfile
- ✅ MovieNightBot/Dockerfile (NEW)

**Node.js Bots (8)**
- ✅ OwOBot/Dockerfile (NEW)
- ✅ OyVeyBot/Dockerfile
- ✅ RedditSimBot/Dockerfile (NEW)
- ✅ TarotBot/Dockerfile (NEW)
- ✅ UwUBot/Dockerfile
- ✅ JailBot/Dockerfile (NEW)
- ✅ JonTronBot/Dockerfile (NEW)
- ✅ TerryDavisBot/Dockerfile (NEW)

**Python Bots (2)**
- ✅ ScribeBot/Dockerfile
- ✅ PurpleHaroBot/Dockerfile (NEW)

### ✅ Kubernetes Infrastructure

**Created Files:**
```
kubernetes/
├── README.md                      # Comprehensive deployment guide
├── namespace.yaml                 # discord-bots namespace
├── deploy-all.sh                  # Deploy all bots at once
├── generate-deployments.sh        # Generate deployment YAMLs
├── bot-manager.sh                 # Helper script for managing bots
├── deployments/                   # (will contain generated YAML files)
│   └── andybot.yaml              # Example deployment
└── secrets/
    └── README.md                  # Secret management guide
```

**Root Directory Scripts:**
```
build-all.sh                       # Build all Docker images
DEPLOYMENT-QUICKSTART.md           # Quick reference guide
KUBERNETES-SETUP-COMPLETE.md       # This file
```

## 🚀 Quick Start Guide

### Step 1: Prerequisites

Make sure you have:
- ✅ k3s installed and running
- ✅ kubectl configured
- ✅ Docker installed and running
- ✅ Local Docker registry on port 5000

**Set up local registry:**
```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

**Configure kubectl for k3s:**
```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
kubectl get nodes  # Verify connection
```

### Step 2: Build All Images

From the Discord-Bots directory:

```bash
chmod +x build-all.sh
./build-all.sh
```

This will build and push all 18 bot images to `localhost:5000`.

### Step 3: Deploy to k3s

```bash
cd kubernetes
chmod +x deploy-all.sh generate-deployments.sh bot-manager.sh
./deploy-all.sh
```

This will:
1. Create the `discord-bots` namespace
2. Create secrets from your auth files
3. Generate deployment manifests
4. Deploy all bots

### Step 4: Verify Deployment

```bash
# Check if pods are running
kubectl get pods -n discord-bots

# Watch pods come online
kubectl get pods -n discord-bots -w

# View logs for a specific bot
kubectl logs -n discord-bots -l app=andybot -f
```

## 📋 Essential Commands

### Using the Bot Manager (Recommended)

```bash
cd kubernetes

# View help
./bot-manager.sh help

# Check bot status
./bot-manager.sh status andybot

# View logs
./bot-manager.sh logs andybot -f

# Restart a bot
./bot-manager.sh restart andybot

# Rebuild and redeploy
./bot-manager.sh rebuild andybot

# List all deployed bots
./bot-manager.sh list
```

### Using kubectl Directly

```bash
# View all bots
kubectl get pods -n discord-bots

# View logs
kubectl logs -n discord-bots -l app=andybot

# Restart a bot
kubectl rollout restart deployment/andybot -n discord-bots

# Delete everything
kubectl delete namespace discord-bots
```

## 🗂️ Project Structure

```
Discord-Bots/
│
├── build-all.sh                    # Build all Docker images
├── DEPLOYMENT-QUICKSTART.md        # Quick reference
├── KUBERNETES-SETUP-COMPLETE.md    # This file
│
├── kubernetes/
│   ├── README.md                   # Full documentation (READ THIS!)
│   ├── namespace.yaml              # Namespace definition
│   ├── deploy-all.sh               # Deploy all bots
│   ├── generate-deployments.sh     # Generate YAML files
│   ├── bot-manager.sh              # Bot management helper
│   │
│   ├── deployments/                # Generated deployment files
│   │   ├── andybot.yaml
│   │   ├── piratebot.yaml
│   │   ├── wsb.yaml
│   │   ├── braincellbot.yaml
│   │   ├── dickjohnson.yaml
│   │   ├── housemog.yaml
│   │   ├── manganotifier.yaml
│   │   ├── movienightbot.yaml
│   │   ├── owobot.yaml
│   │   ├── oyveybot.yaml
│   │   ├── redditsimbot.yaml
│   │   ├── tarotbot.yaml
│   │   ├── uwubot.yaml
│   │   ├── jailbot.yaml
│   │   ├── jontronbot.yaml
│   │   ├── terrydavisbot.yaml
│   │   ├── scribebot.yaml
│   │   └── purpleharobot.yaml
│   │
│   └── secrets/
│       └── README.md               # Secret management guide
│
├── AndyBot/
│   ├── Dockerfile                  # ✅ Ready
│   ├── auth.json                   # Your bot token
│   └── ...
│
├── [Other Bots]/
│   ├── Dockerfile                  # ✅ All ready
│   ├── auth.json or auth.txt       # Your bot tokens
│   └── ...
│
└── ...
```

## 🎯 Your Bots

| Bot Name        | Language | Image Name                           | Auth File  |
|----------------|----------|--------------------------------------|------------|
| AndyBot        | Go       | localhost:5000/andybot:latest        | auth.json  |
| PirateBot      | Go       | localhost:5000/piratebot:latest      | auth.json  |
| WSB            | Go       | localhost:5000/wsb:latest            | auth.json  |
| BrainCellBot   | C#       | localhost:5000/braincellbot:latest   | auth.txt   |
| DickJohnson    | C#       | localhost:5000/dickjohnson:latest    | auth.txt   |
| HouseMog       | C#       | localhost:5000/housemog:latest       | auth.txt   |
| MangaNotifier  | C#       | localhost:5000/manganotifier:latest  | auth.txt   |
| MovieNightBot  | C#       | localhost:5000/movienightbot:latest  | auth.txt   |
| OwOBot         | Node.js  | localhost:5000/owobot:latest         | auth.json  |
| OyVeyBot       | Node.js  | localhost:5000/oyveybot:latest       | auth.json  |
| RedditSimBot   | Node.js  | localhost:5000/redditsimbot:latest   | auth.json  |
| TarotBot       | Node.js  | localhost:5000/tarotbot:latest       | auth.json  |
| UwUBot         | Node.js  | localhost:5000/uwubot:latest         | auth.json  |
| JailBot        | Node.js  | localhost:5000/jailbot:latest        | auth.json  |
| JonTronBot     | Node.js  | localhost:5000/jontronbot:latest     | auth.json  |
| TerryDavisBot  | Node.js  | localhost:5000/terrydavisbot:latest  | auth.json  |
| ScribeBot      | Python   | localhost:5000/scribebot:latest      | auth.txt   |
| PurpleHaroBot  | Python   | localhost:5000/purpleharobot:latest  | auth.txt   |

**Total: 18 Discord Bots** 🤖

## 💡 Common Workflows

### Deploy Everything

```bash
# First time setup
./build-all.sh
cd kubernetes && ./deploy-all.sh

# Verify
kubectl get pods -n discord-bots
```

### Update a Single Bot

```bash
# Make your code changes, then:
cd kubernetes
./bot-manager.sh rebuild andybot
```

### View Bot Logs

```bash
cd kubernetes
./bot-manager.sh logs andybot -f
```

### Restart a Bot

```bash
cd kubernetes
./bot-manager.sh restart andybot
```

### Troubleshoot Issues

```bash
# Check pod status
kubectl get pods -n discord-bots

# View detailed pod info
kubectl describe pod <pod-name> -n discord-bots

# Check logs
kubectl logs -n discord-bots -l app=andybot

# View recent events
kubectl get events -n discord-bots --sort-by='.lastTimestamp'
```

## 🐛 Common Issues & Solutions

### ImagePullBackOff
**Problem:** Kubernetes can't pull the Docker image

**Solution:**
```bash
# Rebuild and push the image
cd AndyBot
docker build -t localhost:5000/andybot:latest .
docker push localhost:5000/andybot:latest

# Delete pod to force new pull
kubectl delete pod -n discord-bots -l app=andybot
```

### CrashLoopBackOff
**Problem:** Container keeps crashing

**Solution:**
```bash
# Check logs for errors
kubectl logs -n discord-bots -l app=andybot

# Verify secret exists
kubectl get secret andybot-secret -n discord-bots

# Recreate secret if needed
kubectl delete secret andybot-secret -n discord-bots
kubectl create secret generic andybot-secret \
  --from-file=auth.json=AndyBot/auth.json \
  --namespace=discord-bots
```

### Insufficient Resources
**Problem:** Not enough CPU/memory

**Solution:**
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n discord-bots

# Scale down or reduce resource limits
kubectl scale deployment andybot -n discord-bots --replicas=0
```

## 📚 Documentation Reference

1. **DEPLOYMENT-QUICKSTART.md** - Quick reference cheat sheet
2. **kubernetes/README.md** - Comprehensive deployment guide
3. **kubernetes/secrets/README.md** - Secret management guide

## 🔒 Security Notes

- ✅ All containers run as non-root users
- ✅ Auth files are stored as Kubernetes secrets
- ✅ Auth files are already in .gitignore
- ⚠️ Never commit actual auth.json or auth.txt files to git
- ⚠️ Secrets in Kubernetes are base64 encoded, not encrypted
- 💡 For production, consider using external secret managers

## 📊 Resource Requirements

**Per Bot Type:**
- **Go:** 64Mi-128Mi RAM, 50m-200m CPU
- **C#:** 128Mi-256Mi RAM, 100m-500m CPU
- **Node.js:** 128Mi-256Mi RAM, 50m-300m CPU
- **Python:** 128Mi-256Mi RAM, 50m-300m CPU

**Total for All 18 Bots:**
- ~3-4 GB RAM
- ~5-6 CPU cores (under load)

## 🎓 Learning Resources

- k3s Documentation: https://docs.k3s.io/
- Kubernetes Docs: https://kubernetes.io/docs/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Docker Best Practices: https://docs.docker.com/develop/dev-best-practices/

## ✨ Next Steps

1. ✅ **You're here!** - Setup complete
2. 🚀 Run `./build-all.sh` to build all images
3. 🚀 Run `cd kubernetes && ./deploy-all.sh` to deploy
4. 📊 Set up monitoring (metrics-server)
5. 🔄 Configure CI/CD for automated deployments
6. 🏥 Add health checks to your bots
7. 💾 Set up persistent storage if needed
8. 🔐 Implement external secret management

## 🎉 Ready to Deploy!

Everything is set up and ready to go. Just run:

```bash
# From Discord-Bots directory
./build-all.sh
cd kubernetes
./deploy-all.sh
```

Then watch your bots come online:

```bash
kubectl get pods -n discord-bots -w
```

---

**Need help?** Check the comprehensive guide: `kubernetes/README.md`

**Happy Botting! 🤖🚀**