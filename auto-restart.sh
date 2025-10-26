#!/bin/bash

# Automatically grab container name for your app image
CONTAINER_NAME=$(docker ps --filter "ancestor=uptime-guardian:version1.0.0" --format "{{.Names}}" | head -n 1)
URL="http://localhost:3000/healthz"
INTERVAL=60 # seconds between checks
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/health-monitor.log"
MAX_SIZE=$((5 * 1024 * 1024)) # 5 MB

mkdir -p "$LOG_DIR"

if [ -z "$CONTAINER_NAME" ]; then
  echo "No running container found for uptime-guardian:version1.0.0"
  exit 1
fi

echo "Monitoring container: $CONTAINER_NAME"
echo "Logs saved to: $LOG_FILE"

# Rotate log if too large
rotate_if_needed() {
  if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE")" -ge "$MAX_SIZE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d-%H%M%S)"
    : > "$LOG_FILE"
  fi
}

# Function to write structured JSON logs
log_json() {
  local level="$1"
  local message="$2"
  local status="$3"
  local ts
  ts="$(date -Iseconds)"
  printf '{ "ts":"%s", "level":"%s", "container":"%s", "url":"%s", "msg":"%s", "status":"%s" }\n' \
    "$ts" "$level" "$CONTAINER_NAME" "$URL" "$message" "$status" | tee -a "$LOG_FILE"
}

# Health check loop
while true; do
  rotate_if_needed
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || echo "000")

  if [ "$STATUS" != "200" ]; then
    log_json "warn" "App down, restarting container..." "$STATUS"
    docker restart "$CONTAINER_NAME" >/dev/null 2>&1
    log_json "info" "Container restarted successfully" "$STATUS"
  else
    log_json "info" "App healthy" "$STATUS"
  fi

  sleep "$INTERVAL"
done