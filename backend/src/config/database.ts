import mongoose from "mongoose";
import { environment } from "./environment";

export async function connectDatabase(): Promise<void> {
  try {
    await mongoose.connect(environment.mongodbUri);
    console.log("✅ Connected to MongoDB");
  } catch (error) {
    console.error("❌ MongoDB connection error:", error);
    process.exit(1);
  }

  mongoose.connection.on("error", (error) => {
    console.error("MongoDB error:", error);
  });

  mongoose.connection.on("disconnected", () => {
    console.warn("MongoDB disconnected");
  });
}

export async function disconnectDatabase(): Promise<void> {
  await mongoose.disconnect();
  console.log("MongoDB disconnected");
}
