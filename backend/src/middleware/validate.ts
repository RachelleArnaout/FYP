import { Request, Response, NextFunction } from "express";
import { validationResult } from "express-validator";
import { ApiResponse } from "../types";

export function validateRequest(
  req: Request,
  res: Response<ApiResponse>,
  next: NextFunction,
): void {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const errorMessages = errors.array().map((err) => err.msg as string);
    res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: errorMessages,
    });
    return;
  }

  next();
}
