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
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"
BACKUP_DIR="$PROJECT_ROOT/backups"

# Functions
print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}             DigitalEgiz HTTPS Setup Script${NC}"
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
    for tool in curl htpasswd openssl sed; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install them using your system package manager:"
        echo "  Ubuntu/Debian: apt install apache2-utils openssl curl"
        echo "  RHEL/CentOS:   yum install httpd-tools openssl curl"
        exit 1
    fi
    
    # Check if .env.example exists
    if [ ! -f "$ENV_EXAMPLE" ]; then
        print_error ".env.example not found in project root"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

create_env_from_example() {
    if [ ! -f "$ENV_FILE" ]; then
        print_step "Creating .env from .env.example..."
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        print_success ".env file created"
    else
        print_warning ".env file already exists"
    fi
}

create_backup() {
    print_step "Creating backup of current configuration..."
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/.env.backup_$timestamp"
    
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$backup_file"
        print_success "Backup created: $backup_file"
    fi
}

validate_domain() {
    local domain="$1"
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        print_error "Invalid domain format"
        return 1
    fi
}

get_user_input() {
    local prompt="$1"
    local var_name="$2"
    local validate_func="${3:-}"
    local value=""
    
    while true; do
        echo -n -e "${CYAN}$prompt${NC}: "
        read -r value
        
        if [ -n "$validate_func" ] && ! "$validate_func" "$value"; then
            continue
        fi
        
        if [ -n "$value" ]; then
            eval "$var_name='$value'"
            break
        else
            print_error "This field is required"
        fi
    done
}

validate_email() {
    local email="$1"
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        print_error "Invalid email format"
        return 1
    fi
}

validate_password() {
    local password="$1"
    if [ ${#password} -ge 8 ]; then
        return 0
    else
        print_error "Password must be at least 8 characters long"
        return 1
    fi
}

generate_secure_password() {
    local length="${1:-16}"
    openssl rand -base64 32 | tr -d '=' | head -c "$length"
}

generate_traefik_hash() {
    local password="$1"
    echo -n "$password" | htpasswd -niB admin | cut -d: -f2 | sed 's/\$/\\$/g'
}

get_secure_password() {
    local password=""
    local confirm_password=""
    
    while true; do
        echo -n -e "${CYAN}Enter Traefik dashboard password (min 8 chars)${NC}: "
        read -s password
        echo
        
        if ! validate_password "$password"; then
            continue
        fi
        
        echo -n -e "${CYAN}Confirm password${NC}: "
        read -s confirm_password
        echo
        
        if [ "$password" = "$confirm_password" ]; then
            echo "$password"
            return 0
        else
            print_error "Passwords do not match. Please try again."
        fi
    done
}

update_env_file() {
    local domain="$1"
    local email="$2"
    local traefik_hash="$3"
    
    print_step "Updating .env configuration..."
    
    # Use temporary file for atomic updates
    local temp_file=$(mktemp)
    cp "$ENV_FILE" "$temp_file"
    
    # Update configurations
    sed -i "s/^DOMAIN=.*/DOMAIN=${domain}/" "$temp_file"
    sed -i "s/^LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=${email}/" "$temp_file"
    sed -i "s|^TRAEFIK_AUTH=.*|TRAEFIK_AUTH=admin:${traefik_hash}|" "$temp_file"
    
    # Move temp file to final location
    mv "$temp_file" "$ENV_FILE"
    
    print_success "Configuration updated successfully"
}

display_configuration() {
    local domain="$1"
    local password="$2"
    
    echo
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}             🎯 Your HTTPS Configuration${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
    echo -e "${CYAN}🌐 Services URLs:${NC}"
    echo "   Main Site:         https://$domain"
    echo "   ChirpStack:        https://$domain/chirpstack/"
    echo "   Grafana:          https://$domain/grafana/"
    echo "   InfluxDB:         https://$domain/influxdb/"
    echo "   Traefik Dashboard: https://$domain/dashboard/"
    echo
    echo -e "${CYAN}🔐 Traefik Dashboard Login:${NC}"
    echo "   Username: admin"
    echo "   Password: $password"
    echo
    echo -e "${YELLOW}⚠️  IMPORTANT: Save the Traefik password above - it won't be shown again!${NC}"
}

display_next_steps() {
    local domain="$1"
    
    echo
    echo -e "${GREEN}================================================================${NC}"
    echo -e "${GREEN}             🚀 Next Steps${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo
    echo -e "${CYAN}1. Deploy with HTTPS:${NC}"
    echo "   docker compose -f docker-compose.https.yml down"
    echo "   docker compose -f docker-compose.https.yml up -d"
    echo
    echo -e "${CYAN}2. Monitor certificate generation (2-3 minutes):${NC}"
    echo "   docker compose -f docker-compose.https.yml logs -f traefik"
    echo
    echo -e "${CYAN}3. Test your secure endpoints:${NC}"
    echo "   curl -I https://$domain"
    echo "   curl -I https://$domain/dashboard/"
    echo
    echo -e "${CYAN}4. Check firewall (ensure ports 80 and 443 are open):${NC}"
    echo "   sudo ufw status"
    echo "   sudo ufw allow 80/tcp"
    echo "   sudo ufw allow 443/tcp"
    echo
    echo -e "${CYAN}5. Verify DNS is pointing to your server:${NC}"
    echo "   dig $domain"
    echo "   nslookup $domain"
    echo
    echo -e "${YELLOW}💡 Pro tips:${NC}"
    echo "   • Ensure DNS A record points $domain to your server IP"
    echo "   • Let's Encrypt certificates auto-renew every 90 days"
    echo "   • Check certificate status: https://$domain (look for valid SSL)"
    echo "   • Backup your .env file regularly"
    echo
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
    create_env_from_example
    create_backup
    
    # Get domain
    local domain=""
    get_user_input "Enter your domain (e.g., example.com or subdomain.example.com)" domain validate_domain
    
    # Get email for Let's Encrypt
    local email=""
    get_user_input "Enter your email for Let's Encrypt certificates" email validate_email
    
    # Get Traefik password
    print_step "Setting up Traefik dashboard credentials..."
    local traefik_password=$(get_secure_password)
    local traefik_hash=$(generate_traefik_hash "$traefik_password")
    print_success "Traefik credentials configured"
    
    # Update configuration
    update_env_file "$domain" "$email" "$traefik_hash"
    
    # Display results
    display_configuration "$domain" "$traefik_password"
    display_next_steps "$domain"
    
    print_success "HTTPS setup completed successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 130' INT

# Run main function
main "$@"