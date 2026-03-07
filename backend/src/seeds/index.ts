import mongoose from "mongoose";
import bcrypt from "bcryptjs";
import { connectDatabase, disconnectDatabase } from "../config/database";
import { User, UserProfile, LifeArea, Habit } from "../models";

/**
 * Seed data for development and testing.
 * Creates sample users with profiles, life areas, and habits.
 */

interface SeedUser {
  name: string;
  email: string;
  password: string;
  isOnboarded: boolean;
}

const SEED_USERS: SeedUser[] = [
  {
    name: "John Doe",
    email: "john@example.com",
    password: "password123",
    isOnboarded: true,
  },
  {
    name: "Jane Smith",
    email: "jane@example.com",
    password: "password123",
    isOnboarded: true,
  },
  {
    name: "New User",
    email: "newuser@example.com",
    password: "password123",
    isOnboarded: false,
  },
];

const DEFAULT_LIFE_AREAS = [
  {
    name: "Academic Growth",
    icon: "📚",
    description: "Learning, studying, and intellectual development",
  },
  {
    name: "Professional Growth",
    icon: "💼",
    description: "Career development and workplace skills",
  },
  {
    name: "Mental & Emotional Well-being",
    icon: "🧠",
    description: "Mental health, emotional balance, and mindfulness",
  },
  {
    name: "Physical Health",
    icon: "💪",
    description: "Exercise, nutrition, and physical wellness",
  },
  {
    name: "Social Skills & Relationships",
    icon: "👥",
    description: "Friendships, networking, and social connections",
  },
  {
    name: "Spiritual or Inner Growth",
    icon: "🕉️",
    description: "Spirituality, values, and purpose",
  },
  {
    name: "Creativity & Self-expression",
    icon: "🎨",
    description: "Creative pursuits and artistic expression",
  },
  {
    name: "Financial Discipline",
    icon: "💰",
    description: "Money management and financial planning",
  },
];

function generateCompletionRecord(
  daysBack: number,
  completionRate: number,
): Map<string, boolean> {
  const record = new Map<string, boolean>();
  const now = new Date();

  for (let i = 0; i < daysBack; i++) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const dateKey = `${year}-${month}-${day}`;
    record.set(dateKey, Math.random() < completionRate);
  }

  return record;
}

async function seed(): Promise<void> {
  console.log("🌱 Starting seed...\n");

  // Clear existing data
  await Promise.all([
    User.deleteMany({}),
    UserProfile.deleteMany({}),
    LifeArea.deleteMany({}),
    Habit.deleteMany({}),
  ]);
  console.log("  Cleared existing data.");

  for (const seedUser of SEED_USERS) {
    // Create user
    const user = await User.create(seedUser);
    console.log(`\n  👤 Created user: ${user.name} (${user.email})`);

    // Create profile
    const profileData: Record<string, unknown> = {
      userId: user._id,
    };

    if (seedUser.isOnboarded) {
      Object.assign(profileData, {
        ageRange: "25-34",
        profession:
          seedUser.name === "John Doe" ? "Software Engineer" : "Designer",
        industry: "Technology",
        degree: "Bachelor's in Computer Science",
        lifestyleTypes: ["Working Professional", "Hybrid Work"],
        livingSituation: "Apartment",
        energyPattern: seedUser.name === "John Doe" ? "morning" : "evening",
        dailyFreeTime: 90,
        stressBaseline: "medium",
        stressSources: ["Work deadlines", "Personal goals"],
        workloadIntensity: "medium",
        motivationDriver: "achievement",
        failureResponse: "resilient",
        structurePreference: "balanced",
        topValues: ["Growth", "Health", "Discipline"],
        identityStatements: [
          "I want to become someone who is more disciplined",
          "I want to become a healthier person",
        ],
        constraints: ["Limited morning time"],
        badHabits: ["Too much screen time", "Skipping meals"],
        currentLifePhase: "Career building",
      });
    }

    await UserProfile.create(profileData);
    console.log("  📋 Created profile");

    // Create life areas
    const lifeAreas = await LifeArea.insertMany(
      DEFAULT_LIFE_AREAS.map((area, index) => ({
        ...area,
        userId: user._id,
        isActive: seedUser.isOnboarded && index < 4, // Activate first 4 for onboarded users
        priority: index + 1,
      })),
    );
    console.log(`  🎯 Created ${lifeAreas.length} life areas`);

    // Create habits for onboarded users
    if (seedUser.isOnboarded) {
      const activeAreas = lifeAreas.filter((a) => a.isActive);

      const sampleHabits = [
        {
          name: "Morning Meditation",
          description: "10 minutes of mindfulness meditation",
          lifeAreaId: activeAreas[2]?._id, // Mental & Emotional
          goalStatement: "Develop daily mindfulness practice",
          valueAlignment: "Peace",
          targetFrequency: 7,
          durationMinutes: 10,
          difficultyLevel: "easy",
          isBuildingHabit: true,
          completionRate: 0.8,
        },
        {
          name: "Read 20 Pages",
          description: "Read at least 20 pages of a non-fiction book",
          lifeAreaId: activeAreas[0]?._id, // Academic Growth
          goalStatement: "Read 24 books this year",
          valueAlignment: "Growth",
          targetFrequency: 5,
          durationMinutes: 30,
          difficultyLevel: "medium",
          isBuildingHabit: true,
          completionRate: 0.6,
        },
        {
          name: "Exercise",
          description: "30-minute workout session",
          lifeAreaId: activeAreas[3]?._id, // Physical Health
          goalStatement: "Maintain consistent exercise routine",
          valueAlignment: "Health",
          targetFrequency: 5,
          durationMinutes: 30,
          difficultyLevel: "medium",
          isBuildingHabit: true,
          completionRate: 0.7,
        },
        {
          name: "Code Practice",
          description: "Solve one coding challenge or work on side project",
          lifeAreaId: activeAreas[1]?._id, // Professional Growth
          goalStatement: "Improve technical skills",
          valueAlignment: "Discipline",
          targetFrequency: 5,
          durationMinutes: 45,
          difficultyLevel: "challenging",
          isBuildingHabit: true,
          completionRate: 0.5,
        },
        {
          name: "Reduce Social Media",
          description: "Limit social media to under 30 minutes daily",
          lifeAreaId: activeAreas[2]?._id, // Mental & Emotional
          goalStatement: "Break social media addiction",
          valueAlignment: "Discipline",
          targetFrequency: 7,
          durationMinutes: 1,
          difficultyLevel: "challenging",
          isBuildingHabit: false,
          completionRate: 0.4,
        },
      ];

      for (const habitData of sampleHabits) {
        if (!habitData.lifeAreaId) continue;

        const { completionRate, ...habitFields } = habitData;
        const completionRecord = generateCompletionRecord(30, completionRate);

        // Calculate streak
        let currentStreak = 0;
        const now = new Date();
        for (let i = 0; i < 365; i++) {
          const date = new Date(now);
          date.setDate(date.getDate() - i);
          const year = date.getFullYear();
          const month = String(date.getMonth() + 1).padStart(2, "0");
          const day = String(date.getDate()).padStart(2, "0");
          const dateKey = `${year}-${month}-${day}`;
          if (completionRecord.get(dateKey) === true) {
            currentStreak++;
          } else {
            break;
          }
        }

        await Habit.create({
          ...habitFields,
          userId: user._id,
          completionRecord,
          currentStreak,
          longestStreak: Math.max(
            currentStreak,
            Math.floor(Math.random() * 15) + 3,
          ),
        });
      }

      console.log(`  ✅ Created ${sampleHabits.length} habits`);
    }
  }

  console.log("\n🌱 Seed completed successfully!\n");
  console.log("  Test accounts:");
  console.log("  ─────────────────────────────────────────");
  console.log("  john@example.com / password123 (onboarded)");
  console.log("  jane@example.com / password123 (onboarded)");
  console.log("  newuser@example.com / password123 (not onboarded)");
  console.log("");
}

// Run seed
connectDatabase()
  .then(() => seed())
  .then(() => disconnectDatabase())
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exit(1);
  });
