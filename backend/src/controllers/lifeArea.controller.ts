import { Response, NextFunction } from "express";
import { LifeAreaService } from "../services/lifeArea.service";
import { AuthenticatedRequest, ApiResponse } from "../types";

export class LifeAreaController {
  /**
   * GET /api/life-areas
   */
  static async getAll(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const areas = await LifeAreaService.getAllByUserId(req.userId!);

      res.status(200).json({
        success: true,
        data: areas,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/life-areas/active
   */
  static async getActive(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const areas = await LifeAreaService.getActiveByUserId(req.userId!);

      res.status(200).json({
        success: true,
        data: areas,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/life-areas/:id
   */
  static async getById(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const area = await LifeAreaService.getById(
        req.userId!,
        req.params.id as string,
      );

      res.status(200).json({
        success: true,
        data: area,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/life-areas
   */
  static async create(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const area = await LifeAreaService.create(req.userId!, req.body);

      res.status(201).json({
        success: true,
        data: area,
        message: "Life area created successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/life-areas/:id
   */
  static async update(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const area = await LifeAreaService.update(
        req.userId!,
        req.params.id as string,
        req.body,
      );

      res.status(200).json({
        success: true,
        data: area,
        message: "Life area updated successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /api/life-areas/:id/toggle
   */
  static async toggleActive(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const area = await LifeAreaService.toggleActive(
        req.userId!,
        req.params.id as string,
      );

      res.status(200).json({
        success: true,
        data: area,
        message: `Life area ${area.isActive ? "activated" : "deactivated"}.`,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/life-areas/:id
   */
  static async delete(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      await LifeAreaService.delete(req.userId!, req.params.id as string);

      res.status(200).json({
        success: true,
        message: "Life area deleted successfully.",
      });
    } catch (error) {
      next(error);
    }
  }
}
