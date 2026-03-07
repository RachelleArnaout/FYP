# Habit Tracker API

Backend API for the Habit Tracker Flutter mobile app, built with **Node.js**, **Express**, **MongoDB/Mongoose**, and **TypeScript**.

## Architecture

```
src/
├── config/          # Environment variables & database connection
├── controllers/     # Request handlers (thin layer, delegates to services)
├── middleware/       # Auth, validation, error handling
├── models/          # Mongoose schemas & models
├── routes/          # Express route definitions with validation
├── services/        # Business logic layer
├── seeds/           # Database seed scripts
├── types/           # TypeScript interfaces, enums, and types
├── app.ts           # Express app setup
└── server.ts        # Server entry point
```

## Entities

| Entity       | Description                                    |
|-------------|------------------------------------------------|
| **User**        | Authentication (email, password, name, onboarding status) |
| **UserProfile** | Detailed profile (values, energy, stress, lifestyle, etc.) |
| **LifeArea**    | Categories for habits (8 defaults created per user) |
| **Habit**       | Trackable habits with completion records & streaks |

## API Endpoints

### Auth (`/api/auth`)
| Method | Path                    | Auth | Description          |
|--------|------------------------|------|----------------------|
| POST   | `/register`            | No   | Create new account   |
| POST   | `/login`               | No   | Login                |
| GET    | `/me`                  | Yes  | Get current user     |
| PATCH  | `/complete-onboarding` | Yes  | Mark user onboarded  |

### User Profile (`/api/profile`)
| Method | Path | Auth | Description    |
|--------|------|------|----------------|
| GET    | `/`  | Yes  | Get profile    |
| PUT    | `/`  | Yes  | Update profile |

### Life Areas (`/api/life-areas`)
| Method | Path           | Auth | Description          |
|--------|---------------|------|----------------------|
| GET    | `/`           | Yes  | List all             |
| GET    | `/active`     | Yes  | List active only     |
| GET    | `/:id`        | Yes  | Get by ID            |
| POST   | `/`           | Yes  | Create custom area   |
| PUT    | `/:id`        | Yes  | Update area          |
| PATCH  | `/:id/toggle` | Yes  | Toggle active state  |
| DELETE | `/:id`        | Yes  | Delete area          |

### Habits (`/api/habits`)
| Method | Path                        | Auth | Description                |
|--------|-----------------------------|------|----------------------------|
| GET    | `/`                         | Yes  | List all habits            |
| GET    | `/active`                   | Yes  | List active habits         |
| GET    | `/life-area/:lifeAreaId`    | Yes  | List habits by life area   |
| GET    | `/analytics/overview?days=` | Yes  | Get analytics overview     |
| GET    | `/:id`                      | Yes  | Get habit by ID            |
| GET    | `/:id/consistency?days=`    | Yes  | Get consistency stats      |
| POST   | `/`                         | Yes  | Create habit               |
| PUT    | `/:id`                      | Yes  | Update habit               |
| DELETE | `/:id`                      | Yes  | Delete habit               |
| PATCH  | `/:id/completion`           | Yes  | Toggle daily completion    |

## Setup

### Prerequisites
- Node.js 18+
- MongoDB running locally (or remote URI)

### Install & Run

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Seed database with sample data
npm run seed

# Build for production
npm run build
npm start
```

### Environment Variables

Copy `.env.example` to `.env` and configure:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/habit-tracker
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d
NODE_ENV=development
```

### Seed Data

Run `npm run seed` to create test accounts:

| Email                | Password      | Status       |
|---------------------|---------------|--------------|
| john@example.com    | password123   | Onboarded    |
| jane@example.com    | password123   | Onboarded    |
| newuser@example.com | password123   | Not onboarded|
