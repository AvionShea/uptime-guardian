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

## Day 1 status

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
    "express": "^5.1.0",
    "nodemon": "^3.1.10"
  },
  "dependencies": {
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

## Day 2 Status

- Containerized the Node.js app using Docker
- Image built from `node:20-slim`
- Confirmed app runs inside container and exposes port 3000

### Run with Docker

```bash
docker build -t uptime-guardian .
docker run -d -p 3000:3000 uptime-guardian
```
