#!/bin/bash
# =============================================================================
# Deploy Vault Secrets Operator Resources to K3s
# =============================================================================
# This script applies all VSO (Vault Secrets Operator) YAML manifests to
# your k3s cluster, setting up the connection, auth, and secret syncing
# for all Discord bots.
#
# Prerequisites:
#   - kubectl configured for your k3s cluster
#   - Vault Secrets Operator installed in the cluster
#   - Vault server-side setup completed (run vault-setup.sh first)
#   - discord-bots namespace exists
#
# Usage:
#   chmod +x deploy-vault.sh
#   ./deploy-vault.sh [--dry-run] [--delete]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="discord-bots"
VSO_NAMESPACE="vault-secrets-operator-system"

DRY_RUN=false
DELETE=false

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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Apply all Vault Secrets Operator resources to the k3s cluster.

Options:
  --dry-run     Show what would be applied without making changes
  --delete      Remove all VSO resources from the cluster
  -h, --help    Show this help message

Examples:
  $(basename "$0")              # Apply all VSO resources
  $(basename "$0") --dry-run    # Preview changes without applying
  $(basename "$0") --delete     # Remove all VSO resources
EOF
    exit 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --delete)
            DELETE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# =============================================================================
# Preflight Checks
# =============================================================================

preflight_checks() {
    log_section "Preflight Checks"

    local failed=0

    # Check kubectl
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl not found in PATH"
        failed=1
    else
        log_success "kubectl found"
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &>/dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        failed=1
    else
        log_success "Cluster is reachable"
    fi

    # Check if VSO is installed
    if kubectl get deployment -n "$VSO_NAMESPACE" -l app.kubernetes.io/name=vault-secrets-operator &>/dev/null 2>&1; then
        local ready
        ready="$(kubectl get deployment -n "$VSO_NAMESPACE" -l app.kubernetes.io/name=vault-secrets-operator -o jsonpath='{.items[0].status.readyReplicas}' 2>/dev/null || echo "0")"
        if [ "${ready:-0}" -ge 1 ]; then
            log_success "Vault Secrets Operator is running in $VSO_NAMESPACE"
        else
            log_warn "Vault Secrets Operator deployment found but no ready replicas"
            log_warn "VSO may still be starting up. Continuing anyway..."
        fi
    else
        log_warn "Vault Secrets Operator not detected in $VSO_NAMESPACE"
        log_warn "Install it first with:"
        log_warn "  helm repo add hashicorp https://helm.releases.hashicorp.com"
        log_warn "  helm repo update"
        log_warn "  helm install vault-secrets-operator hashicorp/vault-secrets-operator \\"
        log_warn "    -n $VSO_NAMESPACE --create-namespace"
        echo ""

        if [ "$DRY_RUN" = false ] && [ "$DELETE" = false ]; then
            read -rp "Continue anyway? (y/N): " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                log_info "Aborting."
                exit 1
            fi
        fi
    fi

    # Check that YAML files exist
    local yaml_count
    yaml_count="$(find "$SCRIPT_DIR" -name '*.yaml' -type f | wc -l)"
    if [ "$yaml_count" -eq 0 ]; then
        log_error "No YAML files found in $SCRIPT_DIR"
        failed=1
    else
        log_success "Found $yaml_count YAML manifest(s) in vault directory"
    fi

    if [ "$failed" -eq 1 ]; then
        log_error "Preflight checks failed. Fix the above errors and try again."
        exit 1
    fi
}

# =============================================================================
# Ensure Namespace
# =============================================================================

ensure_namespace() {
    log_section "Ensuring Namespace"

    local ns_file="$KUBE_DIR/namespace.yaml"

    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_success "Namespace '$NAMESPACE' already exists"
    else
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would create namespace '$NAMESPACE'"
        else
            if [ -f "$ns_file" ]; then
                kubectl apply -f "$ns_file"
            else
                kubectl create namespace "$NAMESPACE"
            fi
            log_success "Namespace '$NAMESPACE' created"
        fi
    fi
}

# =============================================================================
# Apply VSO Resources
# =============================================================================

apply_resources() {
    log_section "Applying VSO Resources"

    local kubectl_cmd="kubectl apply"
    if [ "$DRY_RUN" = true ]; then
        kubectl_cmd="kubectl apply --dry-run=client"
        log_info "Running in DRY RUN mode — no changes will be made"
        echo ""
    fi

    # Define the order of application — connection and auth first, then secrets
    local ordered_files=(
        "vault-connection.yaml"
        "secrets-go-bots.yaml"
        "secrets-csharp-bots.yaml"
        "secrets-nodejs-bots.yaml"
        "secrets-python-bots.yaml"
    )

    for filename in "${ordered_files[@]}"; do
        local filepath="$SCRIPT_DIR/$filename"
        if [ -f "$filepath" ]; then
            log_info "Applying $filename..."
            if $kubectl_cmd -f "$filepath"; then
                log_success "$filename applied"
            else
                log_error "Failed to apply $filename"
                exit 1
            fi
        else
            log_warn "$filename not found — skipping"
        fi
    done

    # Apply any additional YAML files not in the ordered list
    for filepath in "$SCRIPT_DIR"/*.yaml; do
        local filename
        filename="$(basename "$filepath")"

        # Skip files we already applied
        local already_applied=false
        for ordered in "${ordered_files[@]}"; do
            if [ "$filename" = "$ordered" ]; then
                already_applied=true
                break
            fi
        done

        if [ "$already_applied" = true ]; then
            continue
        fi

        log_info "Applying $filename..."
        if $kubectl_cmd -f "$filepath"; then
            log_success "$filename applied"
        else
            log_error "Failed to apply $filename"
            exit 1
        fi
    done
}

# =============================================================================
# Delete VSO Resources
# =============================================================================

delete_resources() {
    log_section "Deleting VSO Resources"

    if [ "$DRY_RUN" = true ]; then
        log_info "Running in DRY RUN mode — showing what would be deleted"
        echo ""
    fi

    # Delete secrets (VaultStaticSecret) first, then auth/connection
    local reverse_files=(
        "secrets-python-bots.yaml"
        "secrets-nodejs-bots.yaml"
        "secrets-csharp-bots.yaml"
        "secrets-go-bots.yaml"
        "vault-connection.yaml"
    )

    for filename in "${reverse_files[@]}"; do
        local filepath="$SCRIPT_DIR/$filename"
        if [ -f "$filepath" ]; then
            log_info "Deleting resources from $filename..."
            if [ "$DRY_RUN" = true ]; then
                kubectl delete --dry-run=client -f "$filepath" 2>/dev/null || true
            else
                kubectl delete -f "$filepath" --ignore-not-found=true 2>/dev/null || true
            fi
            log_success "$filename resources deleted"
        fi
    done

    # Delete any additional YAML files
    for filepath in "$SCRIPT_DIR"/*.yaml; do
        local filename
        filename="$(basename "$filepath")"

        local already_deleted=false
        for rev in "${reverse_files[@]}"; do
            if [ "$filename" = "$rev" ]; then
                already_deleted=true
                break
            fi
        done

        if [ "$already_deleted" = true ]; then
            continue
        fi

        log_info "Deleting resources from $filename..."
        if [ "$DRY_RUN" = true ]; then
            kubectl delete --dry-run=client -f "$filepath" 2>/dev/null || true
        else
            kubectl delete -f "$filepath" --ignore-not-found=true 2>/dev/null || true
        fi
        log_success "$filename resources deleted"
    done
}

# =============================================================================
# Verify Deployment
# =============================================================================

verify_deployment() {
    log_section "Verifying Deployment"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Skipping verification"
        return
    fi

    echo ""
    log_info "VaultConnection:"
    kubectl get vaultconnection -n "$NAMESPACE" 2>/dev/null || log_warn "  No VaultConnection resources found"

    echo ""
    log_info "VaultAuth:"
    kubectl get vaultauth -n "$NAMESPACE" 2>/dev/null || log_warn "  No VaultAuth resources found"

    echo ""
    log_info "VaultStaticSecrets:"
    kubectl get vaultstaticsecrets -n "$NAMESPACE" 2>/dev/null || log_warn "  No VaultStaticSecret resources found"

    echo ""
    log_info "Kubernetes Secrets (created by VSO):"
    kubectl get secrets -n "$NAMESPACE" -l app.kubernetes.io/managed-by=vault-secrets-operator 2>/dev/null || true

    echo ""
    log_info "All Kubernetes Secrets in $NAMESPACE:"
    kubectl get secrets -n "$NAMESPACE" --no-headers 2>/dev/null | while read -r line; do
        echo "  $line"
    done

    echo ""
    log_info "ServiceAccount:"
    kubectl get serviceaccount discord-bots-vault -n "$NAMESPACE" 2>/dev/null || log_warn "  ServiceAccount discord-bots-vault not found"
}

# =============================================================================
# Wait for Secrets to Sync
# =============================================================================

wait_for_sync() {
    if [ "$DRY_RUN" = true ]; then
        return
    fi

    log_section "Waiting for Secrets to Sync"

    log_info "Waiting up to 120 seconds for VaultStaticSecrets to become ready..."
    echo ""

    local timeout=120
    local interval=5
    local elapsed=0

    local expected_bots=(
        andybot piratebot wsb
        braincellbot dickjohnson housemog manganotifier movienightbot
        owobot oyveybot redditsimbot tarotbot uwubot jailbot jontronbot terrydavisbot
        scribebot purpleharobot
    )

    while [ "$elapsed" -lt "$timeout" ]; do
        local all_ready=true
        local ready_count=0
        local total=${#expected_bots[@]}

        for bot in "${expected_bots[@]}"; do
            local secret_name="${bot}-secret"
            if kubectl get secret "$secret_name" -n "$NAMESPACE" &>/dev/null; then
                ready_count=$((ready_count + 1))
            else
                all_ready=false
            fi
        done

        printf "\r  Secrets synced: %d/%d (elapsed: %ds)" "$ready_count" "$total" "$elapsed"

        if [ "$all_ready" = true ]; then
            echo ""
            log_success "All $total secrets are synced!"
            return
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    echo ""
    log_warn "Timed out waiting for all secrets. $ready_count/$total secrets synced."
    log_warn "Some secrets may still be syncing. Check status with:"
    log_warn "  kubectl get vaultstaticsecrets -n $NAMESPACE"
    log_warn "  kubectl describe vaultstaticsecret <name> -n $NAMESPACE"
}

# =============================================================================
# Print Summary
# =============================================================================

print_summary() {
    log_section "Summary"

    if [ "$DELETE" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would have deleted all VSO resources from $NAMESPACE"
        else
            log_success "All VSO resources deleted from $NAMESPACE"
            echo ""
            log_info "Note: Kubernetes Secrets created by VSO are also removed."
            log_info "Your bot deployments will fail until secrets are recreated."
            log_info "To restore, run: ./deploy-vault.sh"
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] No changes were made. Remove --dry-run to apply."
        else
            log_success "All VSO resources deployed to $NAMESPACE"
            echo ""
            log_info "Useful commands:"
            echo ""
            echo "  # Check sync status of all VaultStaticSecrets"
            echo "  kubectl get vaultstaticsecrets -n $NAMESPACE"
            echo ""
            echo "  # Describe a specific secret sync for debugging"
            echo "  kubectl describe vaultstaticsecret andybot-vault-secret -n $NAMESPACE"
            echo ""
            echo "  # View a synced Kubernetes secret"
            echo "  kubectl get secret andybot-secret -n $NAMESPACE -o yaml"
            echo ""
            echo "  # Check VSO operator logs"
            echo "  kubectl logs -n $VSO_NAMESPACE -l app.kubernetes.io/name=vault-secrets-operator -f"
            echo ""
            echo "  # Deploy your bots (no deployment changes needed!)"
            echo "  kubectl apply -f $KUBE_DIR/deployments/"
            echo ""
        fi
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    if [ "$DELETE" = true ]; then
        echo -e "${CYAN}║  Remove VSO Resources from K3s                          ║${NC}"
    else
        echo -e "${CYAN}║  Deploy VSO Resources to K3s                             ║${NC}"
    fi
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_warn "DRY RUN MODE — no changes will be made to the cluster"
    fi

    preflight_checks

    if [ "$DELETE" = true ]; then
        delete_resources
    else
        ensure_namespace
        apply_resources
        verify_deployment
        wait_for_sync
    fi

    print_summary
}

main "$@"
