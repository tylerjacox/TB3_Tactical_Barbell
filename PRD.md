# Tactical Barbell PWA — Product Requirements Document

## 1. Overview

A mobile-first Progressive Web App (PWA) optimized for iOS that replaces the existing Google Sheets-based Tactical Barbell training tracker. The app generates percentage-based strength programs, displays plate loading breakdowns, tracks training sessions, and stores historical 1RM data — all offline-capable and installable to the iOS home screen.

---

## 2. Goals

- **Replace the spreadsheet entirely** — all current functionality must exist in the PWA
- **iOS-optimized** — designed for Safari PWA behavior, safe area insets, standalone display, haptic-style interactions
- **Offline-first** — full functionality with no network connection via Service Worker + local storage
- **Fast data entry** — minimize taps during a workout; one-handed operation where possible
- **Plate math at a glance** — every working weight shows the exact plate breakdown per side

---

## 3. Target Platform & Technical Constraints

| Concern | Detail |
|---|---|
| Primary platform | iOS Safari (Add to Home Screen PWA) |
| Display mode | `standalone` via web app manifest |
| Viewport | Respect `env(safe-area-inset-*)` for notch/home indicator |
| Touch targets | Minimum 44x44pt per Apple HIG |
| Status bar | `apple-mobile-web-app-status-bar-style: black-translucent` |
| Splash screens | Apple touch startup images for common iPhone resolutions |
| Storage | `localStorage` or IndexedDB — no server/backend |
| Offline | Service Worker with cache-first strategy for all app assets |
| Framework | Vanilla JS, or lightweight framework (Preact/Svelte preferred over React for bundle size) |
| No dependencies on** | Google Sheets, network APIs, user accounts, or authentication |

---

## 4. Information Architecture

```
Home (Dashboard)
├── Active Program (current template + week at a glance)
├── Today's Session (quick-start the next workout)
│
Settings / Entry
├── 1RM Entry (lifts, weights, reps, true max vs training max)
├── Rounding Increment (2.5 or 5)
├── Plate Inventory (customize available plates per side)
├── Template Selection
│
Templates (read-only structure, populated by 1RM data)
├── Operator (6 weeks, 6 sessions/week)
├── Mass Template (3 weeks, 6 sessions/week)
├── Zulu (6 weeks, 4 sessions/week, A/B split)
├── Fighter (6 weeks, 2 sessions/week)
├── Gladiator (6 weeks, 3 sessions/week)
├── Mass (6 weeks, 3 sessions/week)
├── Grey Man (12 weeks, 3 sessions/week)
│
Session View (active workout)
├── Exercise list with weight + plate breakdown
├── Set/rep tracking with tap-to-complete
├── Rest timer
│
History
├── 1RM Test Log (date, lift, weight, reps, calculated 1RM)
├── Completed Sessions Log
```

---

## 5. Feature Specifications

### 5.1 — 1RM Entry & Calculation

**Purpose:** User inputs lift data; app calculates 1 Rep Max and all training percentages.

**Inputs:**
| Field | Type | Notes |
|---|---|---|
| Lift/Movement | Dropdown or preset | Squat, Bench, Deadlift, Military Press, Weighted Pull-up (user can leave lifts empty) |
| Weight | Number | Weight lifted |
| Reps | Number | Reps performed (1–15) |
| Max Type | Toggle | "True Max" or "Training Max" |
| Rounding Increment | Selector | 2.5 or 5 (default: 2.5) |

**1RM Formula** (Epley):
```
1RM = Weight × (1 + Reps / 30)
```
If Reps = 1, then 1RM = Weight (no formula needed).

**Percentage Table Output:**
Calculate and display weights at: **65%, 70%, 75%, 80%, 85%, 90%, 95%, 100%** of 1RM, each rounded to the configured rounding increment.

**Rounding logic:**
```
roundedWeight = Math.round(calculatedWeight / roundingIncrement) * roundingIncrement
```

---

### 5.2 — Plate Loading Calculator

**Purpose:** For every working weight, show the exact plates needed per side of the barbell (or on a belt for weighted pull-ups).

**Barbell Loading** (`LoadBarbellConstrained` equivalent):
- Barbell weight: **45 lb** (fixed)
- Weight per side: `(totalWeight - 45) / 2`
- Greedy algorithm: largest plates first, constrained by available inventory

**Default plate inventory (per side):**

| Plate (lb) | Available |
|---|---|
| 45 | 4 |
| 35 | 1 |
| 25 | 1 |
| 10 | 2 |
| 5 | 1 |
| 2.5 | 1 |
| 1.25 | 1 |

**Weighted Pull-up Loading** (`PullupWeightConstrained` equivalent):
- No barbell subtraction — total weight goes directly on the belt
- Different default inventory:

| Plate (lb) | Available |
|---|---|
| 45 | 2 |
| 35 | 1 |
| 25 | 1 |
| 10 | 2 |
| 5 | 1 |
| 2.5 | 1 |
| 1.25 | 1 |

**Display format:** `"350 = 3 x 45, 1 x 10, 1 x 5, 1 x 2.5"`

**Error case:** If plates are insufficient, show `"Not achievable with available plates"`

**Configurable:** User can edit plate inventory in Settings (quantities per plate size). Settings persist in local storage.

---

### 5.3 — Training Templates

Each template defines a multi-week cycle with prescribed sessions, 1RM percentages, sets, and reps. All weights are auto-calculated from the user's 1RM entries.

#### 5.3.1 — Operator

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 6 (3 strength + 3 endurance) |
| Lifts (strength) | Squat, Bench, Weighted Pull-up (sessions 1 & 3), + Deadlift (session 5) |
| Endurance sessions | Sessions 2, 4, 6 — user-defined duration ranges |

**Weekly percentage progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 75 | 85 | 95 |
| **Sets x Reps** | 3-5 x 5 | 3-5 x 5 | 3-4 x 3 | 3-5 x 5 | 3-5 x 3 | 3-4 x 1-2 |

**Endurance duration ranges:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Sessions 2 & 4 | 30-60 | 30-60 | 30-60 | 30 | 60-90 | 60-90 |
| Session 6 | 60-90 | 60-90 | 60-90 | 30 | 90-120 | 90-120 |

**Session structure:**
- **Sessions 1, 3:** Squat, Bench, Weighted Pull-up
- **Session 5:** Squat, Bench, Deadlift
- **Sessions 2, 4, 6:** Endurance (duration only)

Each strength exercise shows: **weight + plate breakdown**.

#### 5.3.2 — Mass Template

| Property | Value |
|---|---|
| Duration | 3 weeks |
| Sessions | 6 per cycle (Sessions 1, 3, 5: upper/lower; Session 6: deadlift) |

**Weekly percentage progression:**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| **% (Sessions 1, 3, 5)** | 65 | 75 | 80 |
| **Sets x Reps** | 4 x 8 | 4 x 6 | 4 x 3 |

**Session 6 (Deadlift day):**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| **%** | 65 | 75 | 80 |
| **Sets x Reps** | 4 x 5 | 4 x 5 | 1 x 3 |

**Session structure:**
- **Sessions 1, 3, 5:** Squat, Bench, Weighted Pull-up
- **Session 6:** Deadlift only

#### 5.3.3 — Zulu

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 4 (A/B split, each performed twice) |
| Variant | Standard or I/A (user selects via dropdown) |

**A/B Split clusters:**

| Day | Lifts |
|---|---|
| A | Military Press, Squat, Weighted Pull-up |
| B | Bench, Deadlift, (optional 3rd slot) |

**Two percentage sets per 6-week block:**

| Cluster | Weeks 1-3 % | Weeks 4-6 % |
|---|---|---|
| A/B One | 70, 80, 90 | 70, 80, 90 |
| A/B Two | 75, 80, 90 | 75, 80, 90 |

**Sets x Reps:** 3x5 (weeks 1-2, 4-5), 3x3 (weeks 3, 6)

**Lift selection:** User picks lifts from dropdown menus per cluster slot to maintain flexibility.

#### 5.3.4 — Fighter

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 2 (spread evenly, no back-to-back days) |

**Cluster lifts:** Squat, Bench, Military Press, Deadlift (user-selected)

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 75 | 80 | 90 | 75 | 80 | 90 |
| **Sets x Reps** | 3-5 x 5 | 3-5 x 5 | 3-5 x 3 | 3-5 x 5 | 3-5 x 5 | 3-5 x 3 |

#### 5.3.5 — Gladiator

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 3 |

**Cluster lifts:** Squat, Bench, Military Press, Deadlift

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 75 | 85 | 95 |
| **Sets x Reps** | 5 x 5 | 5 x 5 | 5 x 3 | 5 x 5 | 5 x 5 | 5 x 3-2-1 |

#### 5.3.6 — Mass

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 3 |
| Notes | No rest minimums |

**Cluster lifts:** Squat, Bench, Military Press, Deadlift

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 75 | 80 | 90 | 75 | 85 | 90 |
| **Sets x Reps** | 4 x 6 | 4 x 5 | 4 x 3 | 4 x 6 | 4 x 4 | 4 x 3 |

#### 5.3.7 — Grey Man

| Property | Value |
|---|---|
| Duration | 12 weeks |
| Sessions/week | 3 |

**Cluster lifts:** Squat, Bench, Weighted Pull-up, Deadlift

**Weekly progression (12-week cycle):**

| Week | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 70 | 80 | 90 | 75 | 85 | 95 | 75 | 85 | 95 |
| **Sets x Reps** | 3x6 | 3x5 | 3x3 | 3x6 | 3x5 | 3x3 | 3x6 | 3x5 | 3x1 | 3x6 | 3x5 | 3x1 |

---

### 5.4 — Active Program & Session Tracking

**Program activation:**
1. User selects a template
2. User selects a start date (or "Start Today")
3. App generates the full schedule with all sessions, weights, and plate breakdowns

**Dashboard (Home screen):**
- Current template name + week number
- Next session summary (lifts + weights)
- Quick-start button for today's session

**Session View (active workout):**
- List of exercises for that session
- Each exercise shows:
  - Exercise name
  - Working weight (bold, large)
  - Plate breakdown (e.g., `3x45 | 1x10 | 1x5 | 1x2.5`)
  - Prescribed sets x reps
  - Tap-to-complete set tracker (circles or checkboxes per set)
- Optional rest timer (configurable default: 2:00 for strength, 1:00 for accessories)
- Endurance sessions show prescribed duration range

**Completion:**
- Mark session complete
- Session logged to history with date and completion status

---

### 5.5 — History & 1RM Test Log

**1RM Test History:**
- Log entries with: date, lift, weight, reps, calculated 1RM
- Replaces the "Historical" sheet
- Shows progression over time per lift
- Existing data to seed:

| Date | Lift | Weight | Reps | 1RM |
|---|---|---|---|---|
| 2025-02-22 | Squat | 355 | 5 | 359.5 |
| 2025-02-22 | Bench | 315 | 3 | 300.2 |
| 2025-02-22 | Deadlift | 405 | 3 | 386.0 |
| 2025-02-22 | Weighted Pull-up | 45 | 5 | 45.6 |
| 2025-05-18 | Squat | 365 | 4 | 398.2 |
| 2025-05-18 | Bench | 315 | 3 | 333.5 |
| 2025-05-18 | Deadlift | 405 | 4 | 441.9 |
| 2025-05-18 | Weighted Pull-up | 70 | 5 | 78.8 |

**Completed Sessions Log:**
- Date, template, week, session number, exercises completed
- Simple list view, newest first

---

### 5.6 — Settings

| Setting | Type | Default | Notes |
|---|---|---|---|
| Rounding Increment | Selector (2.5 / 5) | 2.5 | Applied to all percentage calculations |
| Barbell Weight | Number | 45 | For plate calculator |
| Plate Inventory (Barbell) | Editable list | 4x45, 1x35, 1x25, 2x10, 1x5, 1x2.5, 1x1.25 | Per side |
| Plate Inventory (Belt/Pull-up) | Editable list | 2x45, 1x35, 1x25, 2x10, 1x5, 1x2.5, 1x1.25 | Total on belt |
| Rest Timer Default | Number (seconds) | 120 | Per-set rest timer |
| Theme | Toggle | System (light/dark) | Respect `prefers-color-scheme` |

All settings persist in `localStorage`.

---

## 6. iOS PWA Optimization Details

### 6.1 — Manifest & Meta Tags
```json
{
  "name": "Tactical Barbell",
  "short_name": "TB3",
  "display": "standalone",
  "orientation": "portrait",
  "theme_color": "#000000",
  "background_color": "#000000",
  "start_url": "/",
  "scope": "/"
}
```

Required meta tags:
```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="TB3">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

### 6.2 — Safe Areas
All content padded with `env(safe-area-inset-*)` to avoid notch and home indicator overlap. Bottom navigation bar sits above the home indicator.

### 6.3 — Touch & Interaction
- All interactive elements >= 44x44pt
- Tap feedback via CSS `:active` states (slight scale/opacity change)
- `-webkit-tap-highlight-color: transparent`
- `overscroll-behavior: none` to prevent pull-to-refresh interference
- Momentum scrolling via `-webkit-overflow-scrolling: touch`
- Number inputs use `inputmode="decimal"` to trigger numeric keyboard

### 6.4 — Offline & Caching
- Service Worker caches all app shell assets on install
- Cache-first strategy for all static resources
- App is fully functional offline — no network required after initial load
- Data stored in `localStorage` (or IndexedDB for larger datasets)

### 6.5 — Splash Screens & Icons
- `apple-touch-icon` at 180x180
- Apple launch images for common iPhone sizes (iPhone SE through iPhone 16 Pro Max)
- App icon: bold, simple — barbell or "TB3" monogram

---

## 7. Data Model

```typescript
// Stored in localStorage / IndexedDB

interface UserProfile {
  lifts: LiftEntry[];
  maxType: 'true' | 'training';
  roundingIncrement: 2.5 | 5;
  barbellWeight: number;
  plateInventoryBarbell: PlateInventory;
  plateInventoryBelt: PlateInventory;
  restTimerDefault: number;
  theme: 'light' | 'dark' | 'system';
}

interface LiftEntry {
  name: string;          // "Squat", "Bench", "Deadlift", "Military Press", "Weighted Pull-up"
  weight: number;
  reps: number;
  oneRepMax: number;     // calculated
  isBodyweight: boolean; // true for Weighted Pull-up (uses belt plate calc)
}

interface PlateInventory {
  plates: { weight: number; available: number }[];
}

interface ActiveProgram {
  templateId: string;
  startDate: string;     // ISO date
  currentWeek: number;
  currentSession: number;
  liftSelections?: Record<string, string>; // for Zulu/Fighter cluster customization
}

interface SessionLog {
  id: string;
  date: string;
  templateId: string;
  week: number;
  sessionNumber: number;
  exercises: ExerciseLog[];
  completed: boolean;
}

interface ExerciseLog {
  liftName: string;
  targetWeight: number;
  setsCompleted: number;
  repsPerSet: number[];
}

interface OneRepMaxTest {
  id: string;
  date: string;
  liftName: string;
  weight: number;
  reps: number;
  calculatedMax: number;
}
```

---

## 8. Navigation

Bottom tab bar (4 tabs):

| Tab | Icon | View |
|---|---|---|
| **Home** | House | Dashboard — active program, next session, quick-start |
| **Program** | Calendar | Template browser + active program schedule |
| **History** | Clock | 1RM test log + completed sessions |
| **Settings** | Gear | 1RM entry, plate config, preferences |

---

## 9. Visual Design Direction

- **Dark mode default** — high contrast for gym readability
- Large, bold weight numbers (32px+)
- Plate breakdown in smaller monospace text below the weight
- Minimal color palette: dark background, white text, one accent color (blue or orange) for interactive elements
- Card-based layout for exercises in session view
- Week/session grid for program overview
- No unnecessary decoration — information density prioritized

---

## 10. Out of Scope (v1)

- User accounts / cloud sync / backend
- Social features / sharing
- Exercise video demos
- Custom template builder (only the 7 predefined templates)
- Barbell/dumbbell exercise alternatives
- Conditioning protocol programming (beyond endurance duration ranges)
- Export/import from Google Sheets
- Android-specific optimizations (PWA will work, but iOS is priority)

---

## 11. Success Criteria

1. User can enter 1RM data and see all 7 templates fully populated with correct weights and plate breakdowns — matching the spreadsheet output exactly
2. App installs to iOS home screen and works fully offline
3. User can run through a full workout session with tap-to-complete tracking
4. All data persists across sessions via local storage
5. Plate calculator output matches the existing `LoadBarbellConstrained` and `PullupWeightConstrained` functions for all test cases
