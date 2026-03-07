import express from "express";
import cors from "cors";
import morgan from "morgan";
import routes from "./routes";
import { errorHandler } from "./middleware/errorHandler";
import { environment } from "./config/environment";

const app = express();

// ─── Global Middleware ───────────────────────────────────────────────────────

app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

if (environment.nodeEnv === "development") {
  app.use(morgan("dev"));
}

// ─── Health Check ────────────────────────────────────────────────────────────

app.get("/api/health", (_req, res) => {
  res.json({
    success: true,
    message: "Habit Tracker API is running",
    environment: environment.nodeEnv,
    timestamp: new Date().toISOString(),
  });
});

// ─── API Routes ──────────────────────────────────────────────────────────────

app.use("/api", routes);

// ─── 404 Handler ─────────────────────────────────────────────────────────────

app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found.",
  });
});

// ─── Error Handler ───────────────────────────────────────────────────────────

app.use(errorHandler);

export default app;
