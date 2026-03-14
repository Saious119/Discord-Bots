# Vault Secrets Operator (VSO) Integration for Discord Bots

This directory contains all the YAML manifests and scripts needed to integrate HashiCorp Vault with your K3s cluster using the **Vault Secrets Operator (VSO)**. Once configured, Vault becomes the single source of truth for all Discord bot tokens and credentials — secrets are automatically synced into native Kubernetes Secrets that your existing deployments already reference.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [Step 1: Install Vault Secrets Operator](#step-1-install-vault-secrets-operator)
  - [Step 2: Configure Vault Server](#step-2-configure-vault-server)
  - [Step 3: Deploy VSO Resources to K3s](#step-3-deploy-vso-resources-to-k3s)
  - [Step 4: Verify Everything Works](#step-4-verify-everything-works)
- [File Reference](#file-reference)
- [How It Works](#how-it-works)
- [Vault Secret Structure](#vault-secret-structure)
- [Managing Secrets](#managing-secrets)
  - [Adding a New Bot](#adding-a-new-bot)
  - [Rotating a Token](#rotating-a-token)
  - [Viewing Synced Secrets](#viewing-synced-secrets)
- [Troubleshooting](#troubleshooting)
- [Migrating from Manual Secrets](#migrating-from-manual-secrets)
- [Security Considerations](#security-considerations)
- [Uninstalling](#uninstalling)

---

## Overview

Previously, bot secrets were created manually with `kubectl create secret` from local `auth.txt` and `auth.json` files. This setup replaces that workflow with HashiCorp Vault:

| Before (Manual)                                  | After (Vault + VSO)                                 |
| ------------------------------------------------ | --------------------------------------------------- |
| Secrets stored as local files on disk             | Secrets stored centrally in Vault                   |
| Created manually with `kubectl create secret`     | Automatically synced by VSO                         |
| No audit trail                                    | Full Vault audit logging                            |
| Token rotation requires manual `kubectl` commands | Update in Vault, auto-syncs within 60 seconds       |
| Secrets scattered across machines                 | Single source of truth                              |

**The best part:** your existing bot deployment YAMLs in `kubernetes/deployments/` require **zero changes**. VSO creates the exact same Kubernetes Secret names (`andybot-secret`, `owobot-secret`, etc.) that your deployments already reference.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    HashiCorp Vault                        │
│                                                          │
│  secret/discord-bots/andybot     → { token: "..." }     │
│  secret/discord-bots/owobot      → { token, clientId }  │
│  secret/discord-bots/piratebot   → { token: "..." }     │
│  ...18 bot secrets total...                              │
│                                                          │
│  Auth: Kubernetes (ServiceAccount → Role → Policy)       │
└──────────────┬───────────────────────────────────────────┘
               │  Kubernetes Auth
               │  (discord-bots-vault SA)
               ▼
┌──────────────────────────────────────────────────────────┐
│              Vault Secrets Operator (VSO)                 │
│              (vault-secrets-operator-system)              │
│                                                          │
│  Watches: VaultStaticSecret resources                    │
│  Action:  Reads from Vault → Creates K8s Secrets         │
│  Refresh: Every 60 seconds                               │
└──────────────┬───────────────────────────────────────────┘
               │  Creates / Updates
               ▼
┌──────────────────────────────────────────────────────────┐
│              Kubernetes Secrets (discord-bots ns)         │
│                                                          │
│  andybot-secret       → data: { auth.txt: "<token>" }   │
│  owobot-secret        → data: { auth.json: "{...}" }    │
│  piratebot-secret     → data: { auth.txt: "<token>" }   │
│  ...                                                     │
└──────────────┬───────────────────────────────────────────┘
               │  Volume Mounts (unchanged)
               ▼
┌──────────────────────────────────────────────────────────┐
│              Bot Deployments (discord-bots ns)            │
│                                                          │
│  andybot    → mounts andybot-secret as /app/auth.txt    │
│  owobot     → mounts owobot-secret as /app/auth.json    │
│  piratebot  → mounts piratebot-secret as /app/auth.txt  │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **K3s cluster** running and `kubectl` configured
2. **HashiCorp Vault** instance running (in-cluster or externally accessible)
3. **Helm 3** installed (for VSO installation)
4. **vault CLI** installed (for server-side setup)
5. **Bot auth files** (`auth.txt` / `auth.json`) available locally for initial seeding

### Verify Prerequisites

```bash
# K3s / kubectl
kubectl cluster-info
kubectl get nodes

# Helm
helm version

# Vault CLI
vault version

# Vault connectivity
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="hvs.your-root-token"
vault status
```

## Quick Start

If you want to get up and running fast, here are the commands in order:

```bash
# 1. Install the Vault Secrets Operator via Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  -n vault-secrets-operator-system \
  --create-namespace

# 2. Configure Vault (seeds secrets, enables K8s auth, creates policy + role)
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="hvs.your-root-token"
cd kubernetes/vault
./vault-setup.sh

# 3. Deploy VSO resources to K3s (connection, auth, secret syncing)
./deploy-vault.sh

# 4. Deploy your bots (no changes needed!)
kubectl apply -f ../deployments/
```

That's it! Your bots will automatically get their secrets from Vault.

## Detailed Setup

### Step 1: Install Vault Secrets Operator

The VSO is a Kubernetes operator from HashiCorp that watches for `VaultStaticSecret` (and other) custom resources, then syncs the referenced Vault secrets into native Kubernetes Secrets.

```bash
# Add the HashiCorp Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install VSO into its own namespace
helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  -n vault-secrets-operator-system \
  --create-namespace

# Verify the operator is running
kubectl get pods -n vault-secrets-operator-system
```

You should see the operator pod in a `Running` state:

```
NAME                                        READY   STATUS    RESTARTS   AGE
vault-secrets-operator-xxxxxxxxxx-xxxxx     1/1     Running   0          30s
```

### Step 2: Configure Vault Server

The `vault-setup.sh` script handles all Vault server-side configuration:

1. **Enables the KV-v2 secrets engine** at `secret/`
2. **Seeds all bot tokens** from your local `auth.txt` and `auth.json` files into Vault
3. **Enables Kubernetes auth** so VSO can authenticate using a ServiceAccount
4. **Creates a policy** (`discord-bots-read`) granting read access to `secret/data/discord-bots/*`
5. **Creates a role** (`discord-bots`) binding the `discord-bots-vault` ServiceAccount to the policy

```bash
# Set your Vault environment
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="hvs.your-root-token"

# Run the setup script (from the project root)
cd kubernetes/vault
chmod +x vault-setup.sh
./vault-setup.sh
```

The script is idempotent — you can run it multiple times safely. It will skip steps that are already configured and warn you about missing auth files.

> **Note:** If you don't have the bot auth files locally, you can manually seed secrets into Vault:
>
> ```bash
> # For bots using auth.txt (Go, C#, Python)
> vault kv put secret/discord-bots/andybot token="YOUR_DISCORD_BOT_TOKEN"
>
> # For bots using auth.json (Node.js)
> vault kv put secret/discord-bots/owobot token="YOUR_TOKEN" clientId="YOUR_CLIENT_ID"
> ```

### Step 3: Deploy VSO Resources to K3s

The `deploy-vault.sh` script applies all the Kubernetes manifests in the correct order:

```bash
chmod +x deploy-vault.sh

# Preview what will be applied (dry run)
./deploy-vault.sh --dry-run

# Apply everything
./deploy-vault.sh
```

This creates the following resources in the `discord-bots` namespace:

| Resource              | Name                      | Purpose                                                |
| --------------------- | ------------------------- | ------------------------------------------------------ |
| `ServiceAccount`      | `discord-bots-vault`      | Identity used by VSO to authenticate to Vault          |
| `VaultConnection`     | `vault-connection`        | Tells VSO where the Vault server is                    |
| `VaultAuth`           | `vault-auth`              | Configures Kubernetes auth method for VSO              |
| `VaultStaticSecret`   | `andybot-vault-secret`    | Syncs `secret/discord-bots/andybot` → `andybot-secret`|
| `VaultStaticSecret`   | `owobot-vault-secret`     | Syncs `secret/discord-bots/owobot` → `owobot-secret`  |
| ...                   | ...                       | One per bot (18 total)                                 |

### Step 4: Verify Everything Works

```bash
# Check that VaultStaticSecrets are syncing
kubectl get vaultstaticsecrets -n discord-bots

# Check that Kubernetes Secrets were created
kubectl get secrets -n discord-bots

# Inspect a specific synced secret
kubectl get secret andybot-secret -n discord-bots -o jsonpath='{.data.auth\.txt}' | base64 -d

# Check VSO operator logs for errors
kubectl logs -n vault-secrets-operator-system -l app.kubernetes.io/name=vault-secrets-operator --tail=50

# Now deploy your bots
kubectl apply -f ../deployments/
kubectl get pods -n discord-bots
```

## File Reference

| File                         | Description                                               |
| ---------------------------- | --------------------------------------------------------- |
| `vault-connection.yaml`      | `VaultConnection`, `VaultAuth`, and `ServiceAccount`      |
| `secrets-go-bots.yaml`       | `VaultStaticSecret` for Go bots (andybot, piratebot, wsb) |
| `secrets-csharp-bots.yaml`   | `VaultStaticSecret` for C# bots (5 bots)                 |
| `secrets-nodejs-bots.yaml`   | `VaultStaticSecret` for Node.js bots (8 bots)            |
| `secrets-python-bots.yaml`   | `VaultStaticSecret` for Python bots (scribebot, purpleharobot) |
| `vault-setup.sh`             | Vault server-side setup (secrets engine, auth, policy)    |
| `deploy-vault.sh`            | Applies all YAML manifests to K3s                         |
| `README.md`                  | This file                                                 |

## How It Works

### The Sync Loop

1. VSO watches for `VaultStaticSecret` custom resources in the cluster
2. When it finds one, it uses the referenced `VaultAuth` to authenticate to Vault
3. It reads the secret from the specified Vault path (e.g., `secret/discord-bots/andybot`)
4. It creates or updates a native Kubernetes `Secret` with the data
5. The `transformation.templates` section formats the data to match what the bot expects (e.g., building `auth.json` from individual fields)
6. Every `refreshAfter` interval (60 seconds), VSO re-reads from Vault and updates the K8s secret if anything changed

### Template Transformations

The `VaultStaticSecret` resources use templates to format Vault data into the file formats your bots expect:

**For `auth.txt` bots** (Go, C#, Python):

Vault stores: `{ "token": "abc123" }`

Template produces the K8s secret key `auth.txt` containing: `abc123`

```yaml
transformation:
  excludeRaw: true
  templates:
    auth.txt:
      text: "{{ .Secrets.token }}"
```

**For `auth.json` bots** (Node.js):

Vault stores: `{ "token": "abc123", "clientId": "456" }`

Template produces the K8s secret key `auth.json` containing valid JSON:

```yaml
transformation:
  excludeRaw: true
  templates:
    auth.json:
      text: |
        {
          "token": "{{ .Secrets.token }}",
          "clientId": "{{ .Secrets.clientId }}"
        }
```

The `excludeRaw: true` setting prevents VSO from also dumping the raw Vault key-value pairs as additional keys in the Kubernetes secret. Only the templated keys are included.

## Vault Secret Structure

All bot secrets are stored under the `secret/discord-bots/` path in Vault's KV-v2 engine:

```
secret/
└── discord-bots/
    ├── andybot          { "token": "..." }
    ├── piratebot         { "token": "..." }
    ├── wsb               { "token": "..." }
    ├── braincellbot      { "token": "..." }
    ├── dickjohnson        { "token": "..." }
    ├── housemog           { "token": "..." }
    ├── manganotifier      { "token": "..." }
    ├── movienightbot      { "token": "..." }
    ├── owobot            { "token": "...", "clientId": "..." }
    ├── oyveybot          { "token": "...", "clientId": "..." }
    ├── redditsimbot      { "token": "...", "clientId": "..." }
    ├── tarotbot          { "token": "...", "clientId": "..." }
    ├── uwubot            { "token": "...", "clientId": "..." }
    ├── jailbot           { "token": "...", "clientId": "..." }
    ├── jontronbot        { "token": "...", "clientId": "..." }
    ├── terrydavisbot     { "token": "...", "clientId": "..." }
    ├── scribebot          { "token": "..." }
    └── purpleharobot      { "token": "..." }
```

## Managing Secrets

### Adding a New Bot

To add a new bot that uses `auth.txt`:

1. **Store the secret in Vault:**

   ```bash
   vault kv put secret/discord-bots/mynewbot token="NEW_BOT_TOKEN"
   ```

2. **Create a `VaultStaticSecret`** in the appropriate file (or a new file):

   ```yaml
   apiVersion: secrets.hashicorp.com/v1beta1
   kind: VaultStaticSecret
   metadata:
     name: mynewbot-vault-secret
     namespace: discord-bots
     labels:
       app: mynewbot
       app.kubernetes.io/managed-by: vault-secrets-operator
   spec:
     vaultAuthRef: vault-auth
     mount: secret
     type: kv-v2
     path: discord-bots/mynewbot
     refreshAfter: 60s
     destination:
       name: mynewbot-secret
       create: true
       labels:
         app: mynewbot
       overwrite: true
       transformation:
         excludeRaw: true
         templates:
           auth.txt:
             text: "{{ .Secrets.token }}"
   ```

3. **Apply it:**

   ```bash
   kubectl apply -f kubernetes/vault/secrets-custom.yaml
   ```

4. **Create the bot deployment** referencing `mynewbot-secret` as usual.

For a bot that uses `auth.json`, use the JSON template pattern instead:

```yaml
transformation:
  excludeRaw: true
  templates:
    auth.json:
      text: |
        {
          "token": "{{ .Secrets.token }}",
          "clientId": "{{ .Secrets.clientId }}"
        }
```

### Rotating a Token

Token rotation is simple — just update the secret in Vault:

```bash
# Update the token for andybot
vault kv put secret/discord-bots/andybot token="NEW_TOKEN_VALUE"
```

VSO will detect the change within 60 seconds (the `refreshAfter` interval) and update the Kubernetes Secret. Your bot pod will pick up the new secret on its next restart, or immediately if using environment variables.

To force an immediate sync, you can restart the operator or delete and re-apply the `VaultStaticSecret`:

```bash
# Force immediate sync by triggering a reconcile
kubectl annotate vaultstaticsecret andybot-vault-secret -n discord-bots \
  force-sync="$(date +%s)" --overwrite
```

### Viewing Synced Secrets

```bash
# List all VaultStaticSecrets and their sync status
kubectl get vaultstaticsecrets -n discord-bots

# Describe one for detailed status including last sync time and errors
kubectl describe vaultstaticsecret andybot-vault-secret -n discord-bots

# View the actual Kubernetes secret data
kubectl get secret andybot-secret -n discord-bots -o jsonpath='{.data.auth\.txt}' | base64 -d

# View an auth.json secret
kubectl get secret owobot-secret -n discord-bots -o jsonpath='{.data.auth\.json}' | base64 -d

# List what's stored in Vault
vault kv list secret/discord-bots/

# Read a specific Vault secret
vault kv get secret/discord-bots/andybot
```

## Troubleshooting

### VaultStaticSecret Shows an Error Status

```bash
# Check the status conditions on the resource
kubectl describe vaultstaticsecret andybot-vault-secret -n discord-bots

# Check VSO operator logs
kubectl logs -n vault-secrets-operator-system \
  -l app.kubernetes.io/name=vault-secrets-operator --tail=100
```

**Common causes:**

- Vault is unreachable (check the address in `vault-connection.yaml`)
- Kubernetes auth is misconfigured (the ServiceAccount or role doesn't match)
- The secret path doesn't exist in Vault yet

### Kubernetes Secret Not Created

```bash
# Verify the VaultStaticSecret exists
kubectl get vaultstaticsecret andybot-vault-secret -n discord-bots

# Check if VSO is running
kubectl get pods -n vault-secrets-operator-system

# Check operator logs for auth errors
kubectl logs -n vault-secrets-operator-system \
  -l app.kubernetes.io/name=vault-secrets-operator --tail=100 | grep -i error
```

### Vault Authentication Failing

```bash
# Verify the ServiceAccount exists
kubectl get serviceaccount discord-bots-vault -n discord-bots

# Verify the Vault role is configured correctly
vault read auth/kubernetes/role/discord-bots

# Verify the policy exists and has correct paths
vault policy read discord-bots-read

# Test authentication manually from inside the cluster
kubectl run vault-test --rm -it --image=vault:latest \
  --serviceaccount=discord-bots-vault \
  -n discord-bots -- vault login -method=kubernetes \
  role=discord-bots
```

### Secret Data Is Empty or Malformed

```bash
# Check what Vault is actually returning
vault kv get -format=json secret/discord-bots/andybot

# Ensure the key names match the template variables
# Template uses {{ .Secrets.token }} so Vault must have a "token" key

# Check the raw K8s secret
kubectl get secret andybot-secret -n discord-bots -o yaml
```

### Vault Is Sealed After Restart

Vault starts in a sealed state after a restart. You need to unseal it:

```bash
vault operator unseal <unseal-key-1>
vault operator unseal <unseal-key-2>
vault operator unseal <unseal-key-3>
```

Until Vault is unsealed, VSO cannot read secrets and your `VaultStaticSecret` resources will show errors.

### Pods CrashLoopBackOff After Migration

If bots were running with manually created secrets and you switch to VSO:

1. Make sure the VSO-created secret has the exact same keys (`auth.txt` or `auth.json`)
2. VSO sets `overwrite: true`, so it will replace existing secrets — verify the data is correct
3. Restart the bot pods to pick up the new secret volume:

   ```bash
   kubectl rollout restart deployment -n discord-bots
   ```

## Migrating from Manual Secrets

If you're currently using manually created Kubernetes secrets:

1. **Run `vault-setup.sh`** to seed your existing auth files into Vault
2. **Run `deploy-vault.sh`** to create the VSO resources
3. VSO will create/overwrite the existing K8s secrets with data from Vault (because `overwrite: true` is set)
4. **Verify** the secrets contain the correct data:

   ```bash
   kubectl get secret andybot-secret -n discord-bots -o jsonpath='{.data.auth\.txt}' | base64 -d
   ```

5. **Restart your bots** to pick up any volume mount changes:

   ```bash
   kubectl rollout restart deployment -n discord-bots
   ```

Your existing deployment YAMLs in `kubernetes/deployments/` do not need any modifications. They reference secrets by name (`andybot-secret`, `owobot-secret`, etc.) and those names are preserved.

## Security Considerations

### Principle of Least Privilege

- The `discord-bots-read` policy only grants **read** access to `secret/data/discord-bots/*`
- The `discord-bots` role is bound to a **specific ServiceAccount** (`discord-bots-vault`) in a **specific namespace** (`discord-bots`)
- Bot pods themselves don't talk to Vault — only VSO does

### Recommendations

1. **Don't use the root token in production.** Create a dedicated admin token or use a different auth method for human operators.

2. **Enable Vault audit logging** to track all secret access:

   ```bash
   vault audit enable file file_path=/vault/logs/audit.log
   ```

3. **Use TLS for Vault** in production. Update `vault-connection.yaml` to use `https://` and set `skipTLSVerify: false`.

4. **Rotate the Vault unseal keys** and store them securely (consider using Vault's auto-unseal with a cloud KMS).

5. **Set a shorter `refreshAfter`** if you need faster token rotation (e.g., `30s`), or longer if you want to reduce load on Vault (e.g., `5m`).

6. **Consider separate Vault policies per bot** if you need fine-grained access control:

   ```hcl
   path "secret/data/discord-bots/andybot" {
     capabilities = ["read"]
   }
   ```

## Uninstalling

### Remove VSO Resources Only (Keep Vault Data)

```bash
# Remove all VSO custom resources and the ServiceAccount
./deploy-vault.sh --delete

# Note: This also deletes the K8s secrets that VSO created.
# Your bot pods will fail until secrets are recreated.
```

### Remove VSO Resources and the Operator

```bash
# Remove VSO resources
./deploy-vault.sh --delete

# Uninstall the Helm chart
helm uninstall vault-secrets-operator -n vault-secrets-operator-system
kubectl delete namespace vault-secrets-operator-system
```

### Remove Everything Including Vault Data

```bash
# Remove VSO resources
./deploy-vault.sh --delete

# Uninstall the operator
helm uninstall vault-secrets-operator -n vault-secrets-operator-system

# Delete secrets from Vault
vault kv metadata delete secret/discord-bots/andybot
vault kv metadata delete secret/discord-bots/piratebot
# ... repeat for each bot, or:
for bot in andybot piratebot wsb braincellbot dickjohnson housemog \
           manganotifier movienightbot owobot oyveybot redditsimbot \
           tarotbot uwubot jailbot jontronbot terrydavisbot \
           scribebot purpleharobot; do
  vault kv metadata delete "secret/discord-bots/$bot"
done

# Remove the Vault policy and role
vault delete auth/kubernetes/role/discord-bots
vault policy delete discord-bots-read
```

### Reverting to Manual Secrets

If you want to go back to manually managed secrets:

1. Run `./deploy-vault.sh --delete` to remove VSO resources
2. Recreate secrets manually using the script in `kubernetes/secrets/README.md`
3. Your bot deployments will continue to work as before

---

## Additional Resources

- [Vault Secrets Operator Documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
- [VSO API Reference](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/api-reference)
- [Vault KV-v2 Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
- [Vault Kubernetes Auth Method](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
- [K3s Documentation](https://docs.k3s.io/)