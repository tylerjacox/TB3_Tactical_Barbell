# Tactical Barbell PWA — Product Requirements Document (v2)

> **Revision history:** v1 → v2 incorporates findings from PM, iOS Engineer, UX Designer, and QA Engineer reviews. All reviews preserved in `/reviews/`.

---

## 1. Overview

A mobile-first Progressive Web App (PWA) optimized for iOS that replaces the existing Google Sheets-based Tactical Barbell training tracker. The app generates percentage-based strength programs, displays plate loading breakdowns, tracks training sessions, and stores historical 1RM data — all offline-capable and installable to the iOS home screen.

**Units:** All weights are in **pounds (lb)** for v1. The data model includes a `unit` field to support future kg conversion.

---

## 2. Goals

- **Replace the spreadsheet entirely** — all current functionality must exist in the PWA
- **iOS-optimized** — designed for Safari PWA behavior, safe area insets, standalone display, haptic feedback
- **Offline-first** — full functionality with no network connection via Service Worker + IndexedDB
- **Gym-ready** — designed for sweaty hands, glare, distraction, one-handed use, phone-on-bench viewing
- **Plate math at a glance** — every working weight shows the exact plate breakdown per side
- **Data resilient** — export/import to protect against iOS storage eviction

---

## 3. Target Platform & Technical Constraints

| Concern | Detail |
|---|---|
| Primary platform | iOS Safari (Add to Home Screen PWA) |
| Display mode | `standalone` via web app manifest |
| Viewport | `100dvh` layout with `env(safe-area-inset-*)` for notch/home indicator |
| Touch targets | **56pt minimum** for session-critical actions (set completion, timer); 44pt minimum for all other interactive elements |
| Status bar | `apple-mobile-web-app-status-bar-style: black-translucent` |
| Storage | **IndexedDB** (primary) via `idb-keyval`. localStorage only for `schemaVersion` + `lastActiveTimestamp` |
| Offline | Service Worker: stale-while-revalidate for `index.html`, cache-first for hashed assets |
| Framework | **Preact 10.x** + Vite build. Preact Signals for state. ~7KB gzipped runtime |
| Routing | **Hash-based** (`/#/home`, `/#/program`, etc.) to avoid iOS standalone navigation bugs |
| CSS | Vanilla CSS with custom properties. No CSS-in-JS or Tailwind. `-apple-system` font stack |
| Bundle target | < 50KB gzipped total app shell |
| No dependencies on | Google Sheets, network APIs, user accounts, or authentication |

---

## 4. Information Architecture

```
Onboarding (first launch only)
├── Step 1: Enter your lifts (1RM entry)
├── Step 2: Choose your template
├── Step 3: Preview your first week
├── Step 4: Start training → drops into Dashboard

Home (Dashboard)
├── Active Program (template name + week + progress bar)
├── Next Session preview (lifts + weights)
├── Quick-start button
├── "Update Maxes" shortcut

Program
├── Template browser (with descriptions)
├── Active program week-by-week schedule
├── Program progress overview

History
├── 1RM Test Log (date, lift, weight, reps, calculated 1RM)
├── Completed Sessions Log

Profile & Settings
├── 1RM Entry / Update (primary position, not buried)
├── Rounding Increment
├── Plate Inventory (barbell + belt)
├── Barbell Weight
├── Rest Timer Default
├── Theme (Dark / Light / System)
├── Export Data (JSON)
├── Import Data (JSON)
├── About / Data Warning
```

---

## 5. Feature Specifications

### 5.0 — Onboarding (First Launch)

**Purpose:** Guide new users from install to first workout with zero friction.

**Flow:**
1. **Detect first launch:** If no profile exists in IndexedDB, show onboarding wizard instead of tab bar.
2. **Step 1 — "Enter Your Lifts":** Form for each core lift (Squat, Bench, Deadlift, Military Press, Weighted Pull-up). Each lift is optional — user enters Weight + Reps for lifts they train. Clear explanation: "Enter a recent heavy set. We'll calculate your max."
3. **Step 2 — "Choose Your Template":** Card selector showing all 7 templates with brief descriptions:
   - **Operator:** "Balanced strength + endurance. 3 strength days, 3 cardio days/week. 6-week cycle."
   - **Zulu:** "4 strength sessions/week. A/B split. 6-week cycle."
   - **Fighter:** "Minimal lifting. 2 sessions/week. 6-week cycle. For heavy conditioning schedules."
   - **Gladiator:** "High volume. 3 sessions/week. 5x5 base. 6-week cycle."
   - **Mass Protocol:** "Hypertrophy focus. 3 sessions/week. Higher reps. 6-week cycle."
   - **Mass Strength:** "Hypertrophy + strength. 3-week cycle with deadlift day."
   - **Grey Man:** "Low profile. 3 sessions/week. 12-week cycle."
4. **Step 3 — "Your First Week":** Show Week 1 sessions with calculated weights and plate breakdowns using the user's data. Instant value preview.
5. **Step 4 — "Start Training":** Set start date (default: today). Transition to Dashboard with active program.
6. **After onboarding:** Show "Add to Home Screen" instructions if not already in standalone mode (detect via `window.matchMedia('(display-mode: standalone)')`).

**Empty states:** If the user somehow reaches Dashboard/History/Program without data, each shows a purposeful empty state with a CTA linking to the appropriate setup step.

---

### 5.1 — 1RM Entry & Calculation

**Purpose:** User inputs lift data; app calculates 1 Rep Max and all training percentages.

**Available lifts:** Squat, Bench, Deadlift, Military Press, Weighted Pull-up. All lifts are optional — user only enters data for lifts they train.

**Weighted Pull-up clarification:** All weights for Weighted Pull-up refer to **added weight only** (the weight on the dip belt), not bodyweight + added weight. The plate calculator receives this value directly with no barbell subtraction.

**Inputs & validation:**

| Field | Type | Required | Min | Max | Default | Validation |
|---|---|---|---|---|---|---|
| Lift/Movement | Enum | Yes | — | — | — | One of the 5 preset lifts |
| Weight | Number | Yes | 1 | 1500 | — | Positive number. Decimals allowed to 0.25 lb granularity |
| Reps | Integer | Yes | 1 | 15 | — | Whole numbers only. `inputmode="numeric"` (not decimal) |
| Max Type | Toggle | Yes | — | — | Training Max | "True Max" or "Training Max" |
| Rounding Increment | Selector | Yes | — | — | 2.5 | 2.5 or 5 |

**1RM Formula (Epley):**
```
1RM = Weight × (1 + Reps / 30)
```
If Reps = 1, then `1RM = Weight` (bypass formula).

**Training Max vs True Max:**
- **True Max:** The calculated 1RM is used directly for all percentage calculations.
- **Training Max:** `TrainingMax = calculated1RM × 0.90`. All template percentages are applied to the Training Max, not the True Max. This is the standard Tactical Barbell convention and the **recommended default**.

Example: Weight=365, Reps=4 → Epley 1RM = 365 × (1 + 4/30) = 413.67. Training Max = 413.67 × 0.90 = 372.3. At 70%: 372.3 × 0.70 = 260.6, rounded to 260.

**Percentage Table Output:**
Calculate and display weights at **65%, 70%, 75%, 80%, 85%, 90%, 95%, 100%** of the working max (True Max or Training Max per user selection), each rounded to the configured rounding increment.

**Rounding logic:**
```
roundedWeight = Math.round(calculatedWeight / roundingIncrement) * roundingIncrement
```

**Floating-point guard:** Before plate calculation, round `perSideWeight` to nearest 0.01 to eliminate IEEE 754 artifacts.

**Missing lift handling:** If a template requires a lift the user hasn't entered (e.g., Military Press in Zulu), show "Set 1RM for Military Press" in place of the weight, with a tap-to-navigate to 1RM entry.

---

### 5.2 — Plate Loading Calculator

**Purpose:** For every working weight, show the exact plates needed per side of the barbell (or on a belt for weighted pull-ups).

**Barbell Loading:**
- Barbell weight: configurable (default **45 lb**)
- Weight per side: `(totalWeight - barbellWeight) / 2`
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

**Maximum achievable barbell weight** (default inventory): 45 + (268.75 × 2) = **582.5 lb**

**Weighted Pull-up Loading:**
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

**Maximum achievable belt weight** (default inventory): **178.75 lb**

**Display format:** Visual plate badges with count, always labeled **"per side"** for barbell or **"on belt"** for pull-ups.

Preferred rendering: `45 ×3  10  5  2.5  per side` — largest plate emphasized, smaller plates listed individually. Alternative: color-coded plate badges using competition plate colors.

**Special cases:**

| Condition | Display |
|---|---|
| Total weight = barbell weight (e.g., 45) | "Bar only" — no plate list |
| Weighted pull-up weight = 0 | "Bodyweight only" — no plate list |
| Total weight < barbell weight | "Weight is below bar weight" |
| Plates insufficient for target | "Not achievable with current plates" — show nearest achievable weight as suggestion |
| Negative or zero total weight | "Not achievable" (guard against invalid 1RM input) |

**Configurable:** User can edit plate inventory in Settings (quantities per plate size, min 0, max 20 per size). Settings persist in IndexedDB.

---

### 5.3 — Training Templates

Each template defines a multi-week cycle with prescribed sessions, 1RM percentages, sets, and reps. All weights are auto-calculated from the user's working max (True Max or Training Max per their setting).

**Sets/Reps range convention:** When a template specifies a range (e.g., "3-5 × 5"), the app displays the **maximum set count** (e.g., 5 sets of 5 reps). The user completes sets by tapping; they can stop early (completing only 3 of 5 sets is valid and logged). The tracker shows completed/remaining sets clearly.

#### 5.3.1 — Operator

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 6 (3 strength + 3 endurance, alternating) |
| Description | "Balanced strength + endurance. 3 strength days, 3 cardio days/week." |

**Weekly schedule (sessions always alternate strength/endurance):**
- **Session 1 (Strength):** Squat, Bench, Weighted Pull-up
- **Session 2 (Endurance):** Duration-based
- **Session 3 (Strength):** Squat, Bench, Weighted Pull-up
- **Session 4 (Endurance):** Duration-based
- **Session 5 (Strength):** Squat, Bench, Deadlift *(Weighted Pull-up swapped for Deadlift)*
- **Session 6 (Endurance):** Duration-based

**Weekly percentage progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 75 | 85 | 95 |
| **Sets × Reps** | 5×5 | 5×5 | 4×3 | 5×5 | 5×3 | 4×1 |

*Note: Sets shown are the maximum. User may perform fewer (minimum 3 for "3-5" ranges).*

**Endurance duration ranges (minutes):**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Sessions 2 & 4 | 30-60 | 30-60 | 30-60 | 30 | 60-90 | 60-90 |
| Session 6 | 60-90 | 60-90 | 60-90 | 30 | 90-120 | 90-120 |

#### 5.3.2 — Mass Strength *(renamed from "Mass Template" to avoid collision with 5.3.6)*

| Property | Value |
|---|---|
| Duration | 3 weeks (single cycle) |
| Sessions/cycle | 4 (Sessions 1, 3, 5: Squat/Bench/WPU; Session 6: Deadlift) |
| Description | "Hypertrophy + strength. Higher volume with a dedicated deadlift day. 3-week cycle." |

*Note: This template has 4 training sessions per cycle (not 6). Sessions 2 and 4 are rest/recovery days — no app tracking required.*

**Weekly percentage progression (Sessions 1, 3, 5):**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| **%** | 65 | 75 | 80 |
| **Sets × Reps** | 4×8 | 4×6 | 4×3 |

**Session 6 — Deadlift day:**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| **%** | 65 | 75 | 80 |
| **Sets × Reps** | 4×5 | 4×5 | 1×3 |

**Session structure:**
- **Session 1:** Squat, Bench, Weighted Pull-up
- **Session 3:** Squat, Bench, Weighted Pull-up
- **Session 5:** Squat, Bench, Weighted Pull-up
- **Session 6:** Deadlift only

#### 5.3.3 — Zulu

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 4 (A/B split, each performed twice: A1, B1, A2, B2) |
| Variant | **Standard only for v1.** I/A variant deferred to v1.1 (insufficient specification). |
| Description | "4 strength sessions/week. A/B split with two intensity levels per week." |

**A/B Split clusters (user-selectable lifts from dropdown, defaults shown):**

| Day | Default Lifts |
|---|---|
| A (3 lift slots) | Squat, Weighted Pull-up, *(optional: Military Press)* |
| B (2-3 lift slots) | Bench, Deadlift, *(optional 3rd slot: user choice or empty)* |

**Weekly schedule and percentage mapping:**

Each A and B day is performed twice per week. The first instance of each uses **Tier 1** percentages; the second instance uses **Tier 2** percentages.

| Week pattern | Tier 1 % (A1, B1) | Tier 2 % (A2, B2) | Sets × Reps |
|---|---|---|---|
| Weeks 1, 4 | 70 | 75 | 3×5 |
| Weeks 2, 5 | 80 | 80 | 3×5 |
| Weeks 3, 6 | 90 | 90 | 3×3 |

**Lift selection rules:** User picks lifts from dropdown per cluster slot. Only lifts with a 1RM entered are selectable. Minimum 2 lifts per cluster, maximum 3. Optional 3rd slot on B day can be left empty.

#### 5.3.4 — Fighter

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 2 (spread evenly, guidance: no back-to-back days) |
| Description | "Minimal lifting. 2 sessions/week. For heavy conditioning schedules." |

**Cluster:** User selects **2-3 lifts** from: Squat, Bench, Military Press, Deadlift. All selected lifts are performed in both sessions.

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 75 | 80 | 90 | 75 | 80 | 90 |
| **Sets × Reps** | 5×5 | 5×5 | 5×3 | 5×5 | 5×5 | 5×3 |

*Maximum 5 sets shown. User may perform as few as 3.*

#### 5.3.5 — Gladiator

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 3 |
| Description | "High volume. 3 sessions/week. 5×5 base. 6-week cycle." |

**Cluster lifts:** Squat, Bench, Deadlift *(Military Press optional 4th slot)*

**Session structure:**
- **Session 1:** Squat, Bench
- **Session 2:** Deadlift, *(Military Press if configured)*
- **Session 3:** Squat, Bench

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 75 | 85 | 95 |
| **Sets × Reps** | 5×5 | 5×5 | 5×3 | 5×5 | 5×5 | 5× descending (3,2,1,3,2) |

**Week 6 "descending" clarification:** 5 sets with reps: 3, 2, 1, 3, 2. Total: 11 reps across 5 sets at 95%. Display each set individually with its rep target.

#### 5.3.6 — Mass Protocol *(renamed from "Mass" to avoid collision with 5.3.2)*

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 3 |
| Notes | Rest timer hidden/optional for this template (no rest minimums) |
| Description | "Hypertrophy focus. 3 sessions/week. No rest minimums." |

**Cluster lifts:** Squat, Bench, Deadlift *(Military Press optional 4th slot)*

**Session structure:**
- **Session 1:** Squat, Bench
- **Session 2:** Deadlift, *(Military Press if configured)*
- **Session 3:** Squat, Bench

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 75 | 80 | 90 | 75 | 85 | 90 |
| **Sets × Reps** | 4×6 | 4×5 | 4×3 | 4×6 | 4×4 | 4×3 |

#### 5.3.7 — Grey Man

| Property | Value |
|---|---|
| Duration | 12 weeks |
| Sessions/week | 3 |
| Description | "Low profile. 3 sessions/week. 12-week cycle with progressive intensification." |

**Cluster lifts:** Squat, Bench, Weighted Pull-up, Deadlift

**Session structure:**
- **Session 1:** Squat, Bench
- **Session 2:** Deadlift, Weighted Pull-up
- **Session 3:** Squat, Bench

**Weekly progression (12-week cycle):**

| Week | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 70 | 80 | 90 | 75 | 85 | 95 | 75 | 85 | 95 |
| **Sets × Reps** | 3×6 | 3×5 | 3×3 | 3×6 | 3×5 | 3×3 | 3×6 | 3×5 | 3×1 | 3×6 | 3×5 | 3×1 |

---

### 5.4 — Active Program & Session Tracking

#### Program Lifecycle

1. **Activation:** User selects template → selects start date (default: today) → app pre-computes full schedule (all weeks, sessions, weights, plate breakdowns) and stores in IndexedDB as `computedSchedule`.
2. **Single program:** Only one program active at a time. Switching templates requires confirmation: *"Starting a new program will end your current Operator cycle (Week 3 of 6). Session history is preserved. Continue?"*
3. **Mid-program 1RM change:** Recalculate all **future** sessions automatically. Past completed sessions are immutable. Show brief confirmation: *"Weights updated for remaining sessions."*
4. **Program completion:** After the final session, show completion screen (summary of program, weeks completed). Prompt: *"Start a new cycle"* (same template, fresh) or *"Choose new template"* or *"Retest 1RM"* (navigates to 1RM entry).
5. **Program advancement:** Session-based, **not calendar-based**. The user advances by completing or skipping sessions. Missing a week does not auto-advance the program.

#### Dashboard (Home screen)

- Current template name + week number + progress bar (e.g., "Week 3 of 6")
- Next session preview: exercises with working weights
- Quick-start button (large, bottom-center, 64pt)
- "Update Maxes" shortcut button
- If workout is in progress: persistent "Return to Workout" bar at top

#### Session View (Active Workout) — PRIMARY SCREEN

**Information hierarchy (top to bottom per exercise card):**
1. **Exercise name** — small uppercase label (14pt, muted)
2. **Set progress** — most prominent element. Large: "SET 3 / 5" with visual dots/circles
3. **Working weight** — largest number (32-40pt, bold, white)
4. **Plate breakdown** — secondary line (14-16pt, monospace, labeled "per side" or "on belt")
5. **Reps target** — near set progress ("× 5 reps")
6. **Complete Set button** — full-width, bottom of card, **56pt minimum height**

**Exercise navigation:** Horizontal swipe between exercises (pager pattern). Current exercise is focused/expanded. Completed exercises show a checkmark overlay. Dot indicator at top shows position. Auto-advance to next exercise after all sets complete (1.5s delay, skippable).

**Set completion interaction:**
- Tap "Complete Set" → set circle fills with animation (scale 105%, spring easing), haptic tap
- **5-second undo toast** appears after each set completion ("Undo" action)
- After all sets: exercise card shows checkmark, auto-advances

**Failed rep logging:** If user taps the rep count, they can adjust actual reps (e.g., target was 5, only got 3). Data model tracks both `targetReps` and `actualReps`.

**Weight override:** Tap the weight number to override for this session only (e.g., plates unavailable). Override does not change 1RM.

**During active workout:**
- Bottom tab bar is **hidden** to prevent accidental navigation
- "End Workout" button available via top-right menu
- If user force-quits or backgrounds: session state is persisted to IndexedDB on every set completion. On next launch: "Resume workout?" prompt.

**Endurance session view:** Distinct from strength. Shows: prescribed duration range, start button, running count-up timer, and complete button. No sets/reps UI.

#### Session State Machine

```
NOT_STARTED  → IN_PROGRESS   (user taps "Start Session")
NOT_STARTED  → SKIPPED       (user skips to next session)
IN_PROGRESS  → COMPLETED     (user taps "Complete Session" or finishes all sets)
IN_PROGRESS  → PAUSED        (app backgrounded / user navigates away)
PAUSED       → IN_PROGRESS   (user returns — auto-resume prompt)
PAUSED       → ABANDONED     (paused > 24 hours without resuming)
```

On launch, if `activeSession` exists in IndexedDB: prompt "Resume workout from [Template] Week [N] Session [N]?" with Resume / Discard options.

---

### 5.5 — Rest Timer

**Trigger:** Auto-starts when user completes a set. Dismissible/skippable.

**Display:** Inline expansion within the current exercise card. Large countdown number (48pt+) with circular progress ring. Does not obscure exercise context.

**Controls:**
- Tap timer to **add 30 seconds**
- Tap "Skip" to dismiss immediately
- After timer reaches 0: show elapsed time ("Resting: 2:45") as passive nudge

**Completion notification:** Haptic pulse via Vibration API. Optional audio tone (configurable in settings).

**Background handling:** Timer uses `Date.now()` comparison (not `setInterval`). When app is foregrounded, calculate actual elapsed time and display correctly. iOS will kill `setInterval` in background.

**Default durations (percentage-aware):**

| Intensity | Default Rest |
|---|---|
| 90%+ (weeks 3, 6 of most templates) | 3:00 |
| 70-85% | 2:00 |
| < 70% | 1:30 |

User can override the default globally in Settings.

---

### 5.6 — History & 1RM Test Log

**1RM Test History:**
- Append-only log: date, lift, weight, reps, calculated 1RM, max type (true/training)
- Shows progression over time per lift
- Most recent entry per lift is used for all program calculations
- **No hardcoded seed data.** The user imports their history or enters fresh. (The spreadsheet seed data used a different formula and does not match Epley — hardcoding it would cause confusion.)

**Completed Sessions Log:**
- Date, template, week, session number, exercises with actual sets/reps completed
- Status: COMPLETED, PARTIAL (not all sets done), SKIPPED
- Immutable once logged — settings changes do not retroactively alter history
- Simple list view, newest first

**Session notes:** Optional free-text notes field per session (e.g., "Left knee felt tight," "Used belt on set 3").

---

### 5.7 — Settings & Profile

| Setting | Type | Min | Max | Default | Notes |
|---|---|---|---|---|---|
| Max Type | Toggle | — | — | Training Max | True Max or Training Max (0.90 multiplier) |
| Rounding Increment | Selector | — | — | 2.5 | 2.5 or 5 |
| Barbell Weight | Number | 15 | 100 | 45 | Supports women's bars (35), specialty bars |
| Plate Inventory (Barbell) | Editable per-plate qty | 0 | 20 | 4×45, 1×35, 1×25, 2×10, 1×5, 1×2.5, 1×1.25 | Per side |
| Plate Inventory (Belt) | Editable per-plate qty | 0 | 20 | 2×45, 1×35, 1×25, 2×10, 1×5, 1×2.5, 1×1.25 | Total on belt |
| Rest Timer Default | Seconds | 0 | 600 | 120 | 0 = disabled |
| Theme | 3-way toggle | — | — | Dark | Dark / Light / System |
| Unit | Display only (v1) | — | — | lb | Data model stores unit for future kg support |
| **Export Data** | Button | — | — | — | Exports full JSON to Files app via Web Share API, or clipboard fallback |
| **Import Data** | Button | — | — | — | File picker for JSON import. Validates schema before overwriting. |
| Last Backup Date | Display only | — | — | — | Shows when last export occurred |

**Backup reminder:** If `Date.now() - lastBackupDate > 7 days`, show non-blocking prompt: "It's been a while since your last backup. Tap to export your data."

**Data warning:** Visible in Settings: "All data is stored locally on this device. Clearing Safari data or not opening the app for extended periods may erase your data. Use Export regularly."

---

## 6. iOS PWA Technical Specification

### 6.1 — Manifest

```json
{
  "name": "Tactical Barbell",
  "short_name": "TB3",
  "display": "standalone",
  "theme_color": "#000000",
  "background_color": "#000000",
  "start_url": "/",
  "scope": "/",
  "icons": [...]
}
```

*Note: `orientation` omitted — iOS ignores it. Handle landscape via CSS (see 6.7).*

Required meta tags:
```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="TB3">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

### 6.2 — Safe Areas

```css
:root {
  --sat: env(safe-area-inset-top);
  --sab: env(safe-area-inset-bottom);
}
body { padding-top: var(--sat); }
.tab-bar { padding-bottom: var(--sab); height: calc(56px + var(--sab)); }
.main-content { height: calc(100dvh - var(--sat) - 56px - var(--sab)); overflow-y: auto; }
```

Use `100dvh` (not `100vh`) for full-height containers.

### 6.3 — Touch & Interaction

- Session-critical targets (set complete, timer): **56pt minimum**
- All other interactive elements: **44pt minimum**
- `touch-action: manipulation` on all buttons (removes 300ms tap delay)
- `-webkit-tap-highlight-color: transparent`
- `-webkit-user-select: none` on interactive elements
- `overscroll-behavior: none` on body
- Body is `position: fixed; overflow: hidden` — only inner containers scroll (prevents rubber-band)
- Number inputs: `inputmode="numeric"` for reps (integers), `inputmode="decimal"` for weights

### 6.4 — Keyboard Handling

Detect keyboard open via `visualViewport.resize`. When keyboard is open:
- Hide bottom tab bar
- Adjust main content height
- Prevent layout jank during number input (the most frequent interaction)

```javascript
window.visualViewport?.addEventListener('resize', () => {
  const keyboardOpen = window.visualViewport.height < window.innerHeight * 0.75;
  document.documentElement.classList.toggle('keyboard-open', keyboardOpen);
});
```

### 6.5 — Offline & Service Worker

**Cache strategy:**
- `index.html`: **Stale-while-revalidate** (allows update detection)
- Hashed assets (`app.[hash].js`, `app.[hash].css`): **Cache-first** (immutable)
- No external URLs cached

**Update flow:**
1. App launches, service worker serves cached version instantly
2. Background update check
3. If new version found: non-blocking toast "Update available. Tap to refresh."
4. User taps → `location.reload()`
5. Do NOT call `skipWaiting()` automatically (causes blank screen on iOS)

**Registration:** On `load` event (not `DOMContentLoaded`).

**Cache versioning:** `CACHE_VERSION` constant in service worker. On activation, delete non-matching caches.

### 6.6 — Storage Eviction Defense

Safari will purge all client-side storage after **7 days of no visit**. Multi-layer defense:

1. **Eviction detection:** On launch, check `document.cookie` for `tb3_active=1` (cookies with 1-year expiry survive ITP). If cookie exists but IndexedDB is empty → storage was evicted. Show recovery prompt.
2. **Periodic backup reminders:** If no export in 7+ days, prompt.
3. **Export/Import always available:** JSON export via Web Share API (saves to Files app). JSON import via file picker.
4. **URL-encoded 1RM recovery:** Encode current 1RM values into a shareable URL hash (~200 bytes). User can bookmark this as emergency recovery.
5. **Write-through on every meaningful action:** Every set completion, every 1RM update writes to IndexedDB immediately.

### 6.7 — Landscape Handling

iOS ignores `orientation: portrait` in manifest. If device rotates to landscape, show a "Please rotate to portrait" overlay rather than attempting responsive landscape layout.

### 6.8 — Splash Screens & Icons

- `apple-touch-icon` at 180×180
- Generate Apple launch images at build time via `pwa-asset-generator` from a single source image
- Or: use CSS-based loading screen (dark background + "TB3" text) to avoid maintaining 12+ image sizes

### 6.9 — Install Prompt

No `beforeinstallprompt` on iOS. Detect if running in-browser:
```javascript
const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
```
If in-browser, show persistent banner: "For the best experience, tap Share → Add to Home Screen."

---

## 7. Data Model

```typescript
// Primary store: IndexedDB database "tb3"

interface AppData {
  schemaVersion: number;  // Start at 1. Increment on every schema change.
  profile: UserProfile;
  activeProgram: ActiveProgram | null;
  computedSchedule: ComputedSchedule | null;
  activeSession: ActiveSessionState | null;  // Mid-workout persistence
  sessionHistory: SessionLog[];
  maxTestHistory: OneRepMaxTest[];
  lastBackupDate: string | null;  // ISO date
}

interface UserProfile {
  lifts: LiftEntry[];
  maxType: 'true' | 'training';
  roundingIncrement: 2.5 | 5;
  barbellWeight: number;
  plateInventoryBarbell: PlateInventory;
  plateInventoryBelt: PlateInventory;
  restTimerDefault: number;
  theme: 'light' | 'dark' | 'system';
  unit: 'lb' | 'kg';  // v1: always 'lb'. Reserved for future.
}

interface LiftEntry {
  name: string;          // "Squat" | "Bench" | "Deadlift" | "Military Press" | "Weighted Pull-up"
  weight: number;        // For WPU: added weight only (not bodyweight)
  reps: number;
  oneRepMax: number;     // Calculated via Epley
  workingMax: number;    // = oneRepMax if True Max; = oneRepMax * 0.90 if Training Max
  isBodyweight: boolean; // true for Weighted Pull-up (uses belt plate calc)
}

interface PlateInventory {
  plates: { weight: number; available: number }[];
}

interface ActiveProgram {
  templateId: string;
  startDate: string;
  currentWeek: number;
  currentSession: number;
  liftSelections?: Record<string, string>;  // Zulu/Fighter cluster customization
}

interface ComputedSchedule {
  // Pre-computed on program activation. Regenerated on 1RM or settings change.
  weeks: ComputedWeek[];
}

interface ComputedWeek {
  weekNumber: number;
  percentage: number;
  setsPerExercise: number;
  repsPerSet: number | number[];  // number[] for descending schemes like Gladiator Week 6
  sessions: ComputedSession[];
}

interface ComputedSession {
  sessionNumber: number;
  type: 'strength' | 'endurance';
  exercises: ComputedExercise[];
  enduranceDuration?: string;  // e.g., "30-60" for endurance sessions
}

interface ComputedExercise {
  liftName: string;
  targetWeight: number;
  plateBreakdown: string;
  plateBreakdownPerSide: { weight: number; count: number }[];
  achievable: boolean;
}

interface ActiveSessionState {
  // Persisted to IndexedDB on every set completion for crash recovery
  programWeek: number;
  programSession: number;
  startedAt: string;
  currentExerciseIndex: number;
  sets: {
    exerciseIndex: number;
    setNumber: number;
    targetReps: number;
    actualReps: number | null;  // null = not yet attempted
    completed: boolean;
    completedAt: string | null;
  }[];
  restTimerState: {
    running: boolean;
    targetEndTime: number | null;  // Date.now() based
  } | null;
}

interface SessionLog {
  id: string;
  date: string;
  templateId: string;
  week: number;
  sessionNumber: number;
  status: 'completed' | 'partial' | 'skipped';
  exercises: ExerciseLog[];
  notes: string;
  durationMinutes?: number;  // For endurance sessions
}

interface ExerciseLog {
  liftName: string;
  targetWeight: number;
  actualWeight: number;  // May differ if user overrode weight
  sets: {
    targetReps: number;
    actualReps: number;
    completed: boolean;
  }[];
  notes?: string;
}

interface OneRepMaxTest {
  id: string;
  date: string;
  liftName: string;
  weight: number;
  reps: number;
  calculatedMax: number;
  maxType: 'true' | 'training';
  workingMax: number;
}
```

**IndexedDB Schema:**
```
Database: "tb3"
  Store: "app"       → single record (key: "data") containing AppData
```

**Schema migration:** On app launch, read `schemaVersion`. If less than current code version, run sequential migration functions (v1→v2, v2→v3, etc.) before rendering.

---

## 8. Navigation

**Bottom tab bar (4 tabs):**

| Tab | Icon | View |
|---|---|---|
| **Home** | House | Dashboard — active program, next session, quick-start |
| **Program** | Calendar | Template browser + active program week-by-week schedule |
| **History** | Clock | 1RM test log + completed sessions |
| **Profile** | Person | 1RM entry *(primary position)*, plate config, settings, export/import |

*Renamed "Settings" → "Profile" to signal it contains primary data (1RM entry), not just preferences.*

**During active workout:** Tab bar is hidden. "End Workout" available via top-right. "Return to Workout" bar visible on all other screens if session is in progress.

**Routing:** Hash-based. `/#/home`, `/#/program`, `/#/program/week/3`, `/#/history`, `/#/profile`, `/#/session`.

---

## 9. Visual Design Direction

- **Dark mode default** — high contrast for gym readability under fluorescent/LED lighting
- **Accent color: orange/amber** (#FF9500) — maintains visibility under gym lighting better than blue; standard high-visibility color in fitness contexts
- Large, bold weight numbers (32-40pt, font-weight 700+, white on near-black)
- Plate breakdown in monospace (14pt minimum, `font-variant-numeric: tabular-nums` for stable layout)
- Card-based layout for exercises in session view
- `-apple-system` font stack; `SF Mono` for weight/plate numbers
- Information density prioritized — no unnecessary decoration
- All text minimum 14pt during active sessions (gym glare readability)
- Respect `prefers-reduced-motion` for all animations

**Microinteractions:**
- Set completion: fill + scale (105%) + haptic tap
- All sets done on exercise: checkmark overlay + auto-advance (1.5s, skippable)
- Session complete: full-screen summary card with stats, rotating encouraging message, "Done" CTA
- Weight increase between weeks: show delta in accent color ("+ 25 lbs")

---

## 10. Accessibility

**WCAG AA compliance is a v1 requirement.**

- **Color contrast:** All text meets 4.5:1 ratio (normal text) or 3:1 (large text) against backgrounds. Verify plate breakdown text on dark backgrounds.
- **Dynamic Type:** Use `rem` units. Test at the three largest iOS Dynamic Type sizes. Weight numbers and plate text must scale without clipping.
- **VoiceOver:** All interactive elements have descriptive labels. E.g., "Complete set 3 of 5, squat at 315 pounds" — not "Circle 3." Plate breakdown announced: "Per side: three 45-pound plates, one 10, one 5."
- **Color-blind safety:** Never convey state by color alone. Set completion uses checkmark + color. Rest timer states differ by icon, not just color.
- **Reduced motion:** Respect `prefers-reduced-motion`. Set completion and celebration animations have static alternatives.
- **Motor accessibility:** All swipe gestures have button alternatives. No time-limited mandatory interactions.

---

## 11. Out of Scope (v1)

- User accounts / cloud sync / backend
- Social features / sharing
- Exercise video demos
- Custom template builder (only the 7 predefined templates)
- Zulu I/A variant (insufficient specification — deferred to v1.1)
- kg unit support (data model ready, UI deferred to v1.1)
- Warm-up set display (v1.1 candidate)
- Conditioning protocol programming (beyond endurance duration ranges)
- Android-specific optimizations (PWA will work, but iOS is priority)
- Light theme development (dark-only is acceptable for v1; theme toggle framework is in place)

---

## 12. Success Criteria

1. User can enter 1RM data and see all 7 templates fully populated with correct weights and plate breakdowns — matching the spreadsheet output for Training Max at 90% of Epley
2. App installs to iOS home screen and works fully offline
3. User can run through a full workout session with tap-to-complete tracking, rest timer, and undo
4. All data persists across sessions via IndexedDB, with export/import backup available
5. Plate calculator output matches `LoadBarbellConstrained` and `PullupWeightConstrained` for all QA test cases (TC-001 through TC-028)
6. App survives force-quit mid-workout and offers session resume on relaunch
7. Storage eviction is detected and user is prompted to restore from backup
8. WCAG AA contrast requirements met in dark mode
9. Full onboarding flow takes a new user from zero to first workout in under 2 minutes

---

## Appendix A: Review Files

All review documents are preserved at `/reviews/`:
- `pm-review.md` — 22 recommendations (9 critical)
- `ios-engineer-review.md` — 20 recommendations, iOS PWA technical deep-dive
- `ux-review.md` — 20 recommendations, gym-environment UX
- `qa-review.md` — 69 regression test cases, 25 recommendations, plate calculator edge case matrix

## Appendix B: Key Changes from v1

| # | Change | Source |
|---|---|---|
| 1 | Defined Training Max = 90% of True Max | PM #1, QA #1 |
| 2 | Moved Export/Import to v1 scope | PM #10, iOS #1, UX #17 |
| 3 | Removed incorrect seed data (Epley mismatch) | PM #8, QA Critical |
| 4 | Resolved set/rep range ambiguity (show max, complete what you can) | PM #2, QA #5 |
| 5 | Clarified Gladiator Week 6 as descending (3,2,1,3,2) | PM #3, QA #2 |
| 6 | Deferred Zulu I/A variant to v1.1 | PM #4, QA #3 |
| 7 | Added session structures for Gladiator, Mass Protocol, Grey Man | PM #6, QA #4 |
| 8 | Clarified Mass Strength has 4 sessions (not 6) | PM #7, QA #11 |
| 9 | Renamed Mass Template → Mass Strength, Mass → Mass Protocol | PM #15, QA #6 |
| 10 | IndexedDB as primary store (not localStorage) | iOS #2 |
| 11 | Added schemaVersion + migration strategy | PM #11, iOS #3 |
| 12 | Added activeSession for mid-workout crash recovery | iOS #5, UX #10 |
| 13 | Added computedSchedule to data model | iOS #12 |
| 14 | Added onboarding wizard (Section 5.0) | PM #12, UX #1 |
| 15 | Added session state machine | QA #16 |
| 16 | Added accessibility requirements (Section 10) | iOS #18, UX #8 |
| 17 | Increased session touch targets to 56pt | UX #9 |
| 18 | Revised session view information hierarchy | UX #4 |
| 19 | Specified rest timer UX (Section 5.5) | UX #5, iOS #8 |
| 20 | Added storage eviction defense (Section 6.6) | iOS #1 |
| 21 | Specified keyboard handling (Section 6.4) | iOS #7 |
| 22 | Hash-based routing | iOS #20 |
| 23 | Preact + Vite as specified stack | iOS #16 |
| 24 | Added input validation rules | QA #5 |
| 25 | Added destructive action handling | QA #6 |
| 26 | Added Military Press to default lift list | PM #9 |
| 27 | Clarified Weighted Pull-up = added weight only | PM E6, iOS #4 |
| 28 | Added program lifecycle (completion, switching) | PM #13, iOS #10 |
| 29 | Renamed Settings tab → Profile | UX #2 |
| 30 | Added Zulu percentage-to-session mapping (Tier 1/Tier 2) | PM #5, QA #12 |
| 31 | Added failed rep logging | UX #11 |
| 32 | Added session notes | UX #12 |
| 33 | Added undo for set completion | iOS #14, UX #13 |
| 34 | Added weight override per session | UX #4 |
| 35 | Orange accent color for gym visibility | UX #20 |
