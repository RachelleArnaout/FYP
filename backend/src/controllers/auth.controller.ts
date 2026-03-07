import { Request, Response, NextFunction } from "express";
import { AuthService } from "../services/auth.service";
import { AuthenticatedRequest, ApiResponse, IAuthResponse } from "../types";

export class AuthController {
  /**
   * POST /api/auth/register
   */
  static async register(
    req: Request,
    res: Response<ApiResponse<IAuthResponse>>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const { name, email, password } = req.body;
      const result = await AuthService.register({ name, email, password });

      res.status(201).json({
        success: true,
        data: result,
        message: "Account created successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/login
   */
  static async login(
    req: Request,
    res: Response<ApiResponse<IAuthResponse>>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const { email, password } = req.body;
      const result = await AuthService.login({ email, password });

      res.status(200).json({
        success: true,
        data: result,
        message: "Login successful.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/auth/me
   */
  static async getMe(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const user = await AuthService.getCurrentUser(req.userId!);

      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/auth/complete-onboarding
   */
  static async completeOnboarding(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const user = await AuthService.completeOnboarding(req.userId!);

      res.status(200).json({
        success: true,
        data: user,
        message: "Onboarding completed.",
      });
    } catch (error) {
      next(error);
    }
  }
}
