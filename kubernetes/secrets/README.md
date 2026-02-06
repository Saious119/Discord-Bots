# Discord Bot Secrets Configuration

This directory contains instructions for managing Discord bot tokens and configuration as Kubernetes secrets.

## Important Security Notice

⚠️ **NEVER commit actual secrets to git!** This directory should only contain templates and documentation.

## Creating Secrets

### Method 1: From Existing auth.json/auth.txt Files

Each bot has its own authentication file. You can create secrets from these files:

```bash
# For bots with auth.json files (Node.js bots)
kubectl create secret generic owobot-secret \
  --from-file=auth.json=../OwOBot/auth.json \
  --namespace=discord-bots

# For bots with auth.txt files (Go and C# bots)
kubectl create secret generic andybot-secret \
  --from-file=auth.txt=../AndyBot/auth.txt \
  --namespace=discord-bots

# For bots with auth.txt files
kubectl create secret generic purpleharobot-secret \
  --from-file=auth.txt=../PurpleHaroBot/auth.txt \
  --namespace=discord-bots
```

### Method 2: Using kubectl create secret

```bash
# Create a secret with a bot token
kubectl create secret generic mybot-secret \
  --from-literal=token=YOUR_DISCORD_BOT_TOKEN_HERE \
  --namespace=discord-bots
```

### Method 3: Using YAML Files (Not Recommended for Production)

Create a file like `mybot-secret.yaml` (DO NOT COMMIT THIS):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mybot-secret
  namespace: discord-bots
type: Opaque
stringData:
  token: "YOUR_DISCORD_BOT_TOKEN_HERE"
  # or for auth.json format:
  auth.json: |
    {
      "token": "YOUR_DISCORD_BOT_TOKEN_HERE",
      "clientId": "YOUR_CLIENT_ID"
    }
```

Then apply it:
```bash
kubectl apply -f mybot-secret.yaml
```

## Required Secrets for Each Bot

Create these secrets before deploying the bots:

### Go Bots
- `andybot-secret` - needs `auth.txt`
- `piratebot-secret` - needs `auth.txt`
- `wsb-secret` - needs `auth.txt`

### C# Bots
- `braincellbot-secret` - needs `auth.txt`
- `dickjohnson-secret` - needs `auth.txt`
- `housemog-secret` - needs `auth.txt`
- `manganotifier-secret` - needs `auth.txt`
- `movienightbot-secret` - needs `auth.txt`

### Node.js Bots
- `owobot-secret` - needs `auth.json`
- `oyveybot-secret` - needs `auth.json`
- `redditsimbot-secret` - needs `auth.json`
- `tarotbot-secret` - needs `auth.json`
- `uwubot-secret` - needs `auth.json`
- `jailbot-secret` - needs `auth.json`
- `jontronbot-secret` - needs `auth.json`
- `terrydavisbot-secret` - needs `auth.json`

### Python Bots
- `scribebot-secret` - needs auth configuration
- `purpleharobot-secret` - needs `auth.txt`

## Bulk Secret Creation Script

Here's a script to create all secrets at once:

```bash
#!/bin/bash

# Navigate to the Discord-Bots directory
cd "$(dirname "$0")/../.."

# Create namespace first
kubectl apply -f kubernetes/namespace.yaml

# Go Bots
kubectl create secret generic andybot-secret \
  --from-file=auth.txt=AndyBot/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic piratebot-secret \
  --from-file=auth.txt=PirateBot/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic wsb-secret \
  --from-file=auth.txt=WSB/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

# C# Bots
kubectl create secret generic braincellbot-secret \
  --from-file=auth.txt=BrainCellBot/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic dickjohnson-secret \
  --from-file=auth.txt=DickJohnson/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic housemog-secret \
  --from-file=auth.txt=HouseMog/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic manganotifier-secret \
  --from-file=auth.txt=MangaNotifier/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic movienightbot-secret \
  --from-file=auth.txt=MovieNightBot/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

# Node.js Bots
kubectl create secret generic owobot-secret \
  --from-file=auth.json=OwOBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic oyveybot-secret \
  --from-file=auth.json=OyVeyBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic redditsimbot-secret \
  --from-file=auth.json=RedditSimBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic tarotbot-secret \
  --from-file=auth.json=TarotBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic uwubot-secret \
  --from-file=auth.json=UwUBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic jailbot-secret \
  --from-file=auth.json=JailBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic jontronbot-secret \
  --from-file=auth.json=JonTronBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic terrydavisbot-secret \
  --from-file=auth.json=TerryDavisBot/auth.json \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

# Python Bots
kubectl create secret generic scribebot-secret \
  --from-file=auth.txt=ScribeBot/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic purpleharobot-secret \
  --from-file=auth.txt=PurpleHaroBot/auth.txt \
  --namespace=discord-bots --dry-run=client -o yaml | kubectl apply -f -

echo "All secrets created successfully!"
```

Save this as `create-secrets.sh` and run it from the kubernetes/secrets directory.

## Verifying Secrets

```bash
# List all secrets
kubectl get secrets -n discord-bots

# View a specific secret (base64 encoded)
kubectl get secret andybot-secret -n discord-bots -o yaml

# Decode a secret value
kubectl get secret andybot-secret -n discord-bots -o jsonpath='{.data.auth\.json}' | base64 -d
```

## Updating Secrets

```bash
# Delete and recreate
kubectl delete secret mybot-secret -n discord-bots
kubectl create secret generic mybot-secret --from-file=auth.json=../MyBot/auth.json -n discord-bots

# Or patch an existing secret
kubectl patch secret mybot-secret -n discord-bots \
  --type='json' -p='[{"op": "replace", "path": "/data/token", "value":"'$(echo -n "NEW_TOKEN" | base64)'"}]'
```

## Best Practices

1. **Use External Secret Management**: For production, consider using:
   - [External Secrets Operator](https://external-secrets.io/)
   - [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
   - Cloud provider secret managers (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)

2. **Never Commit Secrets**: Add this directory to `.gitignore` if you create actual secret files

3. **Use RBAC**: Restrict access to secrets in your cluster

4. **Rotate Regularly**: Update bot tokens periodically

5. **Audit Access**: Monitor who accesses secrets in your cluster