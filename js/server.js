const express = require("express");
const app = express();
const morgan = require("morgan");
const client = require("prom-client");

const PORT = process.env.PORT || 3000;

//Request Logging
app.use(morgan(":method :url :status :response-time ms"));

// Health endpoint for monitoring
app.get("/healthz", (req, res) => {
    res.status(200).json({ status: "ok", uptime: process.uptime() });
});

//Home Route
app.get("/", (req, res) => {
    res.type("text").send("Uptime Guardian service is running.");
});

//Prometheus Setup
const register = new client.Registry();
client.collectDefaultMetrics({ register });

//Custom Metrics
const httpRequestCounter = new client.Counter({
    name: "http_request_total",
    help: "Total number of HTTP requests",
    labelNames: ["method", "route", "status"],
    registers: [register]
});

const httpRequestDuration = new client.Histogram({
    name: "http_request_duration_seconds",
    help: "Duration of HTTP requests in seconds",
    labelNames: ["method", "route", "status"],
    buckets: [0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
    registers: [register]
});

// Timing and counting middleware
app.use((req, res, next) => {
    const end = httpRequestDuration.startTimer({ method: req.method, route: req.path });
    res.on("finish", () => {
        end({ status: String(res.statusCode) });
        httpRequestCounter.inc({ method: req.method, route: req.path, status: String(res.statusCode) });
    });
    next();
});

// Metrics Endpoint
app.get("/metrics", async (_req, res) => {
    res.set("Content-Type", register.contentType);
    res.end(await register.metrics());
});

app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
});