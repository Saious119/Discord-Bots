# 📋 Kubernetes Deployment Checklist

Use this checklist to deploy your Discord bots to k3s for the first time.

## ✅ Pre-Deployment Checklist

### System Requirements

- [ ] **k3s installed and running**
  ```bash
  # Check if k3s is running
  sudo systemctl status k3s
  # OR
  kubectl get nodes
  ```

- [ ] **kubectl configured**
  ```bash
  # Set up kubectl config
  mkdir -p ~/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sudo chown $USER:$USER ~/.kube/config
  chmod 600 ~/.kube/config
  
  # Verify
  kubectl cluster-info
  kubectl get nodes
  ```

- [ ] **Docker installed and running**
  ```bash
  # Check Docker status
  docker --version
  docker info
  ```

- [ ] **Local Docker registry running on port 5000**
  ```bash
  # Start local registry
  docker run -d -p 5000:5000 --restart=always --name registry registry:2
  
  # Verify it's running
  curl http://localhost:5000/v2/_catalog
  ```

- [ ] **k3s configured to use local registry** (if needed)
  ```bash
  # Create registries.yaml
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
  
  # Restart k3s
  sudo systemctl restart k3s
  ```

### Bot Configuration

- [ ] **All bot auth files present**
  - [ ] AndyBot/auth.txt
  - [ ] PirateBot/auth.txt
  - [ ] WSB/auth.txt
  - [ ] BrainCellBot/auth.txt
  - [ ] DickJohnson/auth.txt
  - [ ] HouseMog/auth.txt
  - [ ] MangaNotifier/auth.txt
  - [ ] MovieNightBot/auth.txt
  - [ ] OwOBot/auth.json
  - [ ] OyVeyBot/auth.json
  - [ ] RedditSimBot/auth.json
  - [ ] TarotBot/auth.json
  - [ ] UwUBot/auth.json
  - [ ] JailBot/auth.json
  - [ ] JonTronBot/auth.json
  - [ ] TerryDavisBot/auth.json
  - [ ] ScribeBot/auth.txt
  - [ ] PurpleHaroBot/auth.txt

- [ ] **All Dockerfiles present** (✅ All created!)
  - [ ] All 18 bots now have Dockerfiles

### Scripts Ready

- [ ] **Make scripts executable**
  ```bash
  # From Discord-Bots directory
  chmod +x build-all.sh
  chmod +x kubernetes/deploy-all.sh
  chmod +x kubernetes/generate-deployments.sh
  chmod +x kubernetes/bot-manager.sh
  ```

## 🚀 Deployment Steps

### Step 1: Build Docker Images

- [ ] **Build all bot images**
  ```bash
  # Linux/Mac
  ./build-all.sh
  
  # Windows
  .\build-all.ps1
  ```

- [ ] **Verify images are built**
  ```bash
  # Check local images
  docker images | grep localhost:5000
  
  # Should see 18 images like:
  # localhost:5000/andybot:latest
  # localhost:5000/piratebot:latest
  # etc.
  ```

- [ ] **Verify images are in registry**
  ```bash
  # List images in registry
  curl http://localhost:5000/v2/_catalog
  
  # Check specific image tags
  curl http://localhost:5000/v2/andybot/tags/list
  ```

### Step 2: Deploy to Kubernetes

- [ ] **Generate deployment manifests**
  ```bash
  cd kubernetes
  ./generate-deployments.sh
  ```

- [ ] **Verify YAML files created**
  ```bash
  ls -la deployments/
  # Should see 18 .yaml files
  ```

- [ ] **Deploy all bots**
  ```bash
  ./deploy-all.sh
  ```

- [ ] **Watch deployment progress**
  ```bash
  # In another terminal
  kubectl get pods -n discord-bots -w
  ```

### Step 3: Verify Deployment

- [ ] **Check namespace created**
  ```bash
  kubectl get namespace discord-bots
  ```

- [ ] **Check all secrets created**
  ```bash
  kubectl get secrets -n discord-bots
  # Should see 18 secrets (one per bot)
  ```

- [ ] **Check all deployments created**
  ```bash
  kubectl get deployments -n discord-bots
  # Should see 18 deployments
  ```

- [ ] **Check pod status**
  ```bash
  kubectl get pods -n discord-bots
  # All pods should eventually show "Running" status
  ```

- [ ] **Verify no errors**
  ```bash
  # Check for failed pods
  kubectl get pods -n discord-bots --field-selector=status.phase!=Running
  
  # Should return empty (no results)
  ```

## 🧪 Testing & Verification

### Test Individual Bots

For each bot you want to test:

- [ ] **Check bot logs**
  ```bash
  cd kubernetes
  ./bot-manager.sh logs andybot
  ```

- [ ] **Verify bot connected to Discord**
  - [ ] Check Discord server - bot should appear online
  - [ ] Test a bot command
  - [ ] Verify bot responds correctly

- [ ] **Check resource usage**
  ```bash
  kubectl top pods -n discord-bots
  ```

### Troubleshoot Failed Pods

If any pods are not running:

- [ ] **Check pod status**
  ```bash
  kubectl get pods -n discord-bots
  ```

- [ ] **For ImagePullBackOff errors:**
  ```bash
  # Rebuild and push the image
  cd <BotDirectory>
  docker build -t localhost:5000/<botname>:latest .
  docker push localhost:5000/<botname>:latest
  
  # Delete pod to force new pull
  kubectl delete pod -n discord-bots -l app=<botname>
  ```

- [ ] **For CrashLoopBackOff errors:**
  ```bash
  # Check logs
  kubectl logs -n discord-bots -l app=<botname>
  
  # Verify secret exists and is correct
  kubectl get secret <botname>-secret -n discord-bots
  kubectl get secret <botname>-secret -n discord-bots -o yaml
  
  # Recreate secret if needed
  kubectl delete secret <botname>-secret -n discord-bots
  kubectl create secret generic <botname>-secret \
    --from-file=auth.json=<BotDir>/auth.json \
    --namespace=discord-bots
  ```

- [ ] **Check recent events**
  ```bash
  kubectl get events -n discord-bots --sort-by='.lastTimestamp'
  ```

## 📊 Post-Deployment Tasks

### Monitoring Setup

- [ ] **Install metrics-server** (if not already installed)
  ```bash
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  ```

- [ ] **Test resource monitoring**
  ```bash
  kubectl top nodes
  kubectl top pods -n discord-bots
  ```

- [ ] **Set up log aggregation** (optional)
  - Consider tools like Loki, ELK stack, or similar

### Documentation

- [ ] **Document any custom configurations**
- [ ] **Note which bots are running**
- [ ] **Record any special requirements or dependencies**

### Backup

- [ ] **Backup deployment files**
  ```bash
  kubectl get deployments -n discord-bots -o yaml > backup-deployments.yaml
  ```

- [ ] **Backup secrets** (store securely!)
  ```bash
  kubectl get secrets -n discord-bots -o yaml > backup-secrets.yaml
  # Store this file securely and DO NOT commit to git!
  ```

- [ ] **Backup namespace configuration**
  ```bash
  kubectl get namespace discord-bots -o yaml > backup-namespace.yaml
  ```

## 🎯 Success Criteria

Your deployment is successful when:

- [ ] All 18 deployments are created
- [ ] All 18 pods show "Running" status
- [ ] No pods are in CrashLoopBackOff or ImagePullBackOff state
- [ ] All bots appear online in Discord
- [ ] Bots respond to test commands
- [ ] Resource usage is within acceptable limits
- [ ] No error messages in pod logs

## 📝 Notes

### Common Pod Statuses

- **Running** ✅ - Bot is working correctly
- **Pending** ⏳ - Waiting for resources or pulling image
- **ContainerCreating** ⏳ - Container is being created
- **ImagePullBackOff** ❌ - Can't pull Docker image
- **CrashLoopBackOff** ❌ - Container keeps crashing
- **Error** ❌ - Container failed to start

### Resource Requirements

Total for all 18 bots:
- **Memory:** ~3-4 GB
- **CPU:** ~5-6 cores (under load)

Make sure your k3s cluster has sufficient resources!

## 🆘 Getting Help

If you encounter issues:

1. **Check the documentation:**
   - `kubernetes/README.md` - Full deployment guide
   - `DEPLOYMENT-QUICKSTART.md` - Quick reference
   - `kubernetes/secrets/README.md` - Secret management

2. **Common commands for debugging:**
   ```bash
   kubectl get pods -n discord-bots
   kubectl logs -n discord-bots -l app=<botname>
   kubectl describe pod <pod-name> -n discord-bots
   kubectl get events -n discord-bots
   ```

3. **Use the bot manager:**
   ```bash
   cd kubernetes
   ./bot-manager.sh help
   ./bot-manager.sh status <botname>
   ./bot-manager.sh logs <botname> -f
   ```

## ✅ Final Verification

- [ ] All bots deployed successfully
- [ ] All bots online in Discord
- [ ] Resource usage acceptable
- [ ] Logs show no errors
- [ ] Backups created
- [ ] Documentation updated

---

**Congratulations! Your Discord bots are now running on Kubernetes! 🎉**

Use `./bot-manager.sh` for ongoing management and `kubectl` for cluster operations.