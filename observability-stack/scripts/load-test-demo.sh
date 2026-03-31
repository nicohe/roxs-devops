#!/bin/bash

################################################################################
# Load Test Demo Script for Voting App
# Purpose: Generate realistic voting traffic to demonstrate observability features
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VOTE_URL="${VOTE_URL:-http://localhost:30080}"
RESULT_URL="${RESULT_URL:-http://localhost:30081}"
DURATION="${DURATION:-300}"  # 5 minutes default
USERS="${USERS:-10}"         # Concurrent users
VOTE_RATE="${VOTE_RATE:-5}"  # Votes per second per user

# Function to print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║       Voting App - Load Test Demo                         ║"
echo "║       Observability Stack Traffic Generator               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verify services are accessible
log_info "Verifying services are accessible..."

if ! curl -sf "${VOTE_URL}/healthz" > /dev/null 2>&1; then
    log_error "Vote service not accessible at ${VOTE_URL}"
    log_info "Try: kubectl port-forward -n voting-app svc/vote 30080:80 &"
    exit 1
fi
log_success "Vote service is UP ✓"

if ! curl -sf "${RESULT_URL}/healthz" > /dev/null 2>&1; then
    log_warning "Result service not accessible at ${RESULT_URL}"
    log_info "Try: kubectl port-forward -n voting-app svc/result 30081:80 &"
fi

echo ""
log_info "Load Test Configuration:"
echo "  - Target URL: ${VOTE_URL}"
echo "  - Duration: ${DURATION} seconds"
echo "  - Concurrent Users: ${USERS}"
echo "  - Vote Rate: ${VOTE_RATE} votes/sec/user"
echo "  - Total Rate: ~$((USERS * VOTE_RATE)) votes/sec"
echo ""

# Function to simulate a single user voting
simulate_voter() {
    local user_id=$1
    local end_time=$((SECONDS + DURATION))
    local sleep_time=$(echo "scale=2; 1 / ${VOTE_RATE}" | bc)
    
    while [ $SECONDS -lt $end_time ]; do
        # Randomly choose between cats (a) and dogs (b) with 60/40 split
        if [ $((RANDOM % 100)) -lt 60 ]; then
            vote="a"
        else
            vote="b"
        fi
        
        # Submit vote (silently, capture status code)
        status_code=$(curl -sf -o /dev/null -w "%{http_code}" \
            -X POST \
            -d "vote=${vote}" \
            "${VOTE_URL}/" 2>/dev/null || echo "000")
        
        if [ "$status_code" != "200" ] && [ "$status_code" != "302" ]; then
            log_error "User $user_id: Vote failed with status $status_code"
        fi
        
        # Random sleep to simulate human behavior
        sleep_variance=$(echo "scale=2; ${sleep_time} * (0.8 + ($RANDOM % 40) / 100)" | bc)
        sleep "${sleep_variance}"
    done
}

# Function to simulate result page viewers
simulate_viewer() {
    local viewer_id=$1
    local end_time=$((SECONDS + DURATION))
    
    while [ $SECONDS -lt $end_time ]; do
        # View results page
        curl -sf "${RESULT_URL}/" > /dev/null 2>&1 || true
        
        # Random interval between 2-8 seconds
        sleep $((2 + RANDOM % 7))
    done
}

log_info "Starting load test..."
log_warning "Press Ctrl+C to stop early"
echo ""

# Start voters in background
voter_pids=()
for i in $(seq 1 $USERS); do
    simulate_voter $i &
    voter_pids+=($!)
done

# Start fewer viewers (20% of voters)
viewer_count=$((USERS / 5))
if [ $viewer_count -lt 1 ]; then
    viewer_count=1
fi

viewer_pids=()
for i in $(seq 1 $viewer_count); do
    simulate_viewer $i &
    viewer_pids+=($!)
done

log_success "Started ${USERS} voters and ${viewer_count} viewers"
log_info "Load test running for ${DURATION} seconds..."

# Progress indicator
progress_interval=10
elapsed=0
while [ $elapsed -lt $DURATION ]; do
    sleep $progress_interval
    elapsed=$((elapsed + progress_interval))
    percentage=$((elapsed * 100 / DURATION))
    log_info "Progress: ${elapsed}/${DURATION}s (${percentage}%)"
done

# Wait for all background processes to finish
log_info "Waiting for processes to complete..."
for pid in "${voter_pids[@]}" "${viewer_pids[@]}"; do
    wait $pid 2>/dev/null || true
done

log_success "Load test completed!"
echo ""

# Summary
log_info "═══════════════════════════════════════════════════════════"
log_info "Load Test Summary"
log_info "═══════════════════════════════════════════════════════════"
echo ""
echo "  Duration: ${DURATION}s"
echo "  Total Votes Attempted: ~$((USERS * VOTE_RATE * DURATION))"
echo "  Concurrent Users: ${USERS}"
echo "  Result Page Views: ~$((viewer_count * DURATION / 5))"
echo ""

log_info "Next Steps:"
echo ""
echo "  1. 📊 View Metrics in Grafana:"
echo "     http://localhost:30091"
echo "     Dashboard: Voting App - Business Dashboard"
echo ""
echo "  2. 🔍 Check Prometheus Targets:"
echo "     http://localhost:30090/targets"
echo ""
echo "  3. 🕸️ View Traces in Jaeger:"
echo "     http://localhost:16686"
echo "     Service: vote-service"
echo ""
echo "  4. 📋 Check Logs in Kibana:"
echo "     http://localhost:30093"
echo "     Query: kubernetes.namespace:\"voting-app\""
echo ""
echo "  5. 🚨 View Alerts in Prometheus:"
echo "     http://localhost:30090/alerts"
echo ""

log_success "Demo traffic generation complete! Check your observability dashboards."
echo ""
