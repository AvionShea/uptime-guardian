#!/bin/bash

# Automatically grab container name for your app image
CONTAINER_NAME=$(docker ps --filter "ancestor=uptime-guardian:version1.0.0" --format "{{.Names}}" | head -n 1)
URL="http://localhost:3000/healthz"
INTERVAL=30

if [ -z "$CONTAINER_NAME" ]; then
  echo "No running container found for uptime-guardian:version1.0.0"
  exit 1
fi

echo "Monitoring container: $CONTAINER_NAME"

while true; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" $URL)
  if [ "$STATUS" != "200" ]; then
    echo "$(date): App down (status $STATUS). Restarting container..."
    docker restart $CONTAINER_NAME
  else
    echo "$(date): App healthy (status $STATUS)"
  fi
  sleep $INTERVAL
done
