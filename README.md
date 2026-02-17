# TB3 — Tactical Barbell PWA

A progressive web app for tracking strength training programs based on the Tactical Barbell methodology. Runs entirely in the browser with offline support, installable on iOS/Android home screens.

## Features

- **7 Training Templates** — Operator, Zulu, Fighter, Gladiator, Mass Protocol, Mass Strength, Grey Man with correct periodization, set/rep schemes, and percentage progressions
- **1RM Calculator** — Epley formula with training max (90%) support, percentage tables at 65-100%
- **Plate Calculator** — Greedy algorithm for barbell and weight belt loading with visual diagrams showing color-coded competition plates
- **Schedule Generator** — Pre-computes all weights and plate breakdowns for every session in your program cycle
- **Active Workout Tracking** — Set-by-set tracking with rest timers, weight overrides, undo, auto-regulate sets (finish early after minimum), and session persistence (survives app crashes/force-quit)
- **1RM Progression Charts** — SVG line graphs with Day/Week/Month/Year/All time range filtering

### Visual Plate Loading

Every exercise shows a color-coded barbell or belt diagram so you can load plates at a glance. Heaviest plates sit closest to the collar, with a legend showing the exact breakdown per side.

<p align="center">
  <img src="docs/plate-display.png" alt="Barbell and belt plate loading diagrams" width="390">
</p>

### 1RM Progression Chart

Track your strength gains over time with per-lift line graphs. Filter by Day, Week, Month, Year, or All to see short-term and long-term trends.

<p align="center">
  <img src="docs/progression-chart.png" alt="1RM progression chart with time range filtering" width="390">
</p>
- **Session History** — Complete log of all completed workouts with exercise details
- **Data Export/Import** — JSON export via Web Share API with 12-step validated import
- **Cloud Sync** — Cross-device sync via Cognito authentication with automatic token refresh, Google OAuth2 PKCE support
- **Offline-First** — Service worker with precaching and auto-update, works without network
- **Chromecast Support** — Cast your active workout to a TV via Google Cast with two-column layout showing exercise, weight, color-coded barbell plate diagram, sets, rest timer, session elapsed time, current clock, and exercise progress (Android/desktop Chrome)

### Chromecast Display

Cast your workout to any TV with a two-column layout optimized for 16:9 screens. Left side shows exercise, weight, and plate diagram; right side shows set progress, reps, and rest timer. Clock and session elapsed time update in real time.

<p align="center">
  <img src="docs/cast-screen.png" alt="Chromecast workout display with two-column layout" width="720">
</p>

- **iOS Optimized** — Safe area insets, Dynamic Type support, haptic feedback, standalone display

## Native iOS App

A native SwiftUI companion app with full feature parity. Shares the same Cognito auth and sync backend as the PWA.

<p align="center">
  <img src="docs/ios-dashboard.png" alt="Dashboard with plate loading" width="200">
  <img src="docs/ios-program.png" alt="Program schedule view" width="200">
  <img src="docs/ios-history.png" alt="Calendar history view" width="200">
  <img src="docs/ios-profile.png" alt="Profile and settings" width="200">
</p>

- **SwiftUI + SwiftData** with `@Observable` state management
- **Dark theme** matching the web app (pure black OLED background, #1A1A1A cards, #FF9500 accent)
- **Chromecast support** via Google Cast SDK (CocoaPods)
- **Visual plate loading** — barbell and belt diagrams with competition plate colors
- **Two-phase timer** — rest count-up with overtime + exercise duration tracking
- **Voice announcements** — countdown milestones with configurable voice
- **Calendar history** — monthly calendar view with workout dots
- **Custom tab bar** — avoids iOS 26 floating glass style

### Build & Run

```bash
cd ios
pod install
xcodebuild -workspace TB3.xcworkspace -scheme TB3 -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
```

## Tech Stack

| Layer | Technology |
|---|---|
| **Web** | |
| UI Framework | [Preact](https://preactjs.com/) 10 + [Preact Signals](https://preactjs.com/guide/v10/signals/) |
| Build | [Vite](https://vitejs.dev/) 6 + TypeScript 5 |
| PWA | [vite-plugin-pwa](https://vite-pwa-org.netlify.app/) (Workbox) |
| Storage | IndexedDB via [idb-keyval](https://github.com/nicedoc/idb-keyval) |
| **iOS** | |
| UI Framework | SwiftUI + SwiftData |
| State | `@Observable` AppState + Preact Signals-style architecture |
| Cast | Google Cast SDK via CocoaPods |
| **Shared Backend** | |
| Auth | [Amazon Cognito](https://aws.amazon.com/cognito/) (SRP + Google OAuth2 PKCE) |
| API | AWS API Gateway HTTP API + Lambda (Node.js 20) |
| Database | DynamoDB (single-table, PAY_PER_REQUEST) |
| Hosting | S3 + CloudFront (OAC, HTTPS, security headers) |
| IaC | [AWS CDK](https://aws.amazon.com/cdk/) v2 (TypeScript) |

## Project Structure

```
TB3_PWA/
├── app/                          # Frontend PWA
│   ├── src/
│   │   ├── calculators/          # 1RM and plate math
│   │   │   ├── oneRepMax.ts      # Epley formula, training max, percentage tables
│   │   │   └── plates.ts         # Greedy plate loading for barbell and belt
│   │   ├── components/           # Reusable UI components
│   │   │   ├── session/          # Workout session components
│   │   │   ├── CastButton.tsx    # Chromecast cast-to-TV button
│   │   │   ├── ConfirmDialog.tsx  # Modal with focus trap
│   │   │   ├── Icons.tsx         # Inline SVG icon set
│   │   │   ├── Layout.tsx        # Safe area + scroll wrapper
│   │   │   ├── MaxChart.tsx      # SVG 1RM progression chart
│   │   │   ├── PlateDisplay.tsx  # Visual barbell/belt plate diagrams
│   │   │   ├── TabBar.tsx        # Bottom navigation
│   │   │   └── ...
│   │   ├── hooks/                # Preact hooks
│   │   │   ├── useAuth.ts        # Authentication state hook
│   │   │   └── useSync.ts        # Cloud sync hook
│   │   ├── screens/              # Page-level components
│   │   │   ├── auth/             # Login, SignUp, ForgotPassword, ConfirmEmail
│   │   │   ├── onboarding/       # 4-step setup wizard
│   │   │   ├── Dashboard.tsx     # Home screen with next session
│   │   │   ├── History.tsx       # Session log + 1RM chart
│   │   │   ├── Profile.tsx       # Settings, 1RM entry, plate inventory
│   │   │   ├── Program.tsx       # Template browser + active schedule
│   │   │   └── Session.tsx       # Active workout tracker
│   │   ├── services/             # Business logic
│   │   │   ├── auth.ts           # Cognito authentication (SRP)
│   │   │   ├── cast.ts           # Google Cast sender (lazy SDK, state sync)
│   │   │   ├── storage.ts        # IndexedDB persistence
│   │   │   ├── sync.ts           # Cloud sync with push/pull
│   │   │   ├── validation.ts     # Data validation + import safety
│   │   │   ├── exportImport.ts   # JSON export/import
│   │   │   ├── feedback.ts       # Haptics + audio feedback (iOS AudioContext unlock)
│   │   │   └── ...
│   │   ├── templates/            # Training program definitions
│   │   │   ├── definitions.ts    # All 7 template data objects
│   │   │   └── schedule.ts       # Schedule generator
│   │   ├── app.tsx               # Root component + router
│   │   ├── cast.d.ts             # Google Cast SDK type declarations
│   │   ├── types.ts              # TypeScript interfaces
│   │   ├── state.ts              # Global signal state
│   │   ├── version.ts            # Build-time version from package.json
│   │   ├── router.ts             # Hash-based router
│   │   └── style.css             # Design system
│   ├── cast-receiver/
│   │   ├── index.html            # Chromecast custom receiver (standalone, no build)
│   │   └── receiver.js           # Receiver logic (external for CSP compliance)
│   ├── index.html
│   ├── vite.config.ts
│   └── package.json
├── infra/                        # AWS CDK infrastructure
│   ├── lib/
│   │   ├── tb3-stack.ts          # S3, CloudFront, Cognito
│   │   └── tb3-api-stack.ts      # API Gateway, Lambda, DynamoDB
│   ├── lambda/
│   │   └── sync.ts               # Sync endpoint (push/pull)
│   ├── iam/
│   │   ├── setup-deployer.sh     # IAM user creation script
│   │   └── tb3-deployer-policy.json
│   └── package.json
├── ios/                          # Native iOS app
│   ├── TB3/
│   │   ├── Calculators/          # 1RM and plate math (mirrors web)
│   │   ├── Config/               # App configuration
│   │   ├── Extensions/           # Color+TB3, Date+Formatting, Keychain
│   │   ├── Models/               # SwiftData models + sync payloads
│   │   ├── Networking/           # API client, auth, sync, token management
│   │   ├── Services/             # Feedback (haptics/voice), validation, export/import, Cast SDK bridge
│   │   ├── State/                # AppState, AuthState, SyncState, CastState, ActiveSession
│   │   ├── Templates/            # Template definitions + schedule generator
│   │   ├── ViewModels/           # Auth, Onboarding, Profile, Session view models
│   │   └── Views/                # SwiftUI views (Auth, Dashboard, History, Onboarding, Profile, Program, Session)
│   ├── TB3Tests/
│   │   ├── Calculators/          # OneRepMax + PlateCalculator tests
│   │   ├── Extensions/           # Date formatting tests
│   │   ├── Fixtures/             # Shared test fixtures
│   │   ├── Models/               # Enum + SyncPayload Codable tests
│   │   ├── Services/             # Validation + FeedbackService tests
│   │   ├── State/                # AppState tests
│   │   ├── Templates/            # Schedule generator + template definition tests
│   │   └── ViewModels/           # SessionViewModel tests
│   ├── TB3.xcodeproj/
│   ├── TB3.xcworkspace/          # Use this (CocoaPods)
│   └── Podfile
├── deploy.sh                     # Build + S3 sync + CloudFront invalidation
└── .gitignore
```

## Prerequisites

- **Node.js** 20+
- **AWS CLI** v2, configured with credentials
- **AWS CDK** v2 (`npm install -g aws-cdk`)
- An AWS account with CDK bootstrapped (`cdk bootstrap`)

## Getting Started

### 1. Clone and install dependencies

```bash
git clone https://github.com/tylerjacox/TB3_PWA.git
cd TB3_PWA

cd app && npm install && cd ..
cd infra && npm install && cd ..
```

### 2. Deploy infrastructure

Create the deployer IAM user (requires admin credentials):

```bash
bash infra/iam/setup-deployer.sh
aws configure --profile tb3-deployer
```

Deploy the CDK stacks:

```bash
cd infra
AWS_PROFILE=tb3-deployer npx cdk deploy --all
cd ..
```

This creates:
- **Tb3Stack** — S3 bucket, CloudFront distribution, Cognito User Pool
- **Tb3ApiStack** — API Gateway, Lambda sync function, DynamoDB table

### 3. Build and deploy the app

```bash
AWS_PROFILE=tb3-deployer bash deploy.sh
```

The deploy script automatically:
1. Reads CloudFormation stack outputs (Cognito IDs, API URL)
2. Generates `app/.env.production` with the correct values
3. Builds the Vite app with TypeScript checks
4. Syncs hashed assets to S3 with immutable cache headers
5. Uploads `index.html`, `sw.js`, `manifest.webmanifest` with `must-revalidate`
6. Uploads Cast receiver files (`cast-receiver/index.html`, `receiver.js`) with `must-revalidate`
7. Invalidates CloudFront for non-cached files
8. Prints the live site URL

### 4. Local development

```bash
cp app/.env.example app/.env.local
# Edit .env.local with your Cognito/API values from the CDK outputs

cd app
npm run dev
```

## Environment Variables

| Variable | Description |
|---|---|
| `VITE_COGNITO_USER_POOL_ID` | Cognito User Pool ID (e.g., `us-west-2_aBcDeFgHi`) |
| `VITE_COGNITO_CLIENT_ID` | Cognito App Client ID |
| `VITE_COGNITO_REGION` | AWS region (e.g., `us-west-2`) |
| `VITE_COGNITO_DOMAIN` | Cognito hosted UI domain (e.g., `https://tb3-auth.auth.us-west-2.amazoncognito.com`) |
| `VITE_API_URL` | API Gateway endpoint URL |

These are injected at build time by Vite. For production deploys, `deploy.sh` generates them automatically from CloudFormation outputs. For local dev, copy `app/.env.example` to `app/.env.local` and fill in the values.

## Training Templates

| Template | Days/Week | Duration | Description |
|---|---|---|---|
| **Operator** | 3 | 6 weeks | Standard strength template with fixed lifts |
| **Zulu** | 4 | 6 weeks | A/B cluster split with different percentages per cluster |
| **Fighter** | 2 | 6 weeks | Minimal strength — 2-3 lifts, compatible with high skill work |
| **Gladiator** | 3 | 6 weeks | All cluster lifts every session, week 6 descending sets |
| **Mass Protocol** | 3 | 6 weeks | Hypertrophy-focused, all lifts every session, no rest minimums |
| **Mass Strength** | 3 | 3 weeks | Squat/Bench/WPU + Deadlift alternating sessions |
| **Grey Man** | 3 | 12 weeks | Extended cycle, all cluster lifts every session |

All templates follow the Tactical Barbell periodization model with progressive percentage loading across weeks.

## Testing

### Web (Vitest)

```bash
cd app && npm test
```

167 tests across 11 files covering calculators, templates, schedule generation, validation, storage, and export/import.

### iOS (XCTest)

```bash
cd ios
xcodebuild -workspace TB3.xcworkspace -scheme TB3 -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

174 tests across 12 files:

| Suite | Tests | Coverage |
|---|---|---|
| SessionViewModelTests | 24 | Session state, set completion, undo, timer, exercise navigation |
| SyncPayloadTests | 18 | Codable round-trips for all sync types, RepsPerSet encoding |
| TemplateDefinitionTests | 18 | All 7 templates, session counts, percentages, set ranges |
| ScheduleGeneratorTests | 16 | Full schedule generation, plate breakdowns, week progression |
| OneRepMaxCalculatorTests | 15 | Epley formula, training max, rounding, percentage tables |
| PlateCalculatorTests | 15 | Barbell/belt loading, greedy algorithm, edge cases |
| EnumTests | 15 | LiftName, TemplateId, TimerPhase, WorkoutStatus, SoundMode |
| AppStateTests | 14 | Current lifts derivation, max type handling, schedule staleness |
| DateFormattingTests | 14 | ISO8601 parsing/output, display formats, ID generation |
| ValidationServiceTests | 14 | Runtime validation + 12-step import validation |
| FeedbackServiceTests | 11 | Voice milestones, configuration, sound modes |

## Architecture

### Data Flow

```
User action → Signal update → IndexedDB write → UI re-render
                                    ↓
                              Sync service (optional)
                                    ↓
                            API Gateway → Lambda → DynamoDB
```

- **Offline-first**: All data lives in IndexedDB. The app works fully without network.
- **Write-through**: Every state change persists to IndexedDB immediately.
- **Cloud sync**: Push/pull sync via authenticated API with automatic token refresh on 401. Last-write-wins for singletons (profile, active program), union-by-ID for sessions and 1RM tests.

### Schedule Pre-Computation

When a user starts a program, the schedule generator pre-computes every session for the entire cycle:

1. Takes template definition + user's current 1RM values + plate inventory
2. Calculates target weight per exercise per week (1RM × training max × week percentage)
3. Rounds to user's increment (2.5 or 5 lb)
4. Runs the plate calculator for each weight
5. Stores the full `ComputedSchedule` — no recalculation needed during workouts

A `sourceHash` detects when inputs change (new 1RM test, plate inventory edit) and prompts regeneration.

### Session Persistence

Active workout state is saved to IndexedDB on every set completion. If the app crashes, is force-quit, or the phone dies, the workout resumes exactly where it left off. Sessions older than 24 hours prompt the user to resume or discard.

## Security

- **CloudFront security headers**: CSP, HSTS, X-Frame-Options DENY, X-Content-Type-Options
- **Cognito SRP + OAuth2 PKCE auth**: Password never sent in plaintext; Google sign-in uses PKCE (no client secret on frontend)
- **User enumeration prevention**: `preventUserExistenceErrors` enabled on Cognito client
- **API authorization**: JWT authorizer on API Gateway, Lambda validates `sub` claim
- **DynamoDB isolation**: All items keyed by `USER#{cognitoUserId}`, no cross-user access
- **Import validation**: 12-step validation with prototype pollution defense, size limits, type checking
- **S3 private**: Bucket is `BLOCK_ALL` public access, CloudFront OAC only

## License

All rights reserved.
