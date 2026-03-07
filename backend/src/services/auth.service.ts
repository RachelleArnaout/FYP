import jwt from "jsonwebtoken";
import { User } from "../models";
import { environment } from "../config/environment";
import {
  IUser,
  IUserRegistrationInput,
  IUserLoginInput,
  IAuthResponse,
} from "../types";
import { AppError } from "../middleware/errorHandler";
import { LifeAreaService } from "./lifeArea.service";
import { UserProfileService } from "./userProfile.service";

export class AuthService {
  /**
   * Register a new user, create their default profile and life areas.
   */
  static async register(input: IUserRegistrationInput): Promise<IAuthResponse> {
    const existingUser = await User.findOne({ email: input.email });
    if (existingUser) {
      throw new AppError("An account with this email already exists.", 409);
    }

    const user = await User.create({
      name: input.name,
      email: input.email,
      password: input.password,
    });

    // Create default profile and life areas for the new user
    await Promise.all([
      UserProfileService.createDefaultProfile(user._id.toString()),
      LifeAreaService.createDefaultAreas(user._id.toString()),
    ]);

    const token = AuthService.generateToken(user);

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        isOnboarded: user.isOnboarded,
      },
      token,
    };
  }

  /**
   * Authenticate a user with email and password.
   */
  static async login(input: IUserLoginInput): Promise<IAuthResponse> {
    const user = await User.findOne({ email: input.email }).select("+password");
    if (!user) {
      throw new AppError("Invalid email or password.", 401);
    }

    const isPasswordValid = await user.comparePassword(input.password);
    if (!isPasswordValid) {
      throw new AppError("Invalid email or password.", 401);
    }

    const token = AuthService.generateToken(user);

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        isOnboarded: user.isOnboarded,
      },
      token,
    };
  }

  /**
   * Get the current authenticated user.
   */
  static async getCurrentUser(userId: string): Promise<IUser> {
    const user = await User.findById(userId);
    if (!user) {
      throw new AppError("User not found.", 404);
    }
    return user;
  }

  /**
   * Mark user as onboarded.
   */
  static async completeOnboarding(userId: string): Promise<IUser> {
    const user = await User.findByIdAndUpdate(
      userId,
      { isOnboarded: true },
      { new: true },
    );
    if (!user) {
      throw new AppError("User not found.", 404);
    }
    return user;
  }

  /**
   * Generate a JWT token for a user.
   */
  private static generateToken(user: IUser): string {
    const options: jwt.SignOptions = {
      expiresIn:
        environment.jwtExpiresIn as unknown as jwt.SignOptions["expiresIn"],
    };
    return jwt.sign(
      { userId: user._id.toString() },
      environment.jwtSecret,
      options,
    );
  }
}
