import { Request, Response, NextFunction } from "express";
import { ApiResponse } from "../types";

export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export function errorHandler(
  err: Error | AppError,
  _req: Request,
  res: Response<ApiResponse>,
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
    });
    return;
  }

  // Mongoose validation error
  if (err.name === "ValidationError") {
    const messages = Object.values((err as any).errors).map(
      (e: any) => e.message,
    );
    res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: messages,
    });
    return;
  }

  // Mongoose duplicate key error
  if ((err as any).code === 11000) {
    const field = Object.keys((err as any).keyValue || {})[0];
    res.status(409).json({
      success: false,
      message: `${field || "Field"} already exists.`,
    });
    return;
  }

  // Mongoose cast error (invalid ObjectId)
  if (err.name === "CastError") {
    res.status(400).json({
      success: false,
      message: "Invalid ID format.",
    });
    return;
  }

  console.error("Unhandled error:", err);

  res.status(500).json({
    success: false,
    message: "Internal server error.",
  });
}
