#!/bin/bash

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
BACKUP_DIR="$PROJECT_ROOT/backups"

# Functions
print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}        DigitalEgiz Secure Password Generator${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    for tool in openssl sed; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install them using your system package manager:"
        echo "  Ubuntu/Debian: apt install openssl"
        exit 1
    fi
    
    # Check if .env file exists
    if [ ! -f "$ENV_FILE" ]; then
        print_error ".env file not found in project root"
        echo "Please run setup script first or create .env file manually"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

create_backup() {
    print_step "Creating backup of current .env file..."
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/.env.passwords_backup_$timestamp"
    
    cp "$ENV_FILE" "$backup_file"
    print_success "Backup created: $backup_file"
}

generate_password() {
    local length="${1:-16}"
    local charset="${2:-A-Za-z0-9}"
    openssl rand -base64 32 | tr -dc "$charset" | head -c "$length"
}

generate_token() {
    local length="${1:-32}"
    openssl rand -hex "$length"
}

generate_api_secret() {
    openssl rand -base64 64 | tr -d '\n'
}

update_passwords() {
    print_step "Generating new secure passwords..."
    
    # Generate passwords
    local postgres_password=$(generate_password 16)
    local influxdb_password=$(generate_password 20)
    local grafana_password=$(generate_password 16)
    local chirpstack_secret=$(generate_api_secret)
    local influxdb_token=$(generate_token 32)
    
    print_success "Passwords generated"
    
    print_step "Updating .env file with new passwords..."
    
    # Use temporary file for atomic updates
    local temp_file=$(mktemp)
    cp "$ENV_FILE" "$temp_file"
    
    # Update passwords (excluding TRAEFIK_AUTH)
    sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${postgres_password}/" "$temp_file"
    sed -i "s/^INFLUXDB_PASSWORD=.*/INFLUXDB_PASSWORD=${influxdb_password}/" "$temp_file"
    sed -i "s/^GRAFANA_PASSWORD=.*/GRAFANA_PASSWORD=${grafana_password}/" "$temp_file"
    sed -i "s/^CHIRPSTACK_API_SECRET=.*/CHIRPSTACK_API_SECRET=${chirpstack_secret}/" "$temp_file"
    sed -i "s/^INFLUXDB_TOKEN=.*/INFLUXDB_TOKEN=${influxdb_token}/" "$temp_file"
    
    # Move temp file to final location
    mv "$temp_file" "$ENV_FILE"
    
    print_success "All passwords updated successfully"
    
    # Display generated passwords
    display_passwords "$postgres_password" "$influxdb_password" "$grafana_password" "$chirpstack_secret" "$influxdb_token"
}

display_passwords() {
    local postgres_password="$1"
    local influxdb_password="$2"
    local grafana_password="$3"
    local chirpstack_secret="$4"
    local influxdb_token="$5"
    
    echo
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}             🔐 Generated Passwords${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
    echo -e "${CYAN}Database Passwords:${NC}"
    echo "   PostgreSQL:       $postgres_password"
    echo
    echo -e "${CYAN}Application Passwords:${NC}"
    echo "   InfluxDB:         $influxdb_password"
    echo "   Grafana:          $grafana_password"
    echo
    echo -e "${CYAN}API Keys & Tokens:${NC}"
    echo "   ChirpStack Secret: $chirpstack_secret"
    echo "   InfluxDB Token:   $influxdb_token"
    echo
    echo -e "${YELLOW}⚠️  IMPORTANT: Save these passwords securely!${NC}"
    echo -e "${YELLOW}   Traefik password was not changed - use setup-https.sh for that.${NC}"
}

display_next_steps() {
    echo
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}             🚀 Next Steps${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
    echo -e "${CYAN}1. Restart services to apply new passwords:${NC}"
    echo "   docker compose down"
    echo "   docker compose up -d"
    echo
    echo -e "${CYAN}2. Update any external configurations that use these passwords${NC}"
    echo
    echo -e "${CYAN}3. Test service access with new credentials${NC}"
    echo
    echo -e "${YELLOW}💡 Security Tips:${NC}"
    echo "   • Store passwords in a secure password manager"
    echo "   • Regularly rotate passwords (recommended: every 90 days)"
    echo "   • Monitor service logs for authentication failures"
    echo "   • Keep backups of working configurations"
    echo
}

confirm_action() {
    echo -e "${YELLOW}⚠️  WARNING: This will replace all service passwords except Traefik!${NC}"
    echo -e "${YELLOW}   Make sure you have backups and are ready to restart services.${NC}"
    echo
    echo -n -e "${CYAN}Do you want to continue? [y/N]${NC}: "
    read -r confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Operation cancelled by user."
        exit 0
    fi
}

# Main script execution
main() {
    print_header
    
    # Check if we're in the right directory
    cd "$PROJECT_ROOT" || {
        print_error "Could not change to project root directory: $PROJECT_ROOT"
        exit 1
    }
    
    check_prerequisites
    confirm_action
    create_backup
    update_passwords
    display_next_steps
    
    print_success "Password generation completed successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 130' INT

# Run main function
main "$@"