#!/bin/bash

# Build and Test Secure Voting App
# This script builds, tests, and optionally publishes the hardened container images

set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY:-roxsross}"
TAG="${TAG:-secure}"
PUSH_IMAGES="${PUSH_IMAGES:-false}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================${NC}"
}

# Function to build a single service
build_service() {
    local service=$1
    local image_name="${DOCKER_REGISTRY}/${service}:${TAG}"
    
    print_header "Building $service service"
    
    cd "roxs-voting-app/$service"
    
    print_info "Building image: $image_name"
    
    if docker build -t "$image_name" . ; then
        print_success "Successfully built $image_name"
        cd ../..
        return 0
    else
        print_error "Failed to build $image_name"
        cd ../..
        return 1
    fi
}

# Function to inspect image
inspect_image() {
    local image_name=$1
    local service=$2
    
    print_header "Inspecting $service image"
    
    # Get image size
    local size=$(docker images "$image_name" --format "{{.Size}}")
    print_info "Image size: $size"
    
    # Check if size is under 100MB
    local size_mb=$(docker images "$image_name" --format "{{.Size}}" | sed 's/MB//' | sed 's/GB/*1024/' | bc 2>/dev/null || echo "999")
    if (( $(echo "$size_mb < 100" | bc -l 2>/dev/null || echo "0") )); then
        print_success "Image size is under 100MB target ✅"
    else
        print_warning "Image size exceeds 100MB target ⚠️"
    fi
    
    # Show image layers
    print_info "Image layers:"
    docker history "$image_name" --no-trunc --format "table {{.CreatedBy}}\t{{.Size}}" | head -10
    
    echo ""
}

# Function to test image runtime
test_image_runtime() {
    local service=$1
    local image_name="${DOCKER_REGISTRY}/${service}:${TAG}"
    local container_name="test_${service}_secure"
    
    print_header "Testing $service runtime"
    
    # Remove existing test container if exists
    docker rm -f "$container_name" 2>/dev/null || true
    
    # Run container based on service
    case $service in
        vote)
            print_info "Starting vote service on port 5000..."
            docker run -d --name "$container_name" \
                -p 5000:80 \
                -e REDIS_HOST=redis \
                "$image_name"
            ;;
        result)
            print_info "Starting result service on port 5001..."
            docker run -d --name "$container_name" \
                -p 5001:3000 \
                "$image_name"
            ;;
        worker)
            print_info "Starting worker service..."
            docker run -d --name "$container_name" \
                -p 9000:3000 \
                "$image_name"
            ;;
    esac
    
    # Wait for container to start
    sleep 5
    
    # Check container is running
    if docker ps | grep -q "$container_name"; then
        print_success "Container is running ✅"
        
        # Check container user
        local user=$(docker exec "$container_name" whoami 2>/dev/null || echo "unknown")
        print_info "Running as user: $user"
        
        if [ "$user" != "root" ]; then
            print_success "Container is NOT running as root ✅"
        else
            print_error "Container is running as root ❌"
        fi
        
        # Show resource usage
        print_info "Resource usage:"
        docker stats --no-stream "$container_name" --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
        
        # Show logs
        print_info "Recent logs:"
        docker logs "$container_name" --tail 10
        
    else
        print_error "Container failed to start ❌"
        docker logs "$container_name"
        return 1
    fi
    
    # Cleanup
    docker rm -f "$container_name"
    
    echo ""
}

# Function to push image to registry
push_image() {
    local image_name=$1
    local service=$2
    
    print_header "Pushing $service to Docker Hub"
    
    if [ "$PUSH_IMAGES" = "true" ]; then
        print_info "Pushing $image_name..."
        
        if docker push "$image_name"; then
            print_success "Successfully pushed $image_name ✅"
        else
            print_error "Failed to push $image_name ❌"
            return 1
        fi
    else
        print_warning "Skipping push (set PUSH_IMAGES=true to push)"
    fi
    
    echo ""
}

# Function to show summary
show_summary() {
    print_header "SUMMARY"
    
    echo ""
    print_info "Built images:"
    docker images | grep -E "(REPOSITORY|${DOCKER_REGISTRY}.*${TAG})"
    
    echo ""
    print_info "Total size of all images:"
    docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep "$TAG"
    
    echo ""
    print_success "🎉 All images built successfully!"
    
    echo ""
    print_info "Next steps:"
    echo "  1. Run security scan: ./scripts/security-scan.sh"
    echo "  2. Test full stack: docker-compose -f docker-compose.yml up"
    echo "  3. Push to registry: PUSH_IMAGES=true ./scripts/build-secure.sh"
    echo "  4. Update hardening-report.md with results"
}

# Main execution
main() {
    local services=("vote" "result" "worker")
    local failed_services=()
    
    print_header "Building Secure Voting App Images"
    
    # Build all services
    for service in "${services[@]}"; do
        if ! build_service "$service"; then
            failed_services+=("$service")
        fi
    done
    
    # Check if any builds failed
    if [ ${#failed_services[@]} -gt 0 ]; then
        print_error "Failed to build: ${failed_services[*]}"
        exit 1
    fi
    
    # Inspect images
    for service in "${services[@]}"; do
        inspect_image "${DOCKER_REGISTRY}/${service}:${TAG}" "$service"
    done
    
    # Test images (basic runtime test)
    print_warning "Skipping runtime tests (would require full stack)"
    print_info "To test full stack, run: docker-compose up -d"
    
    # Push images if requested
    if [ "$PUSH_IMAGES" = "true" ]; then
        # Check if logged in to Docker Hub
        if ! docker info | grep -q "Username"; then
            print_warning "Not logged in to Docker Hub"
            print_info "Please run: docker login"
            PUSH_IMAGES=false
        else
            for service in "${services[@]}"; do
                push_image "${DOCKER_REGISTRY}/${service}:${TAG}" "$service"
            done
        fi
    fi
    
    # Show summary
    show_summary
}

# Check if help is requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Build and test hardened Docker images for Voting App"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_REGISTRY     Docker registry prefix (default: roxsross)"
    echo "  TAG                 Image tag (default: secure)"
    echo "  PUSH_IMAGES         Push to registry after build (default: false)"
    echo ""
    echo "Examples:"
    echo "  # Build images"
    echo "  $0"
    echo ""
    echo "  # Build and push to Docker Hub"
    echo "  PUSH_IMAGES=true $0"
    echo ""
    echo "  # Build with custom registry"
    echo "  DOCKER_REGISTRY=myuser TAG=v1.0-secure $0"
    exit 0
fi

# Run main function
main
