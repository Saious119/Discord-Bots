#!/bin/bash
# =============================================================================
# Vault Server-Side Setup Script for Discord Bots
# =============================================================================
# This script configures your local HashiCorp Vault instance to:
#   1. Enable the KV-v2 secrets engine
#   2. Seed all Discord bot secrets into Vault
#   3. Enable and configure Kubernetes auth so VSO can authenticate
#   4. Create the policy and role for the discord-bots namespace
#
# Prerequisites:
#   - vault CLI installed and in PATH
#   - VAULT_ADDR and VAULT_TOKEN environment variables set
#   - kubectl configured for your k3s cluster
#   - Bot auth files exist in their respective directories
#
# Usage:
#   export VAULT_ADDR="http://127.0.0.1:8200"
#   export VAULT_TOKEN="hvs.your-root-token"
#   chmod +x vault-setup.sh
#   ./vault-setup.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root is two levels up from this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}============================================================${NC}"
}

check_prerequisites() {
    log_section "Checking Prerequisites"

    local missing=0

    if ! command -v vault &>/dev/null; then
        log_error "vault CLI not found. Install it from https://developer.hashicorp.com/vault/install"
        missing=1
    else
        log_success "vault CLI found: $(vault version)"
    fi

    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl not found."
        missing=1
    else
        log_success "kubectl found"
    fi

    if [ -z "${VAULT_ADDR:-}" ]; then
        log_error "VAULT_ADDR is not set. Export it first:"
        log_error '  export VAULT_ADDR="http://127.0.0.1:8200"'
        missing=1
    else
        log_success "VAULT_ADDR=$VAULT_ADDR"
    fi

    if [ -z "${VAULT_TOKEN:-}" ]; then
        log_error "VAULT_TOKEN is not set. Export it first:"
        log_error '  export VAULT_TOKEN="hvs.your-root-token"'
        missing=1
    else
        log_success "VAULT_TOKEN is set"
    fi

    if [ "$missing" -eq 1 ]; then
        log_error "Missing prerequisites. Fix the above errors and try again."
        exit 1
    fi

    # Verify Vault is reachable
    if ! vault status &>/dev/null; then
        log_error "Cannot connect to Vault at $VAULT_ADDR"
        log_error "Make sure Vault is running and unsealed."
        exit 1
    fi

    log_success "Vault is reachable and unsealed"
}

# =============================================================================
# Step 1: Enable KV-v2 Secrets Engine
# =============================================================================

enable_secrets_engine() {
    log_section "Step 1: Enabling KV-v2 Secrets Engine"

    if vault secrets list -format=json | grep -q '"secret/"'; then
        log_warn "KV secrets engine already enabled at 'secret/'. Skipping."
    else
        vault secrets enable -path=secret kv-v2
        log_success "KV-v2 secrets engine enabled at 'secret/'"
    fi
}

# =============================================================================
# Step 2: Seed Bot Secrets into Vault
# =============================================================================

seed_secret_from_auth_txt() {
    local bot_name="$1"
    local bot_dir="$2"
    local auth_file="$PROJECT_ROOT/$bot_dir/auth.txt"

    if [ ! -f "$auth_file" ]; then
        log_warn "$bot_name: auth.txt not found at $auth_file — skipping"
        return
    fi

    local token
    token="$(cat "$auth_file" | tr -d '[:space:]')"

    if [ -z "$token" ]; then
        log_warn "$bot_name: auth.txt is empty — skipping"
        return
    fi

    vault kv put "secret/discord-bots/$bot_name" token="$token"
    log_success "$bot_name: seeded token from auth.txt"
}

seed_secret_from_auth_json() {
    local bot_name="$1"
    local bot_dir="$2"
    local auth_file="$PROJECT_ROOT/$bot_dir/auth.json"

    if [ ! -f "$auth_file" ]; then
        log_warn "$bot_name: auth.json not found at $auth_file — skipping"
        return
    fi

    # Extract token and clientId from the JSON file
    local token client_id

    if command -v jq &>/dev/null; then
        token="$(jq -r '.token // empty' "$auth_file")"
        client_id="$(jq -r '.clientId // empty' "$auth_file")"
    else
        # Fallback: naive grep-based parsing if jq isn't installed
        log_warn "jq not found — using fallback parser for $bot_name auth.json"
        token="$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$auth_file" | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
        client_id="$(grep -o '"clientId"[[:space:]]*:[[:space:]]*"[^"]*"' "$auth_file" | head -1 | sed 's/.*"clientId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
    fi

    if [ -z "$token" ]; then
        log_warn "$bot_name: no 'token' field found in auth.json — skipping"
        return
    fi

    local vault_args=("token=$token")
    if [ -n "$client_id" ]; then
        vault_args+=("clientId=$client_id")
    fi

    vault kv put "secret/discord-bots/$bot_name" "${vault_args[@]}"
    log_success "$bot_name: seeded token + clientId from auth.json"
}

seed_all_secrets() {
    log_section "Step 2: Seeding Bot Secrets into Vault"

    log_info "--- Go Bots (auth.txt) ---"
    seed_secret_from_auth_txt "andybot"    "AndyBot"
    seed_secret_from_auth_txt "piratebot"  "PirateBot"
    seed_secret_from_auth_txt "wsb"        "WSB"

    log_info "--- C# Bots (auth.txt) ---"
    seed_secret_from_auth_txt "braincellbot"  "BrainCellBot"
    seed_secret_from_auth_txt "dickjohnson"   "DickJohnson"
    seed_secret_from_auth_txt "housemog"      "HouseMog"
    seed_secret_from_auth_txt "manganotifier" "MangaNotifier"
    seed_secret_from_auth_txt "movienightbot" "MovieNightBot"

    log_info "--- Node.js Bots (auth.json) ---"
    seed_secret_from_auth_json "owobot"        "OwOBot"
    seed_secret_from_auth_json "oyveybot"      "OyVeyBot"
    seed_secret_from_auth_json "redditsimbot"  "RedditSimBot"
    seed_secret_from_auth_json "tarotbot"      "TarotBot"
    seed_secret_from_auth_json "uwubot"        "UwUBot"
    seed_secret_from_auth_json "jailbot"       "JailBot"
    seed_secret_from_auth_json "jontronbot"    "JonTronBot"
    seed_secret_from_auth_json "terrydavisbot" "TerryDavisBot"

    log_info "--- Python Bots (auth.txt) ---"
    seed_secret_from_auth_txt "scribebot"      "ScribeBot"
    seed_secret_from_auth_txt "purpleharobot"  "PurpleHaroBot"
}

# =============================================================================
# Step 3: Enable and Configure Kubernetes Auth
# =============================================================================

configure_kubernetes_auth() {
    log_section "Step 3: Configuring Kubernetes Auth Method"

    # Enable kubernetes auth if not already enabled
    if vault auth list -format=json | grep -q '"kubernetes/"'; then
        log_warn "Kubernetes auth method already enabled. Skipping enable."
    else
        vault auth enable kubernetes
        log_success "Kubernetes auth method enabled"
    fi

    # Determine the K8s API server address
    # For in-cluster Vault, use the internal service DNS
    # For external Vault, we need the API server's externally reachable address
    local k8s_host
    k8s_host="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)"

    if [ -z "$k8s_host" ]; then
        k8s_host="https://kubernetes.default.svc.cluster.local:443"
        log_warn "Could not detect K8s API server from kubeconfig. Using default: $k8s_host"
    fi

    log_info "Using Kubernetes API server: $k8s_host"

    # Get the CA certificate from k3s
    # k3s stores it at /var/lib/rancher/k3s/server/tls/server-ca.crt
    # or we can get it from the kubeconfig or the cluster itself
    local ca_cert=""

    # Try to get CA from the running cluster via a ServiceAccount
    if kubectl get configmap kube-root-ca.crt -n kube-system -o jsonpath='{.data.ca\.crt}' &>/dev/null; then
        ca_cert="$(kubectl get configmap kube-root-ca.crt -n kube-system -o jsonpath='{.data.ca\.crt}')"
        log_success "Retrieved CA cert from kube-root-ca.crt configmap"
    elif [ -f /var/lib/rancher/k3s/server/tls/server-ca.crt ]; then
        ca_cert="$(cat /var/lib/rancher/k3s/server/tls/server-ca.crt)"
        log_success "Retrieved CA cert from k3s TLS directory"
    else
        log_warn "Could not auto-detect K8s CA cert. Vault may not be able to verify the API server."
        log_warn "You can manually set it later with:"
        log_warn "  vault write auth/kubernetes/config kubernetes_ca_cert=@/path/to/ca.crt"
    fi

    # Write the kubernetes auth config
    if [ -n "$ca_cert" ]; then
        vault write auth/kubernetes/config \
            kubernetes_host="$k8s_host" \
            kubernetes_ca_cert="$ca_cert"
    else
        vault write auth/kubernetes/config \
            kubernetes_host="$k8s_host" \
            disable_iss_validation=true
    fi

    log_success "Kubernetes auth method configured"
}

# =============================================================================
# Step 4: Create Vault Policy and Role
# =============================================================================

create_policy_and_role() {
    log_section "Step 4: Creating Vault Policy and Role"

    # Create the policy that grants read access to discord-bots secrets
    log_info "Writing policy: discord-bots-read"

    vault policy write discord-bots-read - <<'POLICY'
# discord-bots-read policy
# Grants read-only access to all Discord bot secrets
# Used by the Vault Secrets Operator via Kubernetes auth

# Allow reading all bot secrets under secret/data/discord-bots/*
path "secret/data/discord-bots/*" {
  capabilities = ["read"]
}

# Allow listing secrets (needed for discovery)
path "secret/metadata/discord-bots/*" {
  capabilities = ["read", "list"]
}
POLICY

    log_success "Policy 'discord-bots-read' created"

    # Create the Kubernetes auth role
    # This role binds the discord-bots-vault ServiceAccount in the discord-bots
    # namespace to the discord-bots-read policy
    log_info "Writing role: discord-bots"

    vault write auth/kubernetes/role/discord-bots \
        bound_service_account_names=discord-bots-vault \
        bound_service_account_namespaces=discord-bots \
        policies=discord-bots-read \
        ttl=1h \
        max_ttl=24h

    log_success "Role 'discord-bots' created"
    log_info "  Bound SA: discord-bots-vault"
    log_info "  Bound NS: discord-bots"
    log_info "  Policy:   discord-bots-read"
    log_info "  TTL:      1h (max 24h)"
}

# =============================================================================
# Step 5: Verify
# =============================================================================

verify_setup() {
    log_section "Step 5: Verification"

    log_info "Listing secrets stored in Vault under secret/discord-bots/..."
    echo ""

    local bots=(
        andybot piratebot wsb
        braincellbot dickjohnson housemog manganotifier movienightbot
        owobot oyveybot redditsimbot tarotbot uwubot jailbot jontronbot terrydavisbot
        scribebot purpleharobot
    )

    local found=0
    local missing=0

    for bot in "${bots[@]}"; do
        if vault kv get -format=json "secret/discord-bots/$bot" &>/dev/null; then
            log_success "  secret/discord-bots/$bot"
            found=$((found + 1))
        else
            log_warn "  secret/discord-bots/$bot — NOT FOUND"
            missing=$((missing + 1))
        fi
    done

    echo ""
    log_info "Secrets found: $found / $((found + missing))"

    if [ "$missing" -gt 0 ]; then
        log_warn "$missing secrets were not seeded (auth files probably missing)."
        log_warn "You can manually add them later:"
        log_warn '  vault kv put secret/discord-bots/<botname> token="YOUR_TOKEN"'
        log_warn '  vault kv put secret/discord-bots/<botname> token="YOUR_TOKEN" clientId="YOUR_CLIENT_ID"'
    fi

    echo ""
    log_info "Verifying Vault policy..."
    vault policy read discord-bots-read >/dev/null && log_success "Policy 'discord-bots-read' exists"

    log_info "Verifying Vault role..."
    vault read auth/kubernetes/role/discord-bots >/dev/null && log_success "Role 'discord-bots' exists"
}

# =============================================================================
# Print Next Steps
# =============================================================================

print_next_steps() {
    log_section "Setup Complete! Next Steps"

    cat <<'EOF'

  1. Install the Vault Secrets Operator (if not already installed):

     helm repo add hashicorp https://helm.releases.hashicorp.com
     helm repo update
     helm install vault-secrets-operator hashicorp/vault-secrets-operator \
       -n vault-secrets-operator-system \
       --create-namespace

  2. Ensure the discord-bots namespace exists:

     kubectl apply -f kubernetes/namespace.yaml

  3. Apply the Vault connection, auth, and service account:

     kubectl apply -f kubernetes/vault/vault-connection.yaml

  4. Apply the VaultStaticSecret resources for all bots:

     kubectl apply -f kubernetes/vault/secrets-go-bots.yaml
     kubectl apply -f kubernetes/vault/secrets-csharp-bots.yaml
     kubectl apply -f kubernetes/vault/secrets-nodejs-bots.yaml
     kubectl apply -f kubernetes/vault/secrets-python-bots.yaml

     Or all at once:

     kubectl apply -f kubernetes/vault/

  5. Verify the secrets are syncing:

     kubectl get vaultstaticsecrets -n discord-bots
     kubectl get secrets -n discord-bots

  6. Deploy your bots (no changes needed to existing deployments!):

     kubectl apply -f kubernetes/deployments/

  Note: Your existing deployment YAMLs do NOT need any changes.
  VSO creates the same K8s secrets (e.g. andybot-secret) that your
  deployments already reference. The bots will pick them up as-is.

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  HashiCorp Vault Setup for Discord Bots (VSO)           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    check_prerequisites
    enable_secrets_engine
    seed_all_secrets
    configure_kubernetes_auth
    create_policy_and_role
    verify_setup
    print_next_steps
}

main "$@"
