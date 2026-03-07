import mongoose, { Schema } from "mongoose";
import { IHabit, DifficultyLevel } from "../types";

const habitSchema = new Schema<IHabit>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, "Habit name is required"],
      trim: true,
      minlength: [1, "Habit name must not be empty"],
      maxlength: [200, "Habit name must not exceed 200 characters"],
    },
    description: {
      type: String,
      default: "",
      trim: true,
    },
    lifeAreaId: {
      type: Schema.Types.ObjectId,
      ref: "LifeArea",
      required: [true, "Life area is required"],
    },
    goalStatement: {
      type: String,
      default: "",
      trim: true,
    },
    valueAlignment: {
      type: String,
      default: "",
      trim: true,
    },
    targetFrequency: {
      type: Number,
      default: 7,
      min: 1,
      max: 7,
    },
    durationMinutes: {
      type: Number,
      default: 15,
      min: 1,
      max: 480,
    },
    difficultyLevel: {
      type: String,
      enum: Object.values(DifficultyLevel),
      default: DifficultyLevel.Easy,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    completionRecord: {
      type: Map,
      of: Boolean,
      default: new Map(),
    },
    currentStreak: {
      type: Number,
      default: 0,
      min: 0,
    },
    longestStreak: {
      type: Number,
      default: 0,
      min: 0,
    },
    reminderTime: {
      type: String,
      default: null,
    },
    isBuildingHabit: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret: Record<string, unknown>) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;

        // Convert Map to plain object for JSON serialization
        if (ret.completionRecord instanceof Map) {
          ret.completionRecord = Object.fromEntries(ret.completionRecord);
        }

        return ret;
      },
    },
  },
);

// Compound index for efficient queries
habitSchema.index({ userId: 1, isActive: 1 });
habitSchema.index({ userId: 1, lifeAreaId: 1 });

const Habit = mongoose.model<IHabit>("Habit", habitSchema);

export default Habit;
