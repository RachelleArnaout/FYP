import { Habit } from "../models";
import {
  IHabit,
  IHabitInput,
  IHabitUpdateInput,
  IHabitCompletionInput,
} from "../types";
import { AppError } from "../middleware/errorHandler";

export class HabitService {
  /**
   * Get all habits for a user.
   */
  static async getAllByUserId(userId: string): Promise<IHabit[]> {
    return Habit.find({ userId }).sort({ createdAt: -1 });
  }

  /**
   * Get active habits for a user.
   */
  static async getActiveByUserId(userId: string): Promise<IHabit[]> {
    return Habit.find({ userId, isActive: true }).sort({ createdAt: -1 });
  }

  /**
   * Get habits by life area.
   */
  static async getByLifeArea(
    userId: string,
    lifeAreaId: string,
  ): Promise<IHabit[]> {
    return Habit.find({ userId, lifeAreaId }).sort({ createdAt: -1 });
  }

  /**
   * Get a single habit by ID (scoped to user).
   */
  static async getById(userId: string, habitId: string): Promise<IHabit> {
    const habit = await Habit.findOne({ _id: habitId, userId });
    if (!habit) {
      throw new AppError("Habit not found.", 404);
    }
    return habit;
  }

  /**
   * Create a new habit.
   */
  static async create(userId: string, input: IHabitInput): Promise<IHabit> {
    return Habit.create({ ...input, userId });
  }

  /**
   * Update a habit.
   */
  static async update(
    userId: string,
    habitId: string,
    input: IHabitUpdateInput,
  ): Promise<IHabit> {
    const habit = await Habit.findOneAndUpdate(
      { _id: habitId, userId },
      { $set: input },
      { new: true, runValidators: true },
    );

    if (!habit) {
      throw new AppError("Habit not found.", 404);
    }

    return habit;
  }

  /**
   * Delete a habit.
   */
  static async delete(userId: string, habitId: string): Promise<void> {
    const result = await Habit.findOneAndDelete({ _id: habitId, userId });
    if (!result) {
      throw new AppError("Habit not found.", 404);
    }
  }

  /**
   * Toggle habit completion for a specific date.
   */
  static async toggleCompletion(
    userId: string,
    habitId: string,
    input: IHabitCompletionInput,
  ): Promise<IHabit> {
    const habit = await Habit.findOne({ _id: habitId, userId });
    if (!habit) {
      throw new AppError("Habit not found.", 404);
    }

    const dateKey = input.date; // Expected format: YYYY-MM-DD
    habit.completionRecord.set(dateKey, input.completed);

    // Recalculate streak
    HabitService.recalculateStreak(habit);

    await habit.save();
    return habit;
  }

  /**
   * Get completion stats for a habit over a number of days.
   */
  static async getConsistencyRate(
    userId: string,
    habitId: string,
    days: number,
  ): Promise<{ completed: number; total: number; rate: number }> {
    const habit = await HabitService.getById(userId, habitId);
    const now = new Date();
    let completed = 0;

    for (let i = 0; i < days; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateKey = HabitService.formatDateKey(date);
      if (habit.completionRecord.get(dateKey) === true) {
        completed++;
      }
    }

    return {
      completed,
      total: days,
      rate: days > 0 ? completed / days : 0,
    };
  }

  /**
   * Get overall analytics for a user's habits.
   */
  static async getAnalytics(
    userId: string,
    days: number,
  ): Promise<{
    overallConsistency: number;
    lifeAreaCompletionCounts: Record<string, number>;
    totalHabits: number;
    activeHabits: number;
  }> {
    const habits = await Habit.find({ userId });
    const activeHabits = habits.filter((h) => h.isActive);
    const now = new Date();

    let totalConsistency = 0;
    const lifeAreaCounts: Record<string, number> = {};

    for (const habit of activeHabits) {
      let completed = 0;
      for (let i = 0; i < days; i++) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        const dateKey = HabitService.formatDateKey(date);
        if (habit.completionRecord.get(dateKey) === true) {
          completed++;
        }
      }

      totalConsistency += days > 0 ? completed / days : 0;

      const areaId = habit.lifeAreaId.toString();
      lifeAreaCounts[areaId] = (lifeAreaCounts[areaId] || 0) + completed;
    }

    return {
      overallConsistency:
        activeHabits.length > 0 ? totalConsistency / activeHabits.length : 0,
      lifeAreaCompletionCounts: lifeAreaCounts,
      totalHabits: habits.length,
      activeHabits: activeHabits.length,
    };
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  /**
   * Recalculate current and longest streak for a habit.
   */
  private static recalculateStreak(habit: IHabit): void {
    let streak = 0;
    const now = new Date();

    for (let i = 0; i < 365; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateKey = HabitService.formatDateKey(date);

      if (habit.completionRecord.get(dateKey) === true) {
        streak++;
      } else {
        break;
      }
    }

    habit.currentStreak = streak;
    if (streak > habit.longestStreak) {
      habit.longestStreak = streak;
    }
  }

  /**
   * Format a date to YYYY-MM-DD key.
   */
  private static formatDateKey(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }
}
