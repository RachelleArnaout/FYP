import OpenAI from "openai";
import { environment } from "../config/environment";
import { AppError } from "../middleware/errorHandler";
import { UserProfile, LifeArea, Habit } from "../models";
import {
  IAIGeneratedHabit,
  IAIGenerateHabitsResponse,
  DifficultyLevel,
} from "../types";

const openai = new OpenAI({
  apiKey: environment.openaiApiKey,
});

console.log("AI Service initialized with model:", environment.llmModel);

export class AIService {
  /**
   * Generate personalized habit suggestions using GPT-5-nano based on user profile.
   */
  static async generateHabits(
    userId: string,
    focusAreas?: string[],
    count: number = 5,
  ): Promise<IAIGenerateHabitsResponse> {
    // Clamp count to a safe range
    const habitCount = Math.min(Math.max(count, 1), 10);

    // Fetch user data in parallel
    const [profile, lifeAreas, existingHabits] = await Promise.all([
      UserProfile.findOne({ userId }),
      LifeArea.find({ userId, isActive: true }),
      Habit.find({ userId }),
    ]);

    if (!profile) {
      throw new AppError(
        "User profile not found. Complete onboarding first.",
        400,
      );
    }

    if (lifeAreas.length === 0) {
      throw new AppError(
        "No active life areas found. Please activate at least one.",
        400,
      );
    }

    // Build structured input for the prompt
    const profileContext = AIService.buildProfileContext(profile);
    console.log("Profile context for AI:", profileContext);
    const areasContext = AIService.buildLifeAreasContext(lifeAreas, focusAreas);
    console.log("Life areas context for AI:", areasContext);
    const existingContext =
      AIService.buildExistingHabitsContext(existingHabits);
    console.log("Existing habits context for AI:", existingContext);

    const systemPrompt = `You are an expert behavioral psychologist and life coach specializing in habit formation. Your role is to generate highly personalized, actionable daily habits based on a user's complete profile.

RULES:
- Generate exactly ${habitCount} habit suggestions
- Each habit must be specific, measurable, and achievable
- Consider the user's energy patterns, stress levels, available time, and constraints
- Align habits with the user's values and motivation drivers
- Avoid suggesting habits the user already has
- Consider the user's difficulty preference and structure preference
- Each habit must map to one of the user's active life areas
- Provide a brief reason explaining why each habit fits this user
- Respond ONLY with valid JSON matching the exact schema below

OUTPUT JSON SCHEMA:
{
  "habits": [
    {
      "name": "string (concise habit name, max 60 chars)",
      "description": "string (1-2 sentence description, max 200 chars)",
      "lifeAreaName": "string (must match one of the user's active life areas exactly)",
      "goalStatement": "string (what this habit helps achieve, max 150 chars)",
      "valueAlignment": "string (which user value this aligns with)",
      "targetFrequency": "number (1-7, days per week)",
      "durationMinutes": "number (5-120, realistic time needed)",
      "difficultyLevel": "string (one of: micro, easy, medium, challenging)",
      "isBuildingHabit": "boolean (true to build new behavior, false to break bad one)",
      "reason": "string (why this habit is perfect for this specific user, max 150 chars)"
    }
  ],
  "summary": "string (1-2 sentence overall explanation of the habit plan)"
}`;

    const userPrompt = `Generate ${habitCount} personalized habit suggestions for this user:

${profileContext}

${areasContext}

${existingContext}

Generate habits that are realistic given this person's schedule, energy, and lifestyle. Prioritize high-impact, low-friction habits that match their structure preference.`;

    try {
      const response = await openai.chat.completions.create({
        model: environment.llmModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 1.0,
        max_completion_tokens: 1000,
        response_format: { type: "json_object" },
      });

      console.log("Raw AI response:", response);
      console.log("Raw AI response content:", response.choices[0]?.message);

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new AppError("AI did not return a response.", 500);
      }

      const parsed = JSON.parse(content) as IAIGenerateHabitsResponse;

      // Validate and sanitize the response
      const validatedHabits = AIService.validateAndSanitize(
        parsed.habits,
        lifeAreas.map((a) => a.name),
      );

      return {
        habits: validatedHabits,
        summary:
          parsed.summary || "Here are your personalized habit suggestions.",
      };
    } catch (error: any) {
      console.error("Error during AI habit generation:", error);
      if (error instanceof AppError) throw error;
      if (error.status === 401) {
        throw new AppError(
          "AI service authentication failed. Check API key.",
          500,
        );
      }
      if (error instanceof SyntaxError) {
        throw new AppError("AI returned invalid response format.", 500);
      }
      throw new AppError(`AI habit generation failed: ${error.message}`, 500);
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  private static buildProfileContext(profile: any): string {
    return `USER PROFILE:
- Age Range: ${profile.ageRange || "Not specified"}
- Profession: ${profile.profession || "Not specified"} (${profile.industry || "N/A"})
- Degree: ${profile.degree || "Not specified"}
- Lifestyle: ${profile.lifestyleTypes?.join(", ") || "Not specified"}
- Living Situation: ${profile.livingSituation || "Not specified"}
- Energy Pattern: ${profile.energyPattern} (peak productivity time)
- Daily Free Time: ${profile.dailyFreeTime} minutes
- Stress Level: ${profile.stressBaseline}
- Stress Sources: ${profile.stressSources?.join(", ") || "None specified"}
- Workload Intensity: ${profile.workloadIntensity}
- Motivation Driver: ${profile.motivationDriver}
- Failure Response: ${profile.failureResponse}
- Structure Preference: ${profile.structurePreference}
- Core Values: ${profile.topValues?.join(", ") || "Not specified"}
- Identity Statements: ${profile.identityStatements?.join("; ") || "None"}
- Constraints: ${profile.constraints?.join(", ") || "None"}
- Bad Habits to Address: ${profile.badHabits?.join(", ") || "None"}
- Life Phase: ${profile.currentLifePhase || "Not specified"}`;
  }

  private static buildLifeAreasContext(
    lifeAreas: any[],
    focusAreas?: string[],
  ): string {
    const areas = focusAreas?.length
      ? lifeAreas.filter((a) => focusAreas.includes(a.name))
      : lifeAreas;

    const areasList = areas
      .map(
        (a) =>
          `- ${a.icon} ${a.name}: ${a.description || "No description"} (Priority: ${a.priority})`,
      )
      .join("\n");

    return `ACTIVE LIFE AREAS (generate habits for these):\n${areasList}`;
  }

  private static buildExistingHabitsContext(habits: any[]): string {
    if (habits.length === 0) {
      return "EXISTING HABITS: None (this is a new user)";
    }

    const habitsList = habits
      .map(
        (h) =>
          `- ${h.name} (${h.difficultyLevel}, ${h.durationMinutes}min, ${h.isActive ? "active" : "inactive"})`,
      )
      .join("\n");

    return `EXISTING HABITS (avoid duplicating these):\n${habitsList}`;
  }

  private static validateAndSanitize(
    habits: IAIGeneratedHabit[],
    validAreaNames: string[],
  ): IAIGeneratedHabit[] {
    if (!Array.isArray(habits)) return [];

    const validDifficulties = Object.values(DifficultyLevel);

    return habits
      .filter((h) => h && h.name)
      .map((h) => ({
        name: String(h.name).slice(0, 200),
        description: String(h.description || "").slice(0, 500),
        lifeAreaName: validAreaNames.includes(h.lifeAreaName)
          ? h.lifeAreaName
          : validAreaNames[0],
        goalStatement: String(h.goalStatement || "").slice(0, 500),
        valueAlignment: String(h.valueAlignment || "").slice(0, 200),
        targetFrequency: Math.min(
          Math.max(Number(h.targetFrequency) || 7, 1),
          7,
        ),
        durationMinutes: Math.min(
          Math.max(Number(h.durationMinutes) || 15, 1),
          480,
        ),
        difficultyLevel: validDifficulties.includes(h.difficultyLevel)
          ? h.difficultyLevel
          : DifficultyLevel.Easy,
        isBuildingHabit: h.isBuildingHabit !== false,
        reason: String(h.reason || "").slice(0, 500),
      }));
  }
}
