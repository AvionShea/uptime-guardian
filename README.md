# Uptime Guardian

A tiny Node.js service that we will monitor and harden over one week to simulate SRE work.

## Project Goal

This project, Uptime Guardian is a small but realistic reliability system that includes:

- Containerization (Docker)
- Monitoring with Prometheus + Grafana
- Auto-recovery automation
- Postmortem reporting

## Tech Stack

**Languages & Frameworks**

- Node.js
- Express.js

**Developer Tools**

- npm (package management)
- nodemon (hot reload for development)
- Git & GitHub (version control and collaboration)

## Setup & Environment Familiarization

- Node.js service with Express
- Health endpoint at `/healthz`
- Local dev with nodemon

## Run

Create Project

```bash
mkdir <directory name>
cd <directory name>
npm init -y
npm i express --save-d nodemon dotenv
```

Create .env file

```bash
touch .env
```

Create .gitignore - add node_modules, .env, DS_store

```bash
touch .gitignore
```

Create server.js file

```js
const express = require("express");
const app = express();

const PORT = process.env.PORT || 3000;

// Request logging
app.use((req, res, next) => {
  const start = Date.now();
  res.on("finish", () => {
    const ms = Date.now() - start;
    console.log(`${req.method} ${req.originalUrl} ${res.statusCode} ${ms}ms`);
  });
  next();
});

// Health endpoint for monitoring
app.get("/healthz", (req, res) => {
  res.status(200).json({ status: "ok", uptime: process.uptime() });
});

// Home route
app.get("/", (req, res) => {
  res.type("text").send("Uptime Guardian service is running.");
});

app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
```

Update package.json scripts:

```json
{
  "name": "uptime-guardian",
  "version": "1.0.0",
  "description": "",
  "main": "js/server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon --quiet server.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "commonjs",
  "devDependencies": {
    "nodemon": "^3.1.10"
  },
  "dependencies": {
    "express": "^5.1.0",
    "dotenv": "^17.2.3"
  }
}
```

## Verify

```bash
npm run dev
```

CLI check

```bash
curl -i http://localhost:3000/healthz
```

After running the app, verify these endpoints:

You should see HTTP 200 and a small JSON payload.

- Visit: http://localhost:3000 → should return a simple text message

- Visit: http://localhost:3000/healthz → should return a JSON response like:

```json
{ "status": "ok", "uptime": 12.345 }
```

## Containerization

Goal: Package the app in Docker to ensure reliability and portability.

- Containerized the Node.js app using Docker - Dockerfile defines a reproducible environment
- Image built from `node:20-slim`
- Confirmed app runs inside container and exposes port 3000

### Run with Docker

```bash
docker build -t uptime-guardian .
docker run -d -p 3000:3000 uptime-guardian
```

Create `Dockerfile`

```dockerfile
# Use an official Node.js image as the base
FROM node:20-slim

# Create and set working directory inside container
WORKDIR /app

# Copy dependency files first (for caching)
COPY package*.json ./

# Install dependencies (omit dev dependencies)
RUN npm install --omit=dev

# Copy the rest of the app
COPY . .

# Expose the app port
EXPOSE 3000

# Start the app
CMD ["node", "<sever file location>"]
```

Create `.dockerignore`

```bash
node_modules
.git
.env
.DS_Store
```

Build and Run

```bash
# Build the image with a semantic version tag
docker build -t uptime-guardian:version1.0.0 .

# Run container (host port 3000 → container port 3000)
docker run -d -p 3000:3000 --name uptime-guardian uptime-guardian:version1.0.0

```

`npm install --omit=dev` keeps the image lightweight.

- if an issue occurs, ensure express is listed under dependencies in the `package-lock.json` file.

## Monitoring & Logging

Goal: add observability using Prometheus + Grafana to track uptime, latency, and usage.

- Added Prometheus metrics `(/metrics)` and structured request logs with `morgan`.
- Docker Compose orchestrates App + Prometheus + Grafana together.
- Environment variables are handled securely with `.env`.
- You can visualize live request rate and latency directly in Grafana.

### Install Dependencies

```bash
npm install prom-client morgan
```

Update `server.js`

```js
const express = require("express");
const morgan = require("morgan");
const client = require("prom-client");
const app = express();
const PORT = process.env.PORT || 3000;

// Request logging
app.use(morgan(":method :url :status :response-time ms"));

// Prometheus registry and default metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestCounter = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
  registers: [register],
});

// Timing middleware
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({
    method: req.method,
    route: req.path,
  });
  res.on("finish", () => {
    end({ status: String(res.statusCode) });
    httpRequestCounter.inc({
      method: req.method,
      route: req.path,
      status: String(res.statusCode),
    });
  });
  next();
});

// Metrics endpoint
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// Health + home routes
app.get("/healthz", (_req, res) =>
  res.status(200).json({ status: "ok", uptime: process.uptime() })
);
app.get("/", (_req, res) =>
  res.type("text").send("Uptime Guardian service is running.")
);
app.listen(PORT, "0.0.0.0", () =>
  console.log(`Server listening on http://localhost:${PORT}`)
);
```

### Prometheus Configuration - `prometheus.yml`

```yaml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: "uptime-guardian"
    static_configs:
      - targets: ["app:3000"]
```

### Safe - `docker-compose.yml`

```yaml
services:
  app:
    image: ${APP_IMAGE:-uptime-guardian:version1.0.0}
    container_name: ug-app
    ports:
      - "${HOST_APP_PORT:-3000}:${APP_PORT:-3000}"
    environment:
      - PORT=${APP_PORT:-3000}
      - RUNTIME=docker
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    container_name: ug-prom
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command: ["--config.file=/etc/prometheus/prometheus.yml"]
    ports:
      - "${PROMETHEUS_PORT:-9090}:9090"
    depends_on:
      - app
    restart: unless-stopped

  grafana:
    image: grafana/grafana-oss:latest
    container_name: ug-grafana
    ports:
      - "${GRAFANA_PORT:-3001}:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
    restart: unless-stopped

volumes:
  grafana-data:
```

.env.example

```bash
APP_IMAGE=uptime-guardian:version1.0.0
APP_PORT=3000
HOST_APP_PORT=3000
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
GF_SECURITY_ADMIN_USER=admin_username_here
GF_SECURITY_ADMIN_PASSWORD=new_password_here
```

### Run the Full Stack

```bash
cp .env.example .env
docker compose up -d
```

### Verify

| Component  | URL                                                            | Default                                             |
| ---------- | -------------------------------------------------------------- | --------------------------------------------------- |
| App        | [http://localhost:3000](http://localhost:3000)                 | responds with “Uptime Guardian service is running.” |
| Health     | [http://localhost:3000/healthz](http://localhost:3000/healthz) | JSON status                                         |
| Metrics    | [http://localhost:3000/metrics](http://localhost:3000/metrics) | Prometheus text format                              |
| Prometheus | [http://localhost:9090](http://localhost:9090)                 | Target: `app:3000`                                  |
| Grafana    | [http://localhost:3001](http://localhost:3001)                 | Login: `admin` / your password                      |
