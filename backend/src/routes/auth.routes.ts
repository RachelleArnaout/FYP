import { Router } from "express";
import { body } from "express-validator";
import { AuthController } from "../controllers/auth.controller";
import { authenticate } from "../middleware/auth";
import { validateRequest } from "../middleware/validate";

const router = Router();

// ─── Public Routes ───────────────────────────────────────────────────────────

router.post(
  "/register",
  [
    body("name")
      .trim()
      .notEmpty()
      .withMessage("Name is required")
      .isLength({ min: 2, max: 100 })
      .withMessage("Name must be between 2 and 100 characters"),
    body("email")
      .trim()
      .isEmail()
      .withMessage("Please provide a valid email address")
      .normalizeEmail(),
    body("password")
      .isLength({ min: 6 })
      .withMessage("Password must be at least 6 characters"),
  ],
  validateRequest,
  AuthController.register,
);

router.post(
  "/login",
  [
    body("email")
      .trim()
      .isEmail()
      .withMessage("Please provide a valid email address")
      .normalizeEmail(),
    body("password").notEmpty().withMessage("Password is required"),
  ],
  validateRequest,
  AuthController.login,
);

// ─── Protected Routes ────────────────────────────────────────────────────────

router.get("/me", authenticate, AuthController.getMe);
router.patch(
  "/complete-onboarding",
  authenticate,
  AuthController.completeOnboarding,
);

export default router;
