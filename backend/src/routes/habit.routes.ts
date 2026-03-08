import { Router } from "express";
import { body, query } from "express-validator";
import { HabitController } from "../controllers/habit.controller";
import { AIHabitController } from "../controllers/ai.controller";
import { authenticate } from "../middleware/auth";
import { validateRequest } from "../middleware/validate";

const router = Router();

// All habit routes require authentication
router.use(authenticate);

// ─── Analytics (must be before /:id to avoid route conflict) ─────────────────

router.get(
  "/analytics/overview",
  [
    query("days")
      .optional()
      .isInt({ min: 1, max: 365 })
      .withMessage("Days must be between 1 and 365"),
  ],
  validateRequest,
  HabitController.getAnalytics,
);

// ─── AI Habit Generation ─────────────────────────────────────────────────────

router.post(
  "/ai/generate",
  [
    body("focusAreas")
      .optional()
      .isArray()
      .withMessage("Focus areas must be an array"),
    body("count")
      .optional()
      .isInt({ min: 1, max: 10 })
      .withMessage("Count must be between 1 and 10"),
  ],
  validateRequest,
  AIHabitController.generate,
);

router.post(
  "/ai/approve",
  [
    body("habits")
      .isArray({ min: 1, max: 10 })
      .withMessage("Provide 1-10 habits to approve"),
    body("habits.*.name")
      .trim()
      .notEmpty()
      .withMessage("Each habit must have a name"),
    body("habits.*.lifeAreaId")
      .notEmpty()
      .withMessage("Each habit must have a life area"),
    body("habits.*.targetFrequency")
      .optional()
      .isInt({ min: 1, max: 7 })
      .withMessage("Target frequency must be between 1 and 7"),
    body("habits.*.durationMinutes")
      .optional()
      .isInt({ min: 1, max: 480 })
      .withMessage("Duration must be between 1 and 480 minutes"),
    body("habits.*.difficultyLevel")
      .optional()
      .isIn(["micro", "easy", "medium", "challenging"])
      .withMessage("Invalid difficulty level"),
  ],
  validateRequest,
  AIHabitController.approve,
);

// ─── Listing Routes ──────────────────────────────────────────────────────────

router.get("/", HabitController.getAll);
router.get("/active", HabitController.getActive);
router.get("/life-area/:lifeAreaId", HabitController.getByLifeArea);

// ─── Single Habit Routes ─────────────────────────────────────────────────────

router.get("/:id", HabitController.getById);

router.get(
  "/:id/consistency",
  [
    query("days")
      .optional()
      .isInt({ min: 1, max: 365 })
      .withMessage("Days must be between 1 and 365"),
  ],
  validateRequest,
  HabitController.getConsistency,
);

router.post(
  "/",
  [
    body("name").trim().notEmpty().withMessage("Habit name is required"),
    body("lifeAreaId").notEmpty().withMessage("Life area is required"),
    body("targetFrequency")
      .optional()
      .isInt({ min: 1, max: 7 })
      .withMessage("Target frequency must be between 1 and 7"),
    body("durationMinutes")
      .optional()
      .isInt({ min: 1, max: 480 })
      .withMessage("Duration must be between 1 and 480 minutes"),
    body("difficultyLevel")
      .optional()
      .isIn(["micro", "easy", "medium", "challenging"])
      .withMessage("Invalid difficulty level"),
  ],
  validateRequest,
  HabitController.create,
);

router.put(
  "/:id",
  [
    body("name")
      .optional()
      .trim()
      .notEmpty()
      .withMessage("Habit name must not be empty"),
    body("targetFrequency")
      .optional()
      .isInt({ min: 1, max: 7 })
      .withMessage("Target frequency must be between 1 and 7"),
    body("durationMinutes")
      .optional()
      .isInt({ min: 1, max: 480 })
      .withMessage("Duration must be between 1 and 480 minutes"),
    body("difficultyLevel")
      .optional()
      .isIn(["micro", "easy", "medium", "challenging"])
      .withMessage("Invalid difficulty level"),
  ],
  validateRequest,
  HabitController.update,
);

router.delete("/:id", HabitController.delete);

router.patch(
  "/:id/completion",
  [
    body("date")
      .notEmpty()
      .withMessage("Date is required")
      .matches(/^\d{4}-\d{2}-\d{2}$/)
      .withMessage("Date must be in YYYY-MM-DD format"),
    body("completed")
      .isBoolean()
      .withMessage("Completed must be a boolean value"),
  ],
  validateRequest,
  HabitController.toggleCompletion,
);

export default router;
