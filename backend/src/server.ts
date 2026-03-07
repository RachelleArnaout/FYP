import app from "./app";
import { connectDatabase } from "./config/database";
import { environment } from "./config/environment";

async function startServer(): Promise<void> {
  await connectDatabase();

  app.listen(environment.port, () => {
    console.log(`
╔═══════════════════════════════════════════════╗
║       Habit Tracker API Server                ║
╠═══════════════════════════════════════════════╣
║  Port:        ${String(environment.port).padEnd(31)}║
║  Environment: ${environment.nodeEnv.padEnd(31)}║
║  API URL:     http://localhost:${String(environment.port).padEnd(19)}║
╚═══════════════════════════════════════════════╝
    `);
  });
}

startServer().catch((error) => {
  console.error("Failed to start server:", error);
  process.exit(1);
});
