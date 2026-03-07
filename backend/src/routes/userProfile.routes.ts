import { Router } from "express";
import { UserProfileController } from "../controllers/userProfile.controller";
import { authenticate } from "../middleware/auth";

const router = Router();

// All profile routes require authentication
router.use(authenticate);

router.get("/", UserProfileController.getProfile);
router.put("/", UserProfileController.updateProfile);

export default router;
