import mongoose, { Schema } from "mongoose";
import {
  IUserProfile,
  EnergyPattern,
  StressLevel,
  WorkloadIntensity,
  MotivationDriver,
  FailureResponse,
  StructurePreference,
} from "../types";

const userProfileSchema = new Schema<IUserProfile>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },
    ageRange: {
      type: String,
      default: "",
    },
    profession: {
      type: String,
      default: "",
      trim: true,
    },
    industry: {
      type: String,
      default: "",
      trim: true,
    },
    degree: {
      type: String,
      default: "",
      trim: true,
    },
    lifestyleTypes: {
      type: [String],
      default: [],
    },
    livingSituation: {
      type: String,
      default: "",
    },
    energyPattern: {
      type: String,
      enum: Object.values(EnergyPattern),
      default: EnergyPattern.Morning,
    },
    dailyFreeTime: {
      type: Number,
      default: 60,
      min: 0,
      max: 1440,
    },
    stressBaseline: {
      type: String,
      enum: Object.values(StressLevel),
      default: StressLevel.Medium,
    },
    stressSources: {
      type: [String],
      default: [],
    },
    workloadIntensity: {
      type: String,
      enum: Object.values(WorkloadIntensity),
      default: WorkloadIntensity.Medium,
    },
    motivationDriver: {
      type: String,
      enum: Object.values(MotivationDriver),
      default: MotivationDriver.Achievement,
    },
    failureResponse: {
      type: String,
      enum: Object.values(FailureResponse),
      default: FailureResponse.Resilient,
    },
    structurePreference: {
      type: String,
      enum: Object.values(StructurePreference),
      default: StructurePreference.Balanced,
    },
    topValues: {
      type: [String],
      default: [],
      validate: {
        validator: (values: string[]) => values.length <= 3,
        message: "Cannot have more than 3 top values",
      },
    },
    identityStatements: {
      type: [String],
      default: [],
    },
    constraints: {
      type: [String],
      default: [],
    },
    badHabits: {
      type: [String],
      default: [],
    },
    currentLifePhase: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret: Record<string, unknown>) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  },
);

const UserProfile = mongoose.model<IUserProfile>(
  "UserProfile",
  userProfileSchema,
);

export default UserProfile;
