import { Response, NextFunction } from "express";
import { AIService } from "../services/ai.service";
import { HabitService } from "../services/habit.service";
import { LifeArea } from "../models";
import {
  AuthenticatedRequest,
  ApiResponse,
  IApproveAIHabitsInput,
} from "../types";
import { AppError } from "../middleware/errorHandler";

export class AIHabitController {
  /**
   * POST /api/habits/ai/generate
   * Generate AI habit suggestions based on user profile.
   */
  static async generate(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const { focusAreas, count } = req.body;

      const result = await AIService.generateHabits(
        req.userId!,
        focusAreas,
        count,
      );

      res.status(200).json({
        success: true,
        data: result,
        message: "Habit suggestions generated successfully.",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/habits/ai/approve
   * Save user-approved AI-generated habits.
   */
  static async approve(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const { habits } = req.body as IApproveAIHabitsInput;

      if (!habits || !Array.isArray(habits) || habits.length === 0) {
        throw new AppError(
          "Please provide at least one habit to approve.",
          400,
        );
      }

      if (habits.length > 10) {
        throw new AppError("Cannot approve more than 10 habits at once.", 400);
      }

      // Validate that all lifeAreaIds belong to the user
      const userAreas = await LifeArea.find({ userId: req.userId! });
      const validAreaIds = new Set(userAreas.map((a) => a._id.toString()));

      for (const habit of habits) {
        if (!validAreaIds.has(habit.lifeAreaId)) {
          throw new AppError(`Invalid life area ID: ${habit.lifeAreaId}`, 400);
        }
      }

      // Create all approved habits
      const createdHabits = [];
      for (const habit of habits) {
        const created = await HabitService.create(req.userId!, {
          name: habit.name,
          description: habit.description,
          lifeAreaId: habit.lifeAreaId,
          goalStatement: habit.goalStatement,
          valueAlignment: habit.valueAlignment,
          targetFrequency: habit.targetFrequency,
          durationMinutes: habit.durationMinutes,
          difficultyLevel: habit.difficultyLevel,
          isBuildingHabit: habit.isBuildingHabit,
        });
        createdHabits.push(created);
      }

      res.status(201).json({
        success: true,
        data: createdHabits,
        message: `${createdHabits.length} habit(s) added successfully.`,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/habits/ai/motivational
   * Generate a personalized motivational message based on user progress.
   */
  static async getMotivationalMessage(
    req: AuthenticatedRequest,
    res: Response<ApiResponse>,
    next: NextFunction,
  ): Promise<void> {
    try {
      const {
        overallConsistency,
        completedToday,
        totalToday,
        currentStreaks,
        totalActiveHabits,
      } = req.body;

      const result = await AIService.generateMotivationalMessage(req.userId!, {
        overallConsistency: Number(overallConsistency) || 0,
        completedToday: Number(completedToday) || 0,
        totalToday: Number(totalToday) || 0,
        currentStreaks: Array.isArray(currentStreaks) ? currentStreaks : [],
        totalActiveHabits: Number(totalActiveHabits) || 0,
      });

      res.status(200).json({
        success: true,
        data: result,
        message: "Motivational message generated.",
      });
    } catch (error) {
      next(error);
    }
  }
}
