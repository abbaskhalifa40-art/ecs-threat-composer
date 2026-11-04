const express = require("express");
const path = require("path");

const app = express();
const port = process.env.PORT || 3000;

/**
 * Health check
 * ECS + Load Balancer use this to know if the app is alive
 */
app.get("/health", (req, res) => {
  res.status(200).send("ok");
});

/**
 * When someone visits the domain root (/),
 * send them to the dashboard so they SEE something
 */
app.get("/", (req, res) => {
  res.redirect("/workspaces/default/dashboard");
});

/**
 * Serve the built React app
 */
app.use(express.static(path.join(__dirname, "build")));

/**
 * React router fallback
 */
app.get(/.*/, (req, res) => {
    res.sendFile(path.join(__dirname, "build", "index.html"));
  });
  
app.listen(port, "0.0.0.0", () => {
  console.log(`Threat Composer running on port ${port}`);
});
