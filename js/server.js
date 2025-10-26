const express = require("express");
const app = express();

const PORT = process.env.PORT || 3000;

//Request Logging
app.use((req, res, next) => {
    const start = Date.now();
    res.on("finish", () => {
        const ms = Date.now() - start;
        console.log(`${req.method} ${req.originalUrl} ${res.statusCode} ${ms}ms`)
    });
    next();
});

// Health emdpoint for monitoring
app.get("/healthz", (req, res) => {
    res.status(200).json({ status: "ok", uptime: process.uptime() });
});

//Home Route
app.get("/", (req, res) => {
    res.type("text").send("Uptime Guardian service is running.");
});

app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
});