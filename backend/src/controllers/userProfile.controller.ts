import { Response, NextFunction } from "express";
import { UserProfileService } from "../services/userProfile.service";
import { AuthenticatedRequest, ApiResponse } from "../types";

export class UserProfileController {
  /**
   * GET /api/profile
   */
  static async getProfile(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const profile = await UserProfileService.getByUserId(req.userId!);

      res.status(200).json({
        success: true,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/profile
   */
  static async updateProfile(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const profile = await UserProfileService.update(req.userId!, req.body);

      res.status(200).json({
        success: true,
        data: profile,
        message: "Profile updated successfully.",
      });
    } catch (error) {
      next(error);
    }
  }
}
