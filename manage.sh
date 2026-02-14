#!/bin/bash

# Saleor Platform Management Script
# This script helps manage docker compose services for development

set -e

COMPOSE_FILE="compose.yml"
COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$COMPOSE_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker compose is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Use 'docker compose' (v2) or 'docker-compose' (v1)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    print_error "Neither 'docker compose' nor 'docker-compose' is available"
    exit 1
fi

# Functions
start_services() {
    print_info "Starting all services..."
    $COMPOSE_CMD up -d
    print_info "Services started. API: http://localhost:28000, Dashboard: http://localhost:29000"
}

stop_services() {
    print_info "Stopping all services..."
    $COMPOSE_CMD down
    print_info "Services stopped"
}

restart_services() {
    print_info "Restarting all services..."
    $COMPOSE_CMD restart
    print_info "Services restarted"
}

rebuild_services() {
    print_info "Rebuilding services (no cache)..."
    $COMPOSE_CMD build --no-cache
    print_info "Services rebuilt"
}

rebuild_dashboard() {
    print_info "Rebuilding dashboard..."
    $COMPOSE_CMD build --no-cache dashboard
    print_info "Dashboard rebuilt. Restarting..."
    $COMPOSE_CMD up -d dashboard
    print_info "Dashboard restarted"
}

rebuild_api() {
    print_info "Rebuilding API..."
    $COMPOSE_CMD build --no-cache api
    print_info "API rebuilt. Restarting..."
    $COMPOSE_CMD up -d api
    print_info "API restarted"
}

rebuild_worker() {
    print_info "Rebuilding worker..."
    $COMPOSE_CMD build --no-cache worker
    print_info "Worker rebuilt. Restarting..."
    $COMPOSE_CMD up -d worker
    print_info "Worker restarted"
}

restart_api() {
    print_info "Restarting API..."
    $COMPOSE_CMD restart api
    print_info "API restarted"
}

restart_worker() {
    print_info "Restarting worker..."
    $COMPOSE_CMD restart worker
    print_info "Worker restarted"
}

restart_dashboard() {
    print_info "Restarting dashboard..."
    $COMPOSE_CMD restart dashboard
    print_info "Dashboard restarted"
}

run_migrations() {
    print_info "Running database migrations..."
    $COMPOSE_CMD run --rm api python3 manage.py migrate
    print_info "Migrations completed"
}

create_superuser() {
    print_info "Creating superuser..."
    $COMPOSE_CMD run --rm api python3 manage.py createsuperuser
    print_info "Superuser creation completed"
}

populate_db() {
    print_info "Populating database with sample data..."
    $COMPOSE_CMD run --rm api python3 manage.py populatedb
    print_info "Database populated"
}

view_logs() {
    SERVICE=${1:-""}
    if [ -z "$SERVICE" ]; then
        print_info "Viewing logs for all services (Ctrl+C to exit)..."
        $COMPOSE_CMD logs -f
    else
        print_info "Viewing logs for $SERVICE (Ctrl+C to exit)..."
        $COMPOSE_CMD logs -f "$SERVICE"
    fi
}

shell_api() {
    print_info "Opening API shell..."
    $COMPOSE_CMD exec api /bin/bash
}

shell_db() {
    print_info "Opening database shell..."
    $COMPOSE_CMD exec db psql -U saleor -d saleor
}

full_reload() {
    print_info "Performing full reload (stop, rebuild, migrate, start)..."
    stop_services
    rebuild_services
    start_services
    sleep 5
    run_migrations
    print_info "Full reload completed"
}

reload_with_migrations() {
    print_info "Restarting services and running migrations..."
    restart_services
    sleep 3
    run_migrations
    print_info "Reload with migrations completed"
}

show_status() {
    print_info "Service status:"
    $COMPOSE_CMD ps
}

show_help() {
    cat << EOF
Saleor Platform Management Script

Usage: ./manage.sh [command] [options]

Commands:
    start               Start all services
    stop                Stop all services
    restart             Restart all services
    rebuild             Rebuild all services (no cache)
    rebuild-dashboard   Rebuild dashboard only
    rebuild-api         Rebuild API only
    rebuild-worker      Rebuild worker only
    restart-api         Restart API service
    restart-worker      Restart worker service
    restart-dashboard   Restart dashboard service
    migrate             Run database migrations
    superuser           Create superuser account
    populate            Populate database with sample data
    logs [service]      View logs (all services or specific service)
    shell-api           Open bash shell in API container
    shell-db            Open PostgreSQL shell
    reload              Full reload (stop, rebuild, migrate, start)
    reload-migrations   Restart services and run migrations
    status              Show service status
    help                Show this help message

Examples:
    ./manage.sh start
    ./manage.sh logs api
    ./manage.sh rebuild-dashboard
    ./manage.sh reload-migrations
    ./manage.sh shell-api

EOF
}

# Main command handler
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    rebuild)
        rebuild_services
        ;;
    rebuild-dashboard)
        rebuild_dashboard
        ;;
    rebuild-api)
        rebuild_api
        ;;
    rebuild-worker)
        rebuild_worker
        ;;
    restart-api)
        restart_api
        ;;
    restart-worker)
        restart_worker
        ;;
    restart-dashboard)
        restart_dashboard
        ;;
    migrate)
        run_migrations
        ;;
    superuser)
        create_superuser
        ;;
    populate)
        populate_db
        ;;
    logs)
        view_logs "$2"
        ;;
    shell-api)
        shell_api
        ;;
    shell-db)
        shell_db
        ;;
    reload)
        full_reload
        ;;
    reload-migrations)
        reload_with_migrations
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

