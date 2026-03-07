import { Router } from "express";
import { body } from "express-validator";
import { LifeAreaController } from "../controllers/lifeArea.controller";
import { authenticate } from "../middleware/auth";
import { validateRequest } from "../middleware/validate";

const router = Router();

// All life area routes require authentication
router.use(authenticate);

router.get("/", LifeAreaController.getAll);
router.get("/active", LifeAreaController.getActive);
router.get("/:id", LifeAreaController.getById);

router.post(
  "/",
  [
    body("name").trim().notEmpty().withMessage("Name is required"),
    body("icon").trim().notEmpty().withMessage("Icon is required"),
  ],
  validateRequest,
  LifeAreaController.create,
);

router.put(
  "/:id",
  [
    body("name")
      .optional()
      .trim()
      .notEmpty()
      .withMessage("Name must not be empty"),
    body("icon")
      .optional()
      .trim()
      .notEmpty()
      .withMessage("Icon must not be empty"),
  ],
  validateRequest,
  LifeAreaController.update,
);

router.patch("/:id/toggle", LifeAreaController.toggleActive);
router.delete("/:id", LifeAreaController.delete);

export default router;
