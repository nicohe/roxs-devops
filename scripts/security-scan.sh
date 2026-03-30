#!/bin/bash

# Security Scan Script with Trivy
# This script builds and scans Docker images for vulnerabilities

set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY:-roxsross}"
TAG="${TAG:-secure}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Function to check if Trivy is installed
check_trivy() {
    if ! command -v trivy &> /dev/null; then
        print_error "Trivy is not installed!"
        print_info "Installing Trivy..."
        
        # Install Trivy based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            brew install aquasecurity/trivy/trivy
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        else
            print_error "Unsupported OS. Please install Trivy manually: https://aquasecurity.github.io/trivy/"
            exit 1
        fi
    else
        print_success "Trivy is already installed"
        trivy --version
    fi
}

# Function to scan a Docker image
scan_image() {
    local image_name=$1
    local service_name=$2
    
    print_info "Scanning $image_name for vulnerabilities..."
    
    # Create reports directory if it doesn't exist
    mkdir -p reports
    
    # Scan and generate JSON report
    trivy image \
        --severity CRITICAL,HIGH,MEDIUM \
        --format json \
        --output "reports/${service_name}-scan.json" \
        "$image_name"
    
    # Scan and show table format
    trivy image \
        --severity CRITICAL,HIGH,MEDIUM \
        --format table \
        "$image_name" | tee "reports/${service_name}-scan.txt"
    
    # Check for CRITICAL or HIGH vulnerabilities
    CRITICAL_COUNT=$(trivy image --severity CRITICAL --format json "$image_name" 2>/dev/null | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' || echo 0)
    HIGH_COUNT=$(trivy image --severity HIGH --format json "$image_name" 2>/dev/null | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' || echo 0)
    
    print_info "Found $CRITICAL_COUNT CRITICAL and $HIGH_COUNT HIGH vulnerabilities in $service_name"
    
    if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
        print_warning "Image $image_name has security vulnerabilities!"
        return 1
    else
        print_success "Image $image_name passed security scan!"
        return 0
    fi
}

# Function to build and scan all services
build_and_scan_all() {
    local services=("vote" "result" "worker")
    local failed_services=()
    
    for service in "${services[@]}"; do
        print_info "========================================="
        print_info "Building $service service..."
        print_info "========================================="
        
        cd "roxs-voting-app/$service"
        
        # Build the image
        docker build -t "${DOCKER_REGISTRY}/${service}:${TAG}" .
        
        if [ $? -eq 0 ]; then
            print_success "Successfully built ${DOCKER_REGISTRY}/${service}:${TAG}"
        else
            print_error "Failed to build ${DOCKER_REGISTRY}/${service}:${TAG}"
            failed_services+=("$service")
            cd ../..
            continue
        fi
        
        cd ../..
        
        # Scan the image
        if ! scan_image "${DOCKER_REGISTRY}/${service}:${TAG}" "$service"; then
            failed_services+=("$service")
        fi
        
        echo ""
    done
    
    # Summary
    print_info "========================================="
    print_info "SUMMARY"
    print_info "========================================="
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        print_success "All services passed security scan! 🎉"
        return 0
    else
        print_error "The following services failed: ${failed_services[*]}"
        return 1
    fi
}

# Function to get image size
get_image_sizes() {
    print_info "========================================="
    print_info "IMAGE SIZES"
    print_info "========================================="
    
    for service in vote result worker; do
        size=$(docker images "${DOCKER_REGISTRY}/${service}:${TAG}" --format "{{.Size}}")
        print_info "${service}: $size"
    done
}

# Main execution
main() {
    print_info "Starting security scan process..."
    
    # Check prerequisites
    check_trivy
    
    # Update Trivy database
    print_info "Updating Trivy vulnerability database..."
    trivy image --download-db-only
    
    # Build and scan all services
    if build_and_scan_all; then
        get_image_sizes
        print_success "Security scanning completed successfully!"
        exit 0
    else
        print_error "Security scanning failed!"
        exit 1
    fi
}

# Run main function
main
