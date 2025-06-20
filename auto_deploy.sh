#!/bin/bash


echo "Pulling latest images..."
docker-compose pull

echo "Starting containers..."
docker-compose up -d

echo "Waiting 60 seconds for containers to start and stabilize..."
sleep 60

# Check health of each container in docker-compose.yml
services=("backend")  # Update with your service names

unhealthy_found=0

for service in "${services[@]}"; do
    container_id=$(docker-compose ps -q $service)
    if [ -z "$container_id" ]; then
        echo "Container for service '$service' not found."
        unhealthy_found=1
        continue
    fi

    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id" 2>/dev/null)

    if [ "$health_status" != "healthy" ]; then
        echo "⚠️ Service '$service' is unhealthy or status is '$health_status'!"
        unhealthy_found=1
    else
        echo "✅ Service '$service' is healthy."
    fi
done

if [ $unhealthy_found -eq 1 ]; then
    echo "One or more services are unhealthy. Please check logs."
    # You can add notifications here (email, Slack, etc.)
else
    echo "All services are healthy. Deployment successful!"
fi
