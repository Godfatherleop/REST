#!/bin/bash

set -e  # Exit immediately on error

echo "🔄 Cloning the latest repository..."
gh repo clone Godfatherleop/REST || {
    echo "❌ Failed to clone repository. Make sure GitHub CLI is installed and authenticated."
    exit 1
}

cd REST || {
    echo "❌ Failed to enter REST directory."
    exit 1
}

echo "📦 Pulling latest Docker images..."
docker-compose pull

echo "🚀 Starting Docker containers..."
docker-compose up -d

echo "⏳ Waiting 60 seconds for containers to stabilize..."
sleep 60

# Health check logic
services=("backend" "frontend")  # Add more services here as needed

unhealthy_found=0

echo "🔍 Checking health status of services..."
for service in "${services[@]}"; do
    container_id=$(docker-compose ps -q "$service")

    if [ -z "$container_id" ]; then
        echo "❌ Container for service '$service' not found."
        unhealthy_found=1
        continue
    fi

    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "unknown")

    if [ "$health_status" != "healthy" ]; then
        echo "⚠️ Service '$service' is unhealthy or status is '$health_status'"
        unhealthy_found=1
    else
        echo "✅ Service '$service' is healthy."
    fi
done

echo

if [ "$unhealthy_found" -eq 1 ]; then
    echo "❗ One or more services are unhealthy. Check container logs using:"
    echo "   docker-compose logs -f"
    exit 1
else
    echo "✅ All services are healthy. Deployment successful!"
fi
