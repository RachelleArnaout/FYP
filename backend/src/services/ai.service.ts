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

    const requestedAreaNames =
      focusAreas?.map((a) => String(a).trim()).filter((a) => a.length > 0) ??
      [];

    const targetAreas =
      requestedAreaNames.length > 0
        ? lifeAreas.filter((a) => requestedAreaNames.includes(a.name))
        : lifeAreas;

    if (targetAreas.length === 0) {
      throw new AppError(
        "Selected focus areas are not active. Please choose active life areas.",
        400,
      );
    }

    const habitCount = Math.min(
      Math.max(Math.max(count, targetAreas.length), 1),
      10,
    );
    const areaNames = targetAreas.map((a) => a.name);
    const areaQuotas = AIService.computeAreaQuotas(areaNames, habitCount);

    // Build structured input for the prompt
    const profileContext = AIService.buildProfileContext(profile);
    console.log("Profile context for AI:", profileContext);
    const areasContext = AIService.buildLifeAreasContext(targetAreas);
    console.log("Life areas context for AI:", areasContext);
    const existingContext =
      AIService.buildExistingHabitsContext(existingHabits);
    console.log("Existing habits context for AI:", existingContext);

    const quotaContext = AIService.buildQuotaContext(areaQuotas);

    const systemPrompt = `You are an expert behavioral psychologist and life coach specializing in habit formation. Your role is to generate highly personalized, actionable daily habits based on a user's complete profile.

RULES:
- Generate exactly ${habitCount} habit suggestions
- Each habit must be specific, measurable, and achievable
- Consider the user's energy patterns, stress levels, available time, and constraints
- Align habits with the user's values and motivation drivers
- Avoid suggesting habits the user already has
- Consider the user's difficulty preference and structure preference
- Each habit must map to one of the user's active life areas
- Follow the life-area quota strictly (target distribution is provided by the user prompt)
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

${quotaContext}

${existingContext}

Generate habits that are realistic given this person's schedule, energy, and lifestyle. Prioritize high-impact, low-friction habits that match their structure preference.`;

    try {
      const parsed = await AIService.generateHabitPayload(
        systemPrompt,
        userPrompt,
      );

      const validatedHabits = AIService.validateAndSanitize(
        parsed.habits,
        areaNames,
      );

      let balanced = AIService.enforceQuotaDistribution(
        validatedHabits,
        areaQuotas,
        habitCount,
      );

      const shortages = AIService.getQuotaShortages(balanced, areaQuotas);
      if (shortages.size > 0) {
        const missingCount = Array.from(shortages.values()).reduce(
          (sum, value) => sum + value,
          0,
        );

        const existingNames = new Set(
          [...validatedHabits, ...balanced].map((h) => h.name.toLowerCase()),
        );

        const topUpPrompt = `Generate ${missingCount} additional personalized habits to fill missing life-area quotas.

${profileContext}

${areasContext}

MISSING QUOTAS TO FILL (strict):
${AIService.buildQuotaContext(shortages)}

EXISTING GENERATED HABIT NAMES (do not repeat):
${Array.from(existingNames).join("\n")}

Return JSON in the same schema. Ensure each new habit is assigned to one of the missing quota life areas.`;

        const topUpParsed = await AIService.generateHabitPayload(
          systemPrompt,
          topUpPrompt,
        );

        const topUpValidated = AIService.validateAndSanitize(
          topUpParsed.habits,
          areaNames,
        );

        balanced = AIService.enforceQuotaDistribution(
          [...balanced, ...topUpValidated],
          areaQuotas,
          habitCount,
        );
      }

      balanced = AIService.forceQuotaCoverage(balanced, areaQuotas);

      return {
        habits: balanced.slice(0, habitCount),
        summary:
          parsed.summary || "Here are your personalized habit suggestions.",
      };
    } catch (error: any) {
      console.error("Error during AI habit generation:", error);
      if (
        error instanceof AppError &&
        /(truncated|did not return a response)/i.test(error.message)
      ) {
        console.warn(
          "AI returned no visible JSON content. Using deterministic fallback habit generation.",
        );

        const fallbackHabits = AIService.generateFallbackHabits(
          profile,
          targetAreas,
          existingHabits,
          areaQuotas,
          habitCount,
        );

        return {
          habits: fallbackHabits,
          summary:
            "Generated a reliable starter plan while the AI response was unavailable.",
        };
      }

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

  private static buildLifeAreasContext(lifeAreas: any[]): string {
    const areasList = lifeAreas
      .map(
        (a) =>
          `- ${a.icon} ${a.name}: ${a.description || "No description"} (Priority: ${a.priority})`,
      )
      .join("\n");

    return `ACTIVE LIFE AREAS (generate habits for these):\n${areasList}`;
  }

  private static buildQuotaContext(quotas: Map<string, number>): string {
    const quotaLines = Array.from(quotas.entries()).map(
      ([areaName, quota]) => `- ${areaName}: ${quota}`,
    );
    return `LIFE AREA QUOTAS (number of habits required per area):\n${quotaLines.join("\n")}`;
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

  private static computeAreaQuotas(
    areaNames: string[],
    totalCount: number,
  ): Map<string, number> {
    const quotas = new Map<string, number>();
    if (areaNames.length === 0 || totalCount <= 0) return quotas;

    const base = Math.floor(totalCount / areaNames.length);
    const remainder = totalCount % areaNames.length;

    areaNames.forEach((areaName, index) => {
      quotas.set(areaName, base + (index < remainder ? 1 : 0));
    });

    return quotas;
  }

  private static enforceQuotaDistribution(
    habits: IAIGeneratedHabit[],
    quotas: Map<string, number>,
    totalCount: number,
  ): IAIGeneratedHabit[] {
    const byArea = new Map<string, IAIGeneratedHabit[]>();
    for (const areaName of quotas.keys()) {
      byArea.set(areaName, []);
    }

    for (const habit of habits) {
      const bucket = byArea.get(habit.lifeAreaName);
      if (bucket) {
        bucket.push(habit);
      }
    }

    const selected: IAIGeneratedHabit[] = [];
    const usedNames = new Set<string>();

    for (const [areaName, quota] of quotas.entries()) {
      const bucket = byArea.get(areaName) ?? [];
      for (const habit of bucket) {
        if (selected.length >= totalCount) break;
        if (
          selected.filter((h) => h.lifeAreaName === areaName).length >= quota
        ) {
          break;
        }
        const habitNameKey = habit.name.trim().toLowerCase();
        if (usedNames.has(habitNameKey)) continue;
        usedNames.add(habitNameKey);
        selected.push(habit);
      }
    }

    if (selected.length < totalCount) {
      for (const habit of habits) {
        if (selected.length >= totalCount) break;
        const habitNameKey = habit.name.trim().toLowerCase();
        if (usedNames.has(habitNameKey)) continue;
        usedNames.add(habitNameKey);
        selected.push(habit);
      }
    }

    return selected;
  }

  private static getQuotaShortages(
    habits: IAIGeneratedHabit[],
    quotas: Map<string, number>,
  ): Map<string, number> {
    const counts = new Map<string, number>();
    for (const habit of habits) {
      counts.set(habit.lifeAreaName, (counts.get(habit.lifeAreaName) ?? 0) + 1);
    }

    const shortages = new Map<string, number>();
    for (const [areaName, quota] of quotas.entries()) {
      const missing = quota - (counts.get(areaName) ?? 0);
      if (missing > 0) shortages.set(areaName, missing);
    }
    return shortages;
  }

  private static forceQuotaCoverage(
    habits: IAIGeneratedHabit[],
    quotas: Map<string, number>,
  ): IAIGeneratedHabit[] {
    if (habits.length === 0 || quotas.size === 0) return habits;

    const adjusted = habits.map((h) => ({ ...h }));
    const byAreaIndices = new Map<string, number[]>();

    for (const areaName of quotas.keys()) {
      byAreaIndices.set(areaName, []);
    }

    adjusted.forEach((habit, index) => {
      const indices = byAreaIndices.get(habit.lifeAreaName);
      if (indices) indices.push(index);
    });

    for (const [targetArea, targetQuota] of quotas.entries()) {
      const targetIndices = byAreaIndices.get(targetArea) ?? [];

      while (targetIndices.length < targetQuota) {
        let donorArea: string | null = null;

        for (const [areaName, quota] of quotas.entries()) {
          const donorIndices = byAreaIndices.get(areaName) ?? [];
          if (areaName !== targetArea && donorIndices.length > quota) {
            donorArea = areaName;
            break;
          }
        }

        if (!donorArea) break;

        const donorIndices = byAreaIndices.get(donorArea)!;
        const movedIndex = donorIndices.pop();
        if (movedIndex == null) break;

        adjusted[movedIndex] = {
          ...adjusted[movedIndex],
          lifeAreaName: targetArea,
        };
        targetIndices.push(movedIndex);
      }
    }

    return adjusted;
  }

  private static async generateHabitPayload(
    systemPrompt: string,
    userPrompt: string,
  ): Promise<IAIGenerateHabitsResponse> {
    const requestOptions: any = {
      model: environment.llmModel,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      max_completion_tokens: 16000,
      response_format: { type: "json_object" },
    };

    // GPT-5 reasoning models spend hidden tokens on reasoning before output.
    // Minimal effort reserves budget for the visible JSON response.
    if (environment.llmModel.startsWith("gpt-5")) {
      requestOptions.reasoning_effort = "minimal";
    }

    const response = await openai.chat.completions.create(requestOptions);

    console.log("Raw AI response:", response);
    console.log("Raw AI response content:", response.choices[0]?.message);

    const content = AIService.extractAssistantContent(
      response.choices[0]?.message,
    );
    if (!content) {
      throw new AppError("AI did not return a response.", 500);
    }

    return AIService.parseJsonResponse(content);
  }

  private static extractAssistantContent(message: any): string {
    const content = message?.content;

    if (typeof content === "string") {
      return content.trim();
    }

    if (Array.isArray(content)) {
      const text = content
        .map((part: any) => {
          if (typeof part === "string") return part;
          if (typeof part?.text === "string") return part.text;
          return "";
        })
        .join("")
        .trim();

      return text;
    }

    return "";
  }

  private static parseJsonResponse(content: string): IAIGenerateHabitsResponse {
    const cleaned = content
      .trim()
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/\s*```$/, "")
      .trim();

    return JSON.parse(cleaned) as IAIGenerateHabitsResponse;
  }

  private static generateFallbackHabits(
    profile: any,
    targetAreas: any[],
    existingHabits: any[],
    areaQuotas: Map<string, number>,
    habitCount: number,
  ): IAIGeneratedHabit[] {
    const existingNames = new Set(
      (existingHabits ?? []).map((h: any) =>
        String(h.name || "").toLowerCase(),
      ),
    );

    const freeTime = Math.max(Number(profile?.dailyFreeTime) || 30, 10);
    const durationMinutes = Math.min(
      Math.max(Math.round(freeTime / 3), 10),
      25,
    );
    const valueAlignment = String(
      profile?.topValues?.[0] || profile?.motivationDriver || "Growth",
    ).slice(0, 200);
    const difficultyLevel: DifficultyLevel =
      durationMinutes <= 12 ? DifficultyLevel.Micro : DifficultyLevel.Easy;

    const templates = [
      "10-Minute Deep Work Sprint",
      "Focused Skill Practice",
      "Quick Reflection and Plan",
      "Micro Learning Session",
      "Connection Check-In",
      "Energy Reset Walk",
    ];

    const habits: IAIGeneratedHabit[] = [];

    for (const [areaName, quota] of areaQuotas.entries()) {
      for (let i = 0; i < quota; i++) {
        let name = `${templates[(habits.length + i) % templates.length]} - ${areaName}`;
        let suffix = 2;

        while (existingNames.has(name.toLowerCase())) {
          name = `${name} ${suffix}`;
          suffix += 1;
        }

        existingNames.add(name.toLowerCase());

        habits.push({
          name: name.slice(0, 60),
          description: `Spend ${durationMinutes} minutes on a concrete ${areaName.toLowerCase()} action that moves one task forward.`,
          lifeAreaName: areaName,
          goalStatement: `Build consistent momentum in ${areaName.toLowerCase()} with low-friction daily action.`,
          valueAlignment,
          targetFrequency: 5,
          durationMinutes,
          difficultyLevel,
          isBuildingHabit: true,
          reason: `Fits your ${profile?.energyPattern || "daily"} rhythm and available time while reinforcing disciplined progress.`,
        });
      }
    }

    return habits.slice(0, habitCount);
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
