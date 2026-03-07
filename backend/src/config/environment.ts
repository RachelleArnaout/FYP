import dotenv from "dotenv";

dotenv.config();

export const environment = {
  port: parseInt(process.env.PORT || "3000", 10),
  mongodbUri:
    process.env.MONGODB_URI || "mongodb://localhost:27017/habit-tracker",
  jwtSecret: process.env.JWT_SECRET || "fallback-secret-key",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  nodeEnv: process.env.NODE_ENV || "development",
} as const;
