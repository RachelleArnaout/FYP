import { Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { environment } from "../config/environment";
import { AuthenticatedRequest } from "../types";

interface JwtPayload {
  userId: string;
  iat: number;
  exp: number;
}

export function authenticate(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({
      success: false,
      message: "Authentication required. Please provide a valid token.",
    });
    return;
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, environment.jwtSecret) as JwtPayload;
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: "Invalid or expired token.",
    });
  }
}
