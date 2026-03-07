import { UserProfile } from "../models";
import { IUserProfile, IUserProfileInput } from "../types";
import { AppError } from "../middleware/errorHandler";

export class UserProfileService {
  /**
   * Create a default profile for a new user.
   */
  static async createDefaultProfile(userId: string): Promise<IUserProfile> {
    return UserProfile.create({ userId });
  }

  /**
   * Get a user's profile.
   */
  static async getByUserId(userId: string): Promise<IUserProfile> {
    const profile = await UserProfile.findOne({ userId });
    if (!profile) {
      throw new AppError("User profile not found.", 404);
    }
    return profile;
  }

  /**
   * Update a user's profile.
   */
  static async update(
    userId: string,
    input: IUserProfileInput,
  ): Promise<IUserProfile> {
    const profile = await UserProfile.findOneAndUpdate(
      { userId },
      { $set: input },
      { new: true, runValidators: true },
    );

    if (!profile) {
      throw new AppError("User profile not found.", 404);
    }

    return profile;
  }
}
