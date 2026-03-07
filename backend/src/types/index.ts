import { Request } from "express";
import { Document, Types } from "mongoose";

// ─── Enums ───────────────────────────────────────────────────────────────────

export enum DifficultyLevel {
  Micro = "micro",
  Easy = "easy",
  Medium = "medium",
  Challenging = "challenging",
}

export enum EnergyPattern {
  Morning = "morning",
  Afternoon = "afternoon",
  Evening = "evening",
}

export enum StressLevel {
  Low = "low",
  Medium = "medium",
  High = "high",
}

export enum WorkloadIntensity {
  Low = "low",
  Medium = "medium",
  High = "high",
}

export enum MotivationDriver {
  Achievement = "achievement",
  Connection = "connection",
  Autonomy = "autonomy",
  Purpose = "purpose",
}

export enum FailureResponse {
  Resilient = "resilient",
  Avoidant = "avoidant",
  Analytical = "analytical",
}

export enum StructurePreference {
  Rigid = "rigid",
  Balanced = "balanced",
  Flexible = "flexible",
}

// ─── User Types ──────────────────────────────────────────────────────────────

export interface IUser extends Document {
  _id: Types.ObjectId;
  name: string;
  email: string;
  password: string;
  isOnboarded: boolean;
  createdAt: Date;
  updatedAt: Date;
  comparePassword(candidatePassword: string): Promise<boolean>;
}

export interface IUserRegistrationInput {
  name: string;
  email: string;
  password: string;
}

export interface IUserLoginInput {
  email: string;
  password: string;
}

export interface IAuthResponse {
  user: {
    id: string;
    name: string;
    email: string;
    isOnboarded: boolean;
  };
  token: string;
}

// ─── UserProfile Types ───────────────────────────────────────────────────────

export interface IUserProfile extends Document {
  _id: Types.ObjectId;
  userId: Types.ObjectId;
  ageRange: string;
  profession: string;
  industry: string;
  degree: string;
  lifestyleTypes: string[];
  livingSituation: string;
  energyPattern: EnergyPattern;
  dailyFreeTime: number;
  stressBaseline: StressLevel;
  stressSources: string[];
  workloadIntensity: WorkloadIntensity;
  motivationDriver: MotivationDriver;
  failureResponse: FailureResponse;
  structurePreference: StructurePreference;
  topValues: string[];
  identityStatements: string[];
  constraints: string[];
  badHabits: string[];
  currentLifePhase: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface IUserProfileInput {
  ageRange?: string;
  profession?: string;
  industry?: string;
  degree?: string;
  lifestyleTypes?: string[];
  livingSituation?: string;
  energyPattern?: EnergyPattern;
  dailyFreeTime?: number;
  stressBaseline?: StressLevel;
  stressSources?: string[];
  workloadIntensity?: WorkloadIntensity;
  motivationDriver?: MotivationDriver;
  failureResponse?: FailureResponse;
  structurePreference?: StructurePreference;
  topValues?: string[];
  identityStatements?: string[];
  constraints?: string[];
  badHabits?: string[];
  currentLifePhase?: string | null;
}

// ─── LifeArea Types ──────────────────────────────────────────────────────────

export interface ILifeArea extends Document {
  _id: Types.ObjectId;
  userId: Types.ObjectId;
  name: string;
  icon: string;
  isActive: boolean;
  priority: number;
  description: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ILifeAreaInput {
  name: string;
  icon: string;
  isActive?: boolean;
  priority?: number;
  description?: string;
}

export interface ILifeAreaUpdateInput {
  name?: string;
  icon?: string;
  isActive?: boolean;
  priority?: number;
  description?: string;
}

// ─── Habit Types ─────────────────────────────────────────────────────────────

export interface ICompletionRecord {
  [dateKey: string]: boolean;
}

export interface IHabit extends Document {
  _id: Types.ObjectId;
  userId: Types.ObjectId;
  name: string;
  description: string;
  lifeAreaId: Types.ObjectId;
  goalStatement: string;
  valueAlignment: string;
  targetFrequency: number;
  durationMinutes: number;
  difficultyLevel: DifficultyLevel;
  isActive: boolean;
  completionRecord: Map<string, boolean>;
  currentStreak: number;
  longestStreak: number;
  reminderTime: string | null;
  isBuildingHabit: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface IHabitInput {
  name: string;
  description?: string;
  lifeAreaId: string;
  goalStatement?: string;
  valueAlignment?: string;
  targetFrequency?: number;
  durationMinutes?: number;
  difficultyLevel?: DifficultyLevel;
  isActive?: boolean;
  reminderTime?: string | null;
  isBuildingHabit?: boolean;
}

export interface IHabitUpdateInput {
  name?: string;
  description?: string;
  lifeAreaId?: string;
  goalStatement?: string;
  valueAlignment?: string;
  targetFrequency?: number;
  durationMinutes?: number;
  difficultyLevel?: DifficultyLevel;
  isActive?: boolean;
  reminderTime?: string | null;
  isBuildingHabit?: boolean;
}

export interface IHabitCompletionInput {
  date: string; // ISO date string YYYY-MM-DD
  completed: boolean;
}

// ─── Request Types ───────────────────────────────────────────────────────────

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

// ─── API Response Types ──────────────────────────────────────────────────────

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  message?: string;
  errors?: string[];
}
