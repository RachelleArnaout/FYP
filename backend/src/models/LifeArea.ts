import mongoose, { Schema } from "mongoose";
import { ILifeArea } from "../types";

const lifeAreaSchema = new Schema<ILifeArea>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, "Life area name is required"],
      trim: true,
    },
    icon: {
      type: String,
      required: [true, "Icon is required"],
    },
    isActive: {
      type: Boolean,
      default: false,
    },
    priority: {
      type: Number,
      default: 0,
      min: 0,
      max: 8,
    },
    description: {
      type: String,
      default: "",
      trim: true,
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

// Compound index to ensure unique life area names per user
lifeAreaSchema.index({ userId: 1, name: 1 }, { unique: true });

const LifeArea = mongoose.model<ILifeArea>("LifeArea", lifeAreaSchema);

export default LifeArea;
