import { Response, NextFunction } from "express";
import { HabitService } from "../services/habit.service";
import { AuthenticatedRequest, ApiResponse } from "../types";

export class HabitController {
  /**
   * GET /api/habits
   */
  static async getAll(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habits = await HabitService.getAllByUserId(req.userId!);

      res.status(200).json({
        success: true,
        data: habits,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/habits/active
   */
  static async getActive(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habits = await HabitService.getActiveByUserId(req.userId!);

      res.status(200).json({
        success: true,
        data: habits,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/habits/life-area/:lifeAreaId
   */
  static async getByLifeArea(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habits = await HabitService.getByLifeArea(
        req.userId!,
        req.params.lifeAreaId as string,
      );

      res.status(200).json({
        success: true,
        data: habits,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/habits/:id
   */
  static async getById(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habit = await HabitService.getById(
        req.userId!,
        req.params.id as string,
      );

      res.status(200).json({
        success: true,
        data: habit,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/habits
   */
  static async create(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habit = await HabitService.create(req.userId!, req.body);

      res.status(201).json({
        success: true,
        data: habit,
        message: "Habit created successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/habits/:id
   */
  static async update(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habit = await HabitService.update(
        req.userId!,
        req.params.id as string,
        req.body,
      );

      res.status(200).json({
        success: true,
        data: habit,
        message: "Habit updated successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/habits/:id
   */
  static async delete(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      await HabitService.delete(req.userId!, req.params.id as string);

      res.status(200).json({
        success: true,
        message: "Habit deleted successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/habits/:id/completion
   */
  static async toggleCompletion(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const habit = await HabitService.toggleCompletion(
        req.userId!,
        req.params.id as string,
        req.body,
      );

      res.status(200).json({
        success: true,
        data: habit,
        message: "Habit completion updated.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/habits/:id/consistency
   */
  static async getConsistency(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const days = parseInt(req.query.days as string) || 7;
      const stats = await HabitService.getConsistencyRate(
        req.userId!,
        req.params.id as string,
        days,
      );

      res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/habits/analytics/overview
   */
  static async getAnalytics(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const days = parseInt(req.query.days as string) || 7;
      const analytics = await HabitService.getAnalytics(req.userId!, days);

      res.status(200).json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      next(error);
    }
  }
}
