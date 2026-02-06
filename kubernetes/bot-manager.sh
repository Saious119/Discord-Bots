#!/bin/bash

# Discord Bot Manager - Helper script for managing individual bots in k3s
# Usage: ./bot-manager.sh <command> <bot-name>

set -e

NAMESPACE="discord-bots"
REGISTRY="${REGISTRY:-localhost:5000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
${CYAN}Discord Bot Manager${NC}

${GREEN}Usage:${NC}
    $0 <command> <bot-name>

${GREEN}Commands:${NC}
    ${YELLOW}status${NC} <bot>       - Show status of a bot
    ${YELLOW}logs${NC} <bot>         - View logs for a bot
    ${YELLOW}restart${NC} <bot>      - Restart a bot
    ${YELLOW}rebuild${NC} <bot>      - Rebuild and redeploy a bot
    ${YELLOW}delete${NC} <bot>       - Delete a bot deployment
    ${YELLOW}describe${NC} <bot>     - Describe bot pod details
    ${YELLOW}shell${NC} <bot>        - Open shell in bot container
    ${YELLOW}secret${NC} <bot>       - View bot secret information
    ${YELLOW}events${NC} <bot>       - Show recent events for a bot
    ${YELLOW}scale${NC} <bot> <N>    - Scale bot to N replicas
    ${YELLOW}list${NC}               - List all deployed bots
    ${YELLOW}list-all${NC}           - List all available bots

${GREEN}Examples:${NC}
    $0 status andybot
    $0 logs andybot
    $0 restart andybot
    $0 rebuild andybot
    $0 logs andybot --follow
    $0 list

${GREEN}Available Bots:${NC}
    ${BLUE}Go:${NC}        andybot, piratebot, wsb
    ${BLUE}C#:${NC}        braincellbot, dickjohnson, housemog, manganotifier, movienightbot
    ${BLUE}Node.js:${NC}   owobot, oyveybot, redditsimbot, tarotbot, uwubot, jailbot, jontronbot, terrydavisbot
    ${BLUE}Python:${NC}    scribebot, purpleharobot

EOF
}

# Function to convert bot name to lowercase
normalize_bot_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Function to get bot directory name
get_bot_dir() {
    local BOT=$1
    case "$BOT" in
        andybot) echo "AndyBot" ;;
        piratebot) echo "PirateBot" ;;
        wsb) echo "WSB" ;;
        braincellbot) echo "BrainCellBot" ;;
        dickjohnson) echo "DickJohnson" ;;
        housemog) echo "HouseMog" ;;
        manganotifier) echo "MangaNotifier" ;;
        movienightbot) echo "MovieNightBot" ;;
        owobot) echo "OwOBot" ;;
        oyveybot) echo "OyVeyBot" ;;
        redditsimbot) echo "RedditSimBot" ;;
        tarotbot) echo "TarotBot" ;;
        uwubot) echo "UwUBot" ;;
        jailbot) echo "JailBot" ;;
        jontronbot) echo "JonTronBot" ;;
        terrydavisbot) echo "TerryDavisBot" ;;
        scribebot) echo "ScribeBot" ;;
        purpleharobot) echo "PurpleHaroBot" ;;
        *) echo "" ;;
    esac
}

# Command: status
cmd_status() {
    local BOT=$1
    print_info "Status for ${BOT}:"
    echo ""

    kubectl get deployment "$BOT" -n "$NAMESPACE" 2>/dev/null || print_error "Deployment not found"
    echo ""

    kubectl get pods -n "$NAMESPACE" -l app="$BOT" 2>/dev/null || print_error "No pods found"
    echo ""

    kubectl get service "$BOT" -n "$NAMESPACE" 2>/dev/null || print_warning "Service not found"
}

# Command: logs
cmd_logs() {
    local BOT=$1
    shift
    local EXTRA_ARGS="$@"

    print_info "Showing logs for ${BOT}..."
    echo ""

    # Check if --follow or -f is in extra args, if not add default tail
    if [[ ! "$EXTRA_ARGS" =~ "-f" ]] && [[ ! "$EXTRA_ARGS" =~ "--follow" ]]; then
        EXTRA_ARGS="--tail=100 $EXTRA_ARGS"
    fi

    kubectl logs -n "$NAMESPACE" -l app="$BOT" $EXTRA_ARGS
}

# Command: restart
cmd_restart() {
    local BOT=$1

    print_info "Restarting ${BOT}..."
    kubectl rollout restart deployment/"$BOT" -n "$NAMESPACE"

    print_info "Waiting for rollout to complete..."
    kubectl rollout status deployment/"$BOT" -n "$NAMESPACE"

    print_success "${BOT} restarted successfully!"
}

# Command: rebuild
cmd_rebuild() {
    local BOT=$1
    local BOT_DIR=$(get_bot_dir "$BOT")

    if [ -z "$BOT_DIR" ]; then
        print_error "Unknown bot: $BOT"
        return 1
    fi

    local PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if [ ! -d "$PROJECT_ROOT/$BOT_DIR" ]; then
        print_error "Bot directory not found: $BOT_DIR"
        return 1
    fi

    print_info "Rebuilding ${BOT}..."
    echo ""

    # Build Docker image
    print_info "Building Docker image..."
    if docker build -t "${REGISTRY}/${BOT}:latest" "$PROJECT_ROOT/$BOT_DIR"; then
        print_success "Image built successfully"
    else
        print_error "Failed to build image"
        return 1
    fi

    # Push to registry
    print_info "Pushing to registry..."
    if docker push "${REGISTRY}/${BOT}:latest"; then
        print_success "Image pushed successfully"
    else
        print_error "Failed to push image"
        return 1
    fi

    # Restart deployment
    print_info "Restarting deployment..."
    kubectl rollout restart deployment/"$BOT" -n "$NAMESPACE"
    kubectl rollout status deployment/"$BOT" -n "$NAMESPACE"

    print_success "${BOT} rebuilt and redeployed successfully!"
}

# Command: delete
cmd_delete() {
    local BOT=$1

    print_warning "This will delete the deployment for ${BOT}"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deleting ${BOT}..."

        kubectl delete deployment "$BOT" -n "$NAMESPACE" 2>/dev/null || true
        kubectl delete service "$BOT" -n "$NAMESPACE" 2>/dev/null || true

        print_success "${BOT} deleted"
    else
        print_info "Cancelled"
    fi
}

# Command: describe
cmd_describe() {
    local BOT=$1

    print_info "Describing ${BOT}..."
    echo ""

    # Get pod name
    local POD=$(kubectl get pods -n "$NAMESPACE" -l app="$BOT" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ -z "$POD" ]; then
        print_error "No pod found for ${BOT}"
        return 1
    fi

    kubectl describe pod "$POD" -n "$NAMESPACE"
}

# Command: shell
cmd_shell() {
    local BOT=$1

    # Get pod name
    local POD=$(kubectl get pods -n "$NAMESPACE" -l app="$BOT" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

    if [ -z "$POD" ]; then
        print_error "No pod found for ${BOT}"
        return 1
    fi

    print_info "Opening shell in ${BOT} (pod: ${POD})..."
    print_info "Type 'exit' to close the shell"
    echo ""

    kubectl exec -it "$POD" -n "$NAMESPACE" -- /bin/sh
}

# Command: secret
cmd_secret() {
    local BOT=$1
    local SECRET_NAME="${BOT}-secret"

    print_info "Secret information for ${BOT}:"
    echo ""

    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
        kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o yaml | grep -v "password\|token" | head -20
        echo ""
        print_info "Secret exists and is mounted"

        # Show which files are in the secret
        echo ""
        print_info "Secret contains:"
        kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data}' | grep -o '"[^"]*":' | tr -d '":' | while read key; do
            echo "  - $key"
        done
    else
        print_error "Secret ${SECRET_NAME} not found"
    fi
}

# Command: events
cmd_events() {
    local BOT=$1

    print_info "Recent events for ${BOT}:"
    echo ""

    kubectl get events -n "$NAMESPACE" --field-selector involvedObject.name="$BOT" --sort-by='.lastTimestamp' | tail -20
}

# Command: scale
cmd_scale() {
    local BOT=$1
    local REPLICAS=$2

    if [ -z "$REPLICAS" ]; then
        print_error "Please specify number of replicas"
        echo "Usage: $0 scale <bot> <replicas>"
        return 1
    fi

    print_warning "Scaling ${BOT} to ${REPLICAS} replicas"
    print_warning "Note: Discord bots typically should run with 1 replica"

    kubectl scale deployment "$BOT" -n "$NAMESPACE" --replicas="$REPLICAS"

    print_success "Scaled ${BOT} to ${REPLICAS} replicas"
}

# Command: list
cmd_list() {
    print_info "Deployed Discord Bots:"
    echo ""

    kubectl get deployments -n "$NAMESPACE" -o wide 2>/dev/null || print_warning "No deployments found"
    echo ""

    print_info "Pod Status:"
    echo ""
    kubectl get pods -n "$NAMESPACE" -o wide 2>/dev/null || print_warning "No pods found"
}

# Command: list-all
cmd_list_all() {
    cat << EOF
${CYAN}All Available Discord Bots:${NC}

${BLUE}Go Bots (3):${NC}
  • andybot
  • piratebot
  • wsb

${BLUE}C# Bots (5):${NC}
  • braincellbot
  • dickjohnson
  • housemog
  • manganotifier
  • movienightbot

${BLUE}Node.js Bots (8):${NC}
  • owobot
  • oyveybot
  • redditsimbot
  • tarotbot
  • uwubot
  • jailbot
  • jontronbot
  • terrydavisbot

${BLUE}Python Bots (2):${NC}
  • scribebot
  • purpleharobot

${GREEN}Total: 18 bots${NC}

${YELLOW}Tip:${NC} Use '$0 list' to see which bots are currently deployed
EOF
}

# Main script logic
COMMAND=${1:-help}

case "$COMMAND" in
    help|--help|-h)
        show_usage
        exit 0
        ;;
    list)
        cmd_list
        ;;
    list-all)
        cmd_list_all
        ;;
    status|logs|restart|rebuild|delete|describe|shell|secret|events|scale)
        BOT=$(normalize_bot_name "$2")

        if [ -z "$BOT" ]; then
            print_error "Please specify a bot name"
            echo ""
            show_usage
            exit 1
        fi

        # Check if kubectl is available
        if ! command -v kubectl &> /dev/null; then
            print_error "kubectl is not installed or not in PATH"
            exit 1
        fi

        # Execute command
        case "$COMMAND" in
            status)
                cmd_status "$BOT"
                ;;
            logs)
                shift 2
                cmd_logs "$BOT" "$@"
                ;;
            restart)
                cmd_restart "$BOT"
                ;;
            rebuild)
                cmd_rebuild "$BOT"
                ;;
            delete)
                cmd_delete "$BOT"
                ;;
            describe)
                cmd_describe "$BOT"
                ;;
            shell)
                cmd_shell "$BOT"
                ;;
            secret)
                cmd_secret "$BOT"
                ;;
            events)
                cmd_events "$BOT"
                ;;
            scale)
                cmd_scale "$BOT" "$3"
                ;;
        esac
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        echo ""
        show_usage
        exit 1
        ;;
esac
