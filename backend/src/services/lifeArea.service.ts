import { LifeArea } from "../models";
import { ILifeArea, ILifeAreaInput, ILifeAreaUpdateInput } from "../types";
import { AppError } from "../middleware/errorHandler";

// Default life areas that match the Flutter app
const DEFAULT_LIFE_AREAS: Omit<ILifeAreaInput, "userId">[] = [
  {
    name: "Academic Growth",
    icon: "📚",
    description: "Learning, studying, and intellectual development",
  },
  {
    name: "Professional Growth",
    icon: "💼",
    description: "Career development and workplace skills",
  },
  {
    name: "Mental & Emotional Well-being",
    icon: "🧠",
    description: "Mental health, emotional balance, and mindfulness",
  },
  {
    name: "Physical Health",
    icon: "💪",
    description: "Exercise, nutrition, and physical wellness",
  },
  {
    name: "Social Skills & Relationships",
    icon: "👥",
    description: "Friendships, networking, and social connections",
  },
  {
    name: "Spiritual or Inner Growth",
    icon: "🕉️",
    description: "Spirituality, values, and purpose",
  },
  {
    name: "Creativity & Self-expression",
    icon: "🎨",
    description: "Creative pursuits and artistic expression",
  },
  {
    name: "Financial Discipline",
    icon: "💰",
    description: "Money management and financial planning",
  },
];

export class LifeAreaService {
  /**
   * Create default life areas for a new user.
   */
  static async createDefaultAreas(userId: string): Promise<ILifeArea[]> {
    const areas = DEFAULT_LIFE_AREAS.map((area) => ({
      ...area,
      userId,
    }));
    const result = await LifeArea.insertMany(areas);
    return result as unknown as ILifeArea[];
  }

  /**
   * Get all life areas for a user.
   */
  static async getAllByUserId(userId: string): Promise<ILifeArea[]> {
    return LifeArea.find({ userId }).sort({ priority: 1 });
  }

  /**
   * Get active life areas for a user.
   */
  static async getActiveByUserId(userId: string): Promise<ILifeArea[]> {
    return LifeArea.find({ userId, isActive: true }).sort({ priority: 1 });
  }

  /**
   * Get a single life area by ID (scoped to user).
   */
  static async getById(userId: string, areaId: string): Promise<ILifeArea> {
    const area = await LifeArea.findOne({ _id: areaId, userId });
    if (!area) {
      throw new AppError("Life area not found.", 404);
    }
    return area;
  }

  /**
   * Create a custom life area for a user.
   */
  static async create(
    userId: string,
    input: ILifeAreaInput,
  ): Promise<ILifeArea> {
    return LifeArea.create({ ...input, userId });
  }

  /**
   * Update a life area.
   */
  static async update(
    userId: string,
    areaId: string,
    input: ILifeAreaUpdateInput,
  ): Promise<ILifeArea> {
    const area = await LifeArea.findOneAndUpdate(
      { _id: areaId, userId },
      { $set: input },
      { new: true, runValidators: true },
    );

    if (!area) {
      throw new AppError("Life area not found.", 404);
    }

    return area;
  }

  /**
   * Toggle active state of a life area.
   */
  static async toggleActive(
    userId: string,
    areaId: string,
  ): Promise<ILifeArea> {
    const area = await LifeArea.findOne({ _id: areaId, userId });
    if (!area) {
      throw new AppError("Life area not found.", 404);
    }

    area.isActive = !area.isActive;
    await area.save();
    return area;
  }

  /**
   * Delete a life area.
   */
  static async delete(userId: string, areaId: string): Promise<void> {
    const result = await LifeArea.findOneAndDelete({ _id: areaId, userId });
    if (!result) {
      throw new AppError("Life area not found.", 404);
    }
  }
}
