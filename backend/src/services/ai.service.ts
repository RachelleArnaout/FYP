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

export interface IAIMotivationalResponse {
  message: string;
  type: "encouragement" | "motivation" | "reminder";
  quote?: string;
  quoteAuthor?: string;
  tip?: string;
}

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

  /**
   * Generate a personalized motivational message based on user progress.
   */
  static async generateMotivationalMessage(
    userId: string,
    progressData: {
      overallConsistency: number; // 0-100
      completedToday: number;
      totalToday: number;
      currentStreaks: { name: string; streak: number }[];
      totalActiveHabits: number;
    },
  ): Promise<IAIMotivationalResponse> {
    const [profile] = await Promise.all([UserProfile.findOne({ userId })]);

    const isDoingWell = progressData.overallConsistency >= 60;
    const userName = profile?.profession
      ? `a ${profile.profession}`
      : "the user";

    const topStreaks = progressData.currentStreaks
      .sort((a, b) => b.streak - a.streak)
      .slice(0, 3)
      .map((s) => `${s.name}: ${s.streak}-day streak`)
      .join(", ");

    const systemPrompt = `You are a warm, empathetic life coach embedded in a habit-tracking app. Your job is to craft a short, personalized motivational message for the user.

RULES:
- Keep the main message to 1-2 sentences, warm and personal
- If the user is doing well (consistency >= 60%), celebrate their progress with genuine encouragement
- If the user is struggling (consistency < 60%), be compassionate — offer a motivational quote from a famous person and a practical tip to get back on track
- Never be preachy or condescending
- Reference specific data (streaks, completion rate) when possible
- Respond ONLY with valid JSON matching the schema below

OUTPUT JSON SCHEMA:
{
  "message": "string (1-2 sentence personalized message)",
  "type": "string (encouragement if doing well, motivation if needs a boost, reminder if hasn't started today)",
  "quote": "string (optional, a real motivational quote — only include if user is struggling)",
  "quoteAuthor": "string (optional, author of the quote)",
  "tip": "string (optional, a practical 1-sentence tip — only include if user is struggling)"
}`;

    const userPrompt = `Generate a motivational message for this user:

PROGRESS DATA:
- Weekly consistency: ${progressData.overallConsistency}%
- Today: ${progressData.completedToday} / ${progressData.totalToday} habits completed
- Top streaks: ${topStreaks || "No active streaks yet"}
- Total active habits: ${progressData.totalActiveHabits}
- Doing well: ${isDoingWell ? "YES" : "NO"}
- User values: ${profile?.topValues?.join(", ") || "Not specified"}
- Motivation driver: ${profile?.motivationDriver || "achievement"}`;

    try {
      const response = await openai.chat.completions.create({
        model: environment.llmModel,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 1.0,
        max_completion_tokens: 300,
        response_format: { type: "json_object" },
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        return AIService.getFallbackMessage(isDoingWell);
      }

      const parsed = JSON.parse(content) as IAIMotivationalResponse;
      return {
        message: String(parsed.message || "").slice(0, 500),
        type: ["encouragement", "motivation", "reminder"].includes(parsed.type)
          ? parsed.type
          : isDoingWell
            ? "encouragement"
            : "motivation",
        quote: parsed.quote ? String(parsed.quote).slice(0, 300) : undefined,
        quoteAuthor: parsed.quoteAuthor
          ? String(parsed.quoteAuthor).slice(0, 100)
          : undefined,
        tip: parsed.tip ? String(parsed.tip).slice(0, 300) : undefined,
      };
    } catch (error: any) {
      console.error("Error generating motivational message:", error);
      return AIService.getFallbackMessage(isDoingWell);
    }
  }

  private static getFallbackMessage(
    isDoingWell: boolean,
  ): IAIMotivationalResponse {
    if (isDoingWell) {
      return {
        message:
          "You're doing great! Keep up the momentum — consistency is the key to transformation.",
        type: "encouragement",
      };
    }
    return {
      message:
        "Every expert was once a beginner. One small step today builds the foundation for tomorrow.",
      type: "motivation",
      quote: "It does not matter how slowly you go as long as you do not stop.",
      quoteAuthor: "Confucius",
      tip: "Try completing just one small habit today to rebuild momentum.",
    };
  }
}
