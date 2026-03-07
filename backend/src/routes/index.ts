import { Router } from "express";
import authRoutes from "./auth.routes";
import userProfileRoutes from "./userProfile.routes";
import lifeAreaRoutes from "./lifeArea.routes";
import habitRoutes from "./habit.routes";

const router = Router();

router.use("/auth", authRoutes);
router.use("/profile", userProfileRoutes);
router.use("/life-areas", lifeAreaRoutes);
router.use("/habits", habitRoutes);

export default router;
