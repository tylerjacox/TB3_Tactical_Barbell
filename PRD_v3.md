# Tactical Barbell PWA — Product Requirements Document (v3)

> **Revision history:**
> - v1 → v2: Incorporates findings from PM, iOS Engineer, UX Designer, and QA Engineer reviews.
> - v2 → v3: Incorporates findings from TB Methodology Expert, Data Architect, Accessibility Specialist, and Security Reviewer. All reviews preserved in `/reviews/`.

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
- **Accessible** — WCAG 2.2 AA compliant, VoiceOver-tested, usable under physical exertion

---

## 3. Target Platform & Technical Constraints

| Concern | Detail |
|---|---|
| Primary platform | iOS Safari (Add to Home Screen PWA) |
| Display mode | `standalone` via web app manifest |
| Viewport | `100dvh` layout with `env(safe-area-inset-*)` for notch/home indicator |
| Touch targets | **56pt minimum** for session-critical actions (set completion, timer); 44pt minimum for all other interactive elements. **8pt minimum spacing** between adjacent interactive elements in session view. |
| Status bar | `apple-mobile-web-app-status-bar-style: black-translucent` |
| Storage | **IndexedDB** (primary) via `idb-keyval`. localStorage for `schemaVersion`, `lastActiveTimestamp`, auth tokens, `lastSyncedAt` |
| Offline | Service Worker: stale-while-revalidate for `index.html`, cache-first for hashed assets |
| Framework | **Preact 10.x** + Vite build. Preact Signals for state. ~7KB gzipped runtime |
| Routing | **Hash-based** (`/#/home`, `/#/program`, etc.) to avoid iOS standalone navigation bugs |
| CSS | Vanilla CSS with custom properties. No CSS-in-JS or Tailwind. `-apple-system` font stack |
| Bundle target | < 50KB gzipped total app shell |
| Cloud sync | AWS Cognito (auth) + API Gateway + Lambda + DynamoDB. Offline-first — IndexedDB is primary store, cloud is sync layer. |
| Auth | Email/password via Cognito User Pool. Admin-only signup. 7-day offline grace period. `amazon-cognito-identity-js` (~28KB gzipped, lazy-loaded) |

---

## 4. Information Architecture

```
Onboarding (first launch only)
+-- Step 1: Enter your lifts (1RM entry)
+-- Step 2: Choose your template (with recommendation flow)
+-- Step 3: Preview your first week
+-- Step 4: Start training -> drops into Dashboard

Home (Dashboard)
+-- Active Program (template name + week + progress bar)
+-- Next Session preview (lifts + weights)
+-- Quick-start button
+-- "Update Maxes" shortcut
+-- Last backup indicator

Program
+-- Template browser (with descriptions)
+-- Active program week-by-week schedule
+-- Program progress overview

History
+-- 1RM Test Log (date, lift, weight, reps, calculated 1RM)
+-- Completed Sessions Log

Profile & Settings
+-- 1RM Entry / Update (primary position, not buried)
+-- Rounding Increment
+-- Plate Inventory (barbell + belt)
+-- Barbell Weight
+-- Rest Timer Default
+-- Sound (On / Off / Vibrate Only)
+-- Theme (Dark / Light / System)
+-- Export Data (JSON)
+-- Import Data (JSON)
+-- Sign Out (clears auth tokens, keeps local data)
+-- Delete All Data
+-- About / Privacy Statement / Data Warning
```

---

## 5. Feature Specifications

### 5.0 — Onboarding (First Launch)

**Purpose:** Guide new users from install to first workout with zero friction.

**Flow:**
1. **Detect first launch:** If no profile exists in IndexedDB, show onboarding wizard instead of tab bar.
2. **Step 1 — "Enter Your Lifts":** Form for each core lift (Squat, Bench, Deadlift, Military Press, Weighted Pull-up). Each lift is optional — user enters Weight + Reps for lifts they train. Clear explanation: "Enter a recent heavy set. We'll calculate your max." Each lift is wrapped in a `<fieldset>` with `<legend>` (e.g., "Squat — enter a recent heavy set").
3. **Step 2 — "Choose Your Template":**
   - **Recommendation flow:** Before showing all 7 templates, ask: "How many days per week can you lift?" Filter results:
     - 2 days → Fighter
     - 3 days → Operator (recommended), Gladiator, Mass Protocol, Grey Man
     - 4 days → Zulu
     - "Show all" option to bypass filter
   - Card selector with `role="radiogroup"`. Each card is `role="radio"` with `aria-checked` state.
   - Template descriptions:
     - **Operator:** "Balanced strength + endurance. 3 strength days, 3 cardio days/week. 6-week cycle."
     - **Zulu:** "4 strength sessions/week. A/B split. 6-week cycle."
     - **Fighter:** "Minimal lifting. 2 sessions/week. 6-week cycle. For heavy conditioning schedules."
     - **Gladiator:** "High volume. 3 sessions/week. All lifts every session. 6-week cycle."
     - **Mass Protocol:** "Hypertrophy focus. 3 sessions/week. No rest minimums. 6-week cycle."
     - **Mass Strength:** "Hypertrophy + strength. 3-week cycle with dedicated deadlift day."
     - **Grey Man:** "Low profile. 3 sessions/week. 12-week cycle."
   - Selection does NOT auto-advance (WCAG 3.2.2). User taps "Continue" button.
4. **Step 3 — "Your First Week":** Show Week 1 sessions with calculated weights and plate breakdowns using the user's data. Instant value preview.
5. **Step 4 — "Start Training":** Set start date (default: today). Transition to Dashboard with active program.
6. **After onboarding:** Show "Add to Home Screen" instructions if not already in standalone mode (detect via `window.matchMedia('(display-mode: standalone)')`). Show "Backup your data" prompt encouraging first export.

**Focus management:** When advancing steps, move focus to the new step's heading. When going back, move focus to the previous step's heading. Use `aria-current="step"` on the active step indicator. Step indicator announced as: "Step 2 of 4, Choose your template."

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

**Form accessibility:**
- Use `type="text"` with `inputmode="decimal"` for weight, `inputmode="numeric"` for reps. Do NOT use `type="number"` (inconsistent on iOS/VoiceOver).
- Each lift grouped in `<fieldset>` with `<legend>`.
- Error messages inline below fields with `role="alert"` and `aria-live="polite"`. Input gets `aria-invalid="true"` on error. Errors are specific: "Weight must be between 1 and 1500 pounds."
- On submission with errors, focus moves to first field with an error.

**1RM Formula (Epley):**
```
1RM = Weight x (1 + Reps / 30)
```
If Reps = 1, then `1RM = Weight` (bypass formula).

**Training Max vs True Max:**
- **True Max:** The calculated 1RM is used directly for all percentage calculations.
- **Training Max:** `TrainingMax = calculated1RM x 0.90`. All template percentages are applied to the Training Max, not the True Max. This is the standard Tactical Barbell convention and the **recommended default**.

Example: Weight=365, Reps=4 -> Epley 1RM = 365 x (1 + 4/30) = 413.67. Training Max = 413.67 x 0.90 = 372.3. At 70%: 372.3 x 0.70 = 260.6, rounded to 260.

**Data model note:** When a 1RM is entered or updated, the app appends a `OneRepMaxTest` record to `maxTestHistory`. The user's current lift values (`profile.lifts`) are always **derived** from the most recent `OneRepMaxTest` per lift name — there is no separate write to `profile.lifts`. See Section 7.

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

**Maximum achievable barbell weight** (default inventory): 45 + (268.75 x 2) = **582.5 lb**

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

**Display format:** Plate badges always showing the **weight number as primary content**, labeled **"per side"** for barbell or **"on belt"** for pull-ups. Color is supplementary only — never the sole differentiator.

Preferred rendering: `45 x3  10  5  2.5  per side` — largest plate emphasized, smaller plates listed individually. If color-coded competition plate badges are used as an alternative visual style, each badge **must** contain the weight number in high-contrast text inside the badge.

**Color-blind safety:** Competition plate colors (red=45, green=25) are confusable under protanopia and deuteranopia. The weight number text is the primary identifier. Color is decorative only.

**Special cases:**

| Condition | Display |
|---|---|
| Total weight = barbell weight (e.g., 45) | "Bar only" — no plate list |
| Weighted pull-up weight = 0 | "Bodyweight only" — no plate list |
| Total weight < barbell weight | "Weight is below bar weight" |
| Plates insufficient for target | "Not achievable with current plates" — show nearest achievable weight as suggestion |
| Negative or zero total weight | "Not achievable" (guard against invalid 1RM input) |

**Configurable:** User can edit plate inventory in Settings (quantities per plate size, min 0, max 20 per size). Settings persist in IndexedDB. Plate quantity +/- stepper buttons must be **44pt minimum** touch targets.

---

### 5.3 — Training Templates

Each template defines a multi-week cycle with prescribed sessions, 1RM percentages, sets, and reps. All weights are auto-calculated from the user's working max (True Max or Training Max per their setting).

**Sets/Reps range convention:** When a template specifies a set range (e.g., "3-5 x 5"), the app displays the **maximum set count** as the default target. Before each session begins, the user selects their target set count via a selector (e.g., "How many sets today? 3 / 4 / 5") defaulting to the maximum. The user then completes sets by tapping; they can stop early (completing fewer sets than their target is valid and logged). This preserves the TB philosophy of pre-committing to a number while remaining easy to use.

For templates with fixed set counts (Gladiator, Mass Protocol, Grey Man, Mass Strength), no selector is shown.

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
| **Sets x Reps** | 3-5 x 5 | 3-5 x 5 | 3-4 x 3 | 3-5 x 5 | 3-5 x 3 | 3-4 x 1-2 |

*Note: Set counts are ranges. The pre-session selector defaults to the maximum (5 for "3-5", 4 for "3-4"). Week 6 allows singles or doubles at 95% — the rep selector offers 1 or 2.*

**Endurance duration ranges (minutes):**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| Sessions 2 & 4 | 30-60 | 30-60 | 30-60 | 30 | 60-90 | 60-90 |
| Session 6 | 60-90 | 60-90 | 60-90 | 30 | 90-120 | 90-120 |

#### 5.3.2 — Mass Strength *(renamed from "Mass Template" to avoid collision with 5.3.6)*

| Property | Value |
|---|---|
| Duration | 3 weeks (single cycle) |
| Sessions/week | 4 tracked (Sessions 1, 3, 5: Squat/Bench/WPU; Session 6: Deadlift) |
| Description | "Hypertrophy + strength. 4 tracked sessions per week with a dedicated deadlift day. 3-week cycle." |

*Note: This template has **4 tracked training sessions per week** (12 tracked sessions total across the 3-week cycle). Sessions 2 and 4 are supplemental/accessory days not tracked in the app — the user performs those independently.*

**Weekly percentage progression (Sessions 1, 3, 5):**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| **%** | 65 | 75 | 80 |
| **Sets x Reps** | 4x8 | 4x6 | 4x3 |

**Session 6 — Deadlift day:**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| **%** | 65 | 75 | 80 |
| **Sets x Reps** | 4x5 | 4x5 | 1x3 |

**Session structure:**
- **Session 1:** Squat, Bench, Weighted Pull-up
- **Session 2:** *(Supplemental/accessory — not tracked)*
- **Session 3:** Squat, Bench, Weighted Pull-up
- **Session 4:** *(Supplemental/accessory — not tracked)*
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
| A (3 lift slots) | Military Press, Squat, Weighted Pull-up |
| B (2-3 lift slots) | Bench, Deadlift, *(optional 3rd slot: user choice or empty)* |

**Weekly schedule and percentage mapping:**

Each A and B day is performed twice per week. The first instance of each uses **Cluster One** percentages; the second instance uses **Cluster Two** percentages.

| Week pattern | Cluster One % (A1, B1) | Cluster Two % (A2, B2) | Sets x Reps |
|---|---|---|---|
| Weeks 1, 4 | 70 | 75 | 3x5 |
| Weeks 2, 5 | 80 | 80 | 3x5 |
| Weeks 3, 6 | 90 | 90 | 3x3 |

**Lift selection rules:** User picks lifts from dropdown per cluster slot. Only lifts with a 1RM entered are selectable. Minimum 2 lifts per cluster, maximum 3. Optional 3rd slot on B day can be left empty. Validation: warn if a cluster has no lower body lift or no upper body push.

#### 5.3.4 — Fighter

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 2 (spread evenly, guidance: no back-to-back days) |
| Description | "Minimal lifting. 2 sessions/week. For heavy conditioning schedules." |

**Cluster:** User selects **2-3 lifts** from: Squat, Bench, Military Press, Deadlift, **Weighted Pull-up**. All selected lifts are performed in both sessions.

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 75 | 80 | 90 | 75 | 80 | 90 |
| **Sets x Reps** | 3-5 x 5 | 3-5 x 5 | 3-5 x 3 | 3-5 x 5 | 3-5 x 5 | 3-5 x 3 |

*Set count is a range. Pre-session selector defaults to 5.*

#### 5.3.5 — Gladiator

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 3 |
| Description | "High volume. 3 sessions/week. All lifts every session. 5x5 base. 6-week cycle." |

**Cluster lifts:** User selects **2-4 lifts** from: Squat, Bench, Deadlift, Military Press, Weighted Pull-up.

**Session structure: ALL selected cluster lifts appear in EVERY session.** There is no A/B split. A typical cluster (Squat, Bench, Deadlift) means all three lifts are performed in all three weekly sessions.

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 75 | 85 | 95 |
| **Sets x Reps** | 5x5 | 5x5 | 5x3 | 5x5 | 5x5 | 5x descending (3,2,1,3,2) |

*Note: Gladiator uses fixed set counts (no ranges). No pre-session selector needed.*

**Week 6 "descending" clarification:** 5 sets with reps: 3, 2, 1, 3, 2. Total: 11 reps across 5 sets at 95%. Display each set individually with its rep target.

#### 5.3.6 — Mass Protocol *(renamed from "Mass" to avoid collision with 5.3.2)*

| Property | Value |
|---|---|
| Duration | 6 weeks |
| Sessions/week | 3 |
| Notes | Rest timer hidden/optional for this template (no rest minimums) |
| Description | "Hypertrophy focus. 3 sessions/week. All lifts every session. No rest minimums." |

**Cluster lifts:** User selects **2-4 lifts** from: Squat, Bench, Deadlift, Military Press, Weighted Pull-up.

**Session structure: ALL selected cluster lifts appear in EVERY session.** Same as Gladiator — no A/B split.

**Weekly progression:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| **%** | 75 | 80 | 90 | 75 | 85 | 90 |
| **Sets x Reps** | 4x6 | 4x5 | 4x3 | 4x6 | 4x4 | 4x3 |

#### 5.3.7 — Grey Man

| Property | Value |
|---|---|
| Duration | 12 weeks |
| Sessions/week | 3 |
| Description | "Low profile. 3 sessions/week. All lifts every session. 12-week cycle with progressive intensification." |

**Cluster lifts:** User selects **2-4 lifts** from: Squat, Bench, Deadlift, Weighted Pull-up, Military Press.

**Session structure: ALL selected cluster lifts appear in EVERY session.** Same cluster-based approach as Gladiator and Mass Protocol.

**Weekly progression (12-week cycle):**

| Week | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **%** | 70 | 80 | 90 | 70 | 80 | 90 | 75 | 85 | 95 | 75 | 85 | 95 |
| **Sets x Reps** | 3x6 | 3x5 | 3x3 | 3x6 | 3x5 | 3x3 | 3x6 | 3x5 | 3x1 | 3x6 | 3x5 | 3x1 |

---

### 5.4 — Active Program & Session Tracking

#### Program Lifecycle

1. **Activation:** User selects template -> selects cluster lifts (if applicable) -> selects start date (default: today) -> app pre-computes full schedule (all weeks, sessions, weights, plate breakdowns) and stores in IndexedDB as `computedSchedule`.
2. **Single program:** Only one program active at a time. Switching templates requires confirmation: *"Starting a new program will end your current Operator cycle (Week 3 of 6). Session history is preserved. Continue?"* Confirmation dialog traps focus and returns focus to trigger on dismissal.
3. **Mid-program 1RM change:** Recalculate all **future** sessions automatically. Past completed sessions are immutable. The active in-progress session (if any) keeps its snapshotted weights — only future sessions change. Show brief confirmation: *"Weights updated for remaining sessions."*
4. **Program completion:** After the final session, show completion screen with summary. **Primary CTA: "Retest 1RM"** (navigates to 1RM entry). Secondary options: "Start a new cycle" (same template, fresh) or "Choose new template." Brief note: "TB recommends retesting your maxes before starting a new block."
5. **Program advancement:** Session-based, **not calendar-based**. The user advances by completing or skipping sessions. Missing a week does not auto-advance the program.

#### Dashboard (Home screen)

- Current template name + week number + progress bar (e.g., "Week 3 of 6"). Progress bar uses `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, and `aria-label="Program progress, week 3 of 6"`.
- Next session preview: exercises with working weights
- Quick-start button (large, bottom-center, 64pt)
- "Update Maxes" shortcut button
- Last backup indicator: "Last backup: 3 days ago" — visible on dashboard
- If workout is in progress: persistent "Return to Workout" bar at top with `role="alert"` on first appearance

#### Session View (Active Workout) — PRIMARY SCREEN

**Information hierarchy (top to bottom per exercise card):**
1. **Exercise name** — small uppercase label (14pt, muted — minimum #999999 on #111111 background for 4.67:1 contrast)
2. **Set progress** — most prominent element. Large: "SET 3 / 5" with visual dots/circles. Each dot has `aria-label="Set N, completed/pending"`. Completed dots show a **checkmark icon** (not color fill alone).
3. **Working weight** — largest number (32-40pt, bold, white)
4. **Plate breakdown** — secondary line (14-16pt, monospace, labeled "per side" or "on belt"). Weight numbers are always the primary content.
5. **Reps target** — near set progress ("x 5 reps")
6. **Complete Set button** — full-width, bottom of card, **56pt minimum height**. Label: "Complete set 3 of 5, Squat at 315 pounds."

**Exercise navigation:**
- Horizontal swipe between exercises (pager pattern) for sighted touch users.
- **Explicit "Previous Exercise" and "Next Exercise" buttons** always present in the DOM (arrow icons at card edges). Labels: "Previous exercise, Squat" / "Next exercise, Deadlift". These are the accessible alternative to swipe.
- Current exercise is focused/expanded. Completed exercises show a checkmark overlay with `aria-label` indicating completion.
- Dot indicator at top shows position. Dots use `aria-label="Exercise 2 of 4, Bench Press"`.
- Auto-advance to next exercise after all sets complete (1.5s delay, skippable). **When VoiceOver is active, do not auto-advance.** Instead announce "All sets complete. Tap Next Exercise for Bench Press" and wait for user action.

**Pre-session set target selector (for range-based templates):**
Before the session starts, for Operator and Fighter, display a selector per exercise: "How many sets today?" with options from the range (e.g., 3, 4, 5 for "3-5"). Default: maximum. The selected target is stored in `activeSession.exercises[].targetSets` and used for the set counter display.

**Set completion interaction:**
- Tap "Complete Set" -> set circle fills with checkmark + scale (105%, spring easing) + haptic tap
- **10-second undo toast** appears after each set completion. Undo toast uses `role="alert"` with `aria-live="assertive"`: "Undo last set. Available for 10 seconds." Undo remains available until the next set is completed or 10 seconds elapse, whichever comes first.
- After all sets: exercise card shows checkmark, auto-advances (or waits for user action if VoiceOver active)

**Failed rep logging:** If user taps the rep count, they can adjust actual reps (e.g., target was 5, only got 3). The tappable area around the rep count must be **44pt minimum** even if the visible text is smaller. Data model tracks both `targetReps` and `actualReps`.

**Weight override:** Tap the weight number to override for this session only (e.g., plates unavailable). The tappable area must be **44pt minimum**. Override is stored in `activeSession.weightOverrides` and does not change 1RM. Also accessible via "Session Actions" menu.

**Session Actions menu:** A button (e.g., three-dot menu icon) provides single-point access to all workout controls: Complete Current Set, Skip Rest Timer, Override Weight, Edit Reps, End Workout. This consolidates actions for VoiceOver and Switch Control users.

**During active workout:**
- Bottom tab bar is **hidden** to prevent accidental navigation
- "End Workout" button available via top-right menu **and** via the Session Actions menu (accessible from bottom of screen)
- If user force-quits or backgrounds: session state is persisted to IndexedDB on every set completion. On next launch: "Resume workout?" prompt.

**Endurance session view:** Distinct from strength. Shows: prescribed duration range, start button, running count-up timer, and complete button. No sets/reps UI.

#### Session State Machine

```
NOT_STARTED  -> IN_PROGRESS   (user taps "Start Session")
NOT_STARTED  -> SKIPPED       (user skips to next session)
IN_PROGRESS  -> COMPLETED     (user taps "Complete Session" or finishes all sets)
IN_PROGRESS  -> PAUSED        (app backgrounded / user navigates away)
PAUSED       -> IN_PROGRESS   (user returns -- auto-resume prompt)
PAUSED       -> ABANDONED     (paused > 24 hours without resuming)
```

On launch, if `activeSession` exists in IndexedDB: if `startedAt` is more than 24 hours ago, treat as potentially abandoned. Offer "Resume" and "Discard" options. If discarded, convert to a `SessionLog` with `status: 'partial'` (some sets done) or `status: 'skipped'` (no sets done).

---

### 5.5 — Rest Timer

**Trigger:** Auto-starts when user completes a set. Dismissible/skippable.

**Display:** Inline expansion within the current exercise card. Large countdown number (48pt+) with circular progress ring. Uses `role="timer"`. Does not obscure exercise context. The "Complete Set" button remains accessible and focusable even while the timer is active.

**Controls:**
- Explicit "+30s" button with `aria-label="Add 30 seconds to rest timer"` (not just "tap the timer")
- Tap "Skip" button to dismiss immediately (`aria-label="Skip rest timer"`)
- After timer reaches 0: show elapsed time ("Resting: 2:45") as passive nudge. Elapsed nudge is dismissible.

**Completion notification:** Haptic triple pulse via Vibration API. Audio chime (ascending, 300ms) if Sound setting is On. VoiceOver announcement: "Rest complete" via `aria-live="assertive"`.

**VoiceOver timer announcements:**
- On timer start: announce "Rest timer, 2 minutes" (once)
- At 30-second mark: announce "30 seconds remaining" via `aria-live="assertive"`
- At zero: announce "Rest complete" + haptic + optional audio
- Do NOT announce every second. If user navigates to the timer element, read current remaining time (updated every 5 seconds for aria-label accuracy).

**Audio countdown option:** Settings toggle: "Timer audio countdown: Off / 30s intervals / 10s intervals." Helps non-visual users track time without constant VoiceOver announcements. Default: Off.

**Background handling:** Timer uses `Date.now()` comparison (not `setInterval`). When app is foregrounded, calculate actual elapsed time and display correctly. iOS will kill `setInterval` in background.

**Default durations (percentage-aware):**

| Intensity | Default Rest |
|---|---|
| 90%+ (weeks 3, 6 of most templates) | 3:00 |
| 70-85% | 2:00 |
| < 70% | 1:30 |

User can override the default globally in Settings.

**Reduced motion:** When `prefers-reduced-motion` is active, the progress ring shows a static filled state rather than smooth animation. The countdown number still counts down (text changes are not motion). Pulsing at completion is replaced with a static bold/highlighted state.

**Non-text contrast:** Both the filled and unfilled portions of the progress ring must maintain **3:1 contrast** against the card background (WCAG 1.4.11).

---

### 5.6 — History & 1RM Test Log

**1RM Test History:**
- Append-only log: date, lift, weight, reps, calculated 1RM, max type (true/training)
- Shows progression over time per lift
- **Most recent entry per lift is the source of truth for `profile.lifts`** — current values are derived, not separately stored
- **No hardcoded seed data.** The user imports their history or enters fresh.
- Each entry uses `role="listitem"` within a `role="list"`. VoiceOver reads: "February 10, 2026. Squat, 365 pounds, 4 reps, calculated 1RM 414 pounds, Training Max 372 pounds."

**Completed Sessions Log:**
- Date, template, week, session number, exercises with actual sets/reps completed, `startedAt` and `completedAt` timestamps for duration tracking
- Status: COMPLETED, PARTIAL (not all sets done), SKIPPED — status communicated via text label, not color alone
- Immutable once logged — settings changes do not retroactively alter history
- Simple list view, newest first

**Session notes:** Optional free-text notes field per session (e.g., "Left knee felt tight," "Used belt on set 3"). Maximum **500 characters**. Character counter shown in UI.

---

### 5.7 — Settings & Profile

| Setting | Type | Min | Max | Default | Notes |
|---|---|---|---|---|---|
| Max Type | Toggle | — | — | Training Max | True Max or Training Max (0.90 multiplier). Use `role="radiogroup"`. |
| Rounding Increment | Selector | — | — | 2.5 | 2.5 or 5. Use `role="radiogroup"`. |
| Barbell Weight | Number | 15 | 100 | 45 | Supports women's bars (35), specialty bars |
| Plate Inventory (Barbell) | Editable per-plate qty | 0 | 20 | 4x45, 1x35, 1x25, 2x10, 1x5, 1x2.5, 1x1.25 | Per side. +/- buttons 44pt minimum. |
| Plate Inventory (Belt) | Editable per-plate qty | 0 | 20 | 2x45, 1x35, 1x25, 2x10, 1x5, 1x2.5, 1x1.25 | Total on belt |
| Rest Timer Default | Seconds | 0 | 600 | 120 | 0 = disabled |
| Sound | 3-way toggle | — | — | On | On / Off / Vibrate Only |
| Theme | 3-way toggle | — | — | Dark | Dark / Light / System |
| Unit | Display only (v1) | — | — | lb | Data model stores unit for future kg support |
| **Export Data** | Button | — | — | — | Exports full JSON to Files app via Web Share API, or clipboard fallback. Shows "Your data is exported as unencrypted JSON." |
| **Import Data** | Button | — | — | — | File picker for JSON import. Full validation before overwriting (see Section 7.5). |
| **Delete All Data** | Button | — | — | — | Two-step confirmation. Clears IndexedDB + localStorage, navigates to onboarding. |
| Last Backup Date | Display only | — | — | — | Shows when last export occurred |

**Cloud sync as primary backup:** When signed in, cloud sync provides automatic data protection across devices. Export/import remains available as a secondary backup option.

**Backup reminder (when not signed in):** If `Date.now() - lastBackupDate > 5 days` and user is not authenticated, show non-blocking but persistent banner on dashboard: "It's been 5 days since your last backup. Tap to export your data." Escalate to daily reminders after 6 days. The 5-day threshold provides a 2-day buffer before Safari's 7-day eviction window. When signed in with active cloud sync, this reminder is suppressed.

**Data warning:** Visible in Settings: "Your data is stored locally on this device and synced to the cloud when signed in. Clearing Safari data while offline may require re-syncing. Use Export as an additional backup."

**Privacy statement** (Settings > About): "Your training data is stored locally on your device and synced to the cloud when signed in. Data is only accessible to you."

**Sign Out:** Clears auth tokens from localStorage. Local IndexedDB data is preserved — the app remains usable offline after sign out, but cloud sync stops until the user signs back in.

---

### 5.8 — Authentication

**Purpose:** Email/password authentication for access control and future monetization. Admin-only signup — users cannot self-register.

**Auth provider:** AWS Cognito User Pool

**Auth library:** `amazon-cognito-identity-js` (~28KB gzipped, lazy-loaded on first auth interaction — not included in initial bundle)

**Screens:**
- **Login:** Email + password form. Handles `NEW_PASSWORD_REQUIRED` challenge (admin-created accounts on first login). Error messages do not reveal whether an email exists in the system.
- **Forgot Password:** Enter email → receive verification code → enter code + new password.
- **Confirm Email:** Enter verification code for email confirmation.

**Token storage:** localStorage (`tb3_auth_tokens`). Tokens:
- Access token (24h validity) — used for API calls
- ID token (24h validity) — contains user claims (email, sub)
- Refresh token (30-day validity) — silent refresh

**Offline grace period:** If the app cannot reach Cognito to refresh tokens, the user remains authenticated for up to **7 days** since their last successful authentication. This covers gym use without Wi-Fi. After 7 days offline, the user must sign in again.

**Admin user creation:**
```bash
aws cognito-idp admin-create-user \
  --user-pool-id <POOL_ID> \
  --username user@example.com \
  --user-attributes Name=email,Value=user@example.com \
  --temporary-password TempPass123
```
The user receives an email with the temporary password and must set a new password on first sign-in.

---

### 5.9 — Cloud Sync

**Purpose:** Multi-device sync — use the app on phone + iPad with data staying in sync. The app remains offline-first; IndexedDB is the primary store, cloud is the sync layer.

**Architecture:** Single `POST /sync` endpoint (AWS API Gateway + Lambda + DynamoDB). Cognito JWT authorizer.

**DynamoDB data model (single-table):**

| PK | SK | Data |
|---|---|---|
| `USER#{userId}` | `PROFILE` | User settings (maxType, rounding, plates, etc.) |
| `USER#{userId}` | `PROGRAM` | Active program state (templateId, week, session, liftSelections) |
| `USER#{userId}` | `SESSION#{id}` | Completed session log |
| `USER#{userId}` | `MAXTEST#{id}` | 1RM test entry |

Every item has `lastModified` (ISO timestamp) for delta sync queries.

**Sync triggers:**
- On app launch (if online and authenticated)
- After completing a workout session
- After updating 1RM
- After changing settings
- Every 5 minutes while app is open and online
- On app foreground (visibilitychange)
- On coming back online
- **NOT** during an active workout (don't interrupt)

**Sync protocol:**
1. Client gathers local changes since `lastSyncedAt` from IndexedDB
2. `POST /sync` with push payload + `lastSyncedAt`
3. Server writes pushed data, queries items modified since `lastSyncedAt`, returns delta
4. Client merges pulled data into IndexedDB
5. Client updates `lastSyncedAt` to server's timestamp
6. UI re-renders via Preact Signals

**Conflict resolution:**
- **Sessions / 1RM tests:** No conflicts — append-only, keyed by UUID. Sync = union by ID.
- **Profile / active program:** Last-write-wins by `lastModified` timestamp. Acceptable for single-user app.
- **Active session (mid-workout):** NOT synced. Only completed session logs sync after workout ends.

**Offline behavior:** Changes accumulate in IndexedDB normally. On next online sync, all changes push together. No separate offline queue — delta detection via `lastSyncedAt` handles this automatically.

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
- **8pt minimum spacing** between adjacent interactive elements in session view
- `touch-action: manipulation` on all buttons (removes 300ms tap delay)
- `-webkit-tap-highlight-color: transparent` — replaced with custom `:focus-visible` outline (minimum 2px, contrasting color). Do NOT apply `:focus { outline: none }` without a replacement.
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

**External keyboard support (Bluetooth):** All interactive elements must be reachable via Tab key. Focus order follows DOM order. Consider keyboard shortcuts for session view: Space/Enter to complete set, Escape to undo.

### 6.5 — Offline & Service Worker

**Cache strategy:**
- `index.html`: **Stale-while-revalidate** (allows update detection)
- Hashed assets (`app.[hash].js`, `app.[hash].css`): **Cache-first** (immutable)
- No external URLs cached

**Update flow:**
1. App launches, service worker serves cached version instantly
2. Background update check
3. If new version found: non-blocking toast "Update available. Tap to refresh."
4. User taps -> `location.reload()`
5. Do NOT call `skipWaiting()` automatically (causes blank screen on iOS; also prevents silent code replacement from compromised updates)

**Registration:** On `load` event (not `DOMContentLoaded`).

**Cache versioning:** `CACHE_VERSION` constant in service worker. On activation, delete all caches not matching the current version.

### 6.6 — Storage Eviction Defense

Safari will purge all client-side storage after **7 days of no visit**. This affects IndexedDB, localStorage, cookies set via JavaScript, service worker registrations, and Cache API equally. **There is no technical solution that prevents data loss from Safari's 7-day eviction policy for users who stop using the app.** The only reliable protection is regular exports.

Multi-layer defense:

1. **Eviction detection (heuristic):** On launch, attempt to read IndexedDB. If the read returns empty but the app is running in standalone mode (detect via `navigator.standalone` or `display-mode: standalone` media query), storage was likely evicted. Show recovery prompt: "It looks like your data may have been cleared. Restore from a backup?" with a button to the import flow.
2. **Aggressive backup reminders:** If no export in **5+ days**, show persistent banner on dashboard (not just a one-time toast). Escalate to daily after 6 days. The 5-day threshold gives a 2-day buffer before the 7-day eviction window.
3. **Export/Import always available:** JSON export via Web Share API (saves to Files app). JSON import via file picker with full validation (see Section 7.5).
4. **URL-encoded 1RM recovery (last resort):** Encode current 1RM values into a shareable URL hash (~100 bytes). User can bookmark this. UI note: "This URL contains your lift maxes. Anyone with the URL can see these values." Values decoded from URL must pass the same numeric validation as manual entry (see Section 11). Show confirmation prompt before writing.
5. **Write-through on every meaningful action:** Every set completion, every 1RM update, every settings change writes to IndexedDB immediately. No batching or debouncing.

### 6.7 — Landscape Handling

iOS ignores `orientation: portrait` in manifest. If device rotates to landscape, show a "Please rotate to portrait" overlay rather than attempting responsive landscape layout.

### 6.8 — Splash Screens & Icons

- `apple-touch-icon` at 180x180
- Generate Apple launch images at build time via `pwa-asset-generator` from a single source image
- Or: use CSS-based loading screen (dark background + "TB3" text) to avoid maintaining 12+ image sizes

### 6.9 — Install Prompt

No `beforeinstallprompt` on iOS. Detect if running in-browser:
```javascript
const isStandalone = window.matchMedia('(display-mode: standalone)').matches;
```
If in-browser, show persistent banner: "For the best experience, tap Share -> Add to Home Screen."

---

## 7. Data Model

### 7.1 — Core Interfaces

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
  lastSyncedAt: string | null;    // ISO timestamp — last successful cloud sync
}

// All entities include lastModified (ISO timestamp) for cloud sync delta detection.

interface UserProfile {
  // NOTE: profile does NOT store a separate `lifts` array.
  // Current lift values are DERIVED from the most recent OneRepMaxTest
  // per liftName in maxTestHistory. This eliminates dual-write bugs.
  maxType: 'true' | 'training';
  roundingIncrement: 2.5 | 5;
  barbellWeight: number;
  plateInventoryBarbell: PlateInventory;
  plateInventoryBelt: PlateInventory;
  restTimerDefault: number;
  soundMode: 'on' | 'off' | 'vibrate';
  theme: 'light' | 'dark' | 'system';
  unit: 'lb' | 'kg';  // v1: always 'lb'. Reserved for future.
}

// Derived at runtime, NOT stored:
interface DerivedLiftEntry {
  name: string;          // "Squat" | "Bench" | "Deadlift" | "Military Press" | "Weighted Pull-up"
  weight: number;        // From most recent OneRepMaxTest for this lift
  reps: number;
  oneRepMax: number;     // Calculated via Epley
  workingMax: number;    // = oneRepMax if True Max; = oneRepMax * 0.90 if Training Max
  isBodyweight: boolean; // true for Weighted Pull-up (uses belt plate calc)
  testDate: string;      // ISO date of the most recent test
}

// Function to derive current lifts:
// getCurrentLifts(maxTestHistory, maxType, roundingIncrement) -> DerivedLiftEntry[]
// Groups by liftName, takes most recent per group, applies maxType preference.

interface PlateInventory {
  plates: { weight: number; available: number }[];
}

interface ActiveProgram {
  templateId: string;
  startDate: string;
  currentWeek: number;
  currentSession: number;
  liftSelections: Record<string, string[]>;  // Applies to ALL templates with customizable lift slots
}

interface ComputedSchedule {
  computedAt: string;    // ISO timestamp
  sourceHash: string;    // Hash of (lifts + settings + templateId) that produced this schedule
  weeks: ComputedWeek[];
}

interface ComputedWeek {
  weekNumber: number;
  percentage: number;
  setsRange: [number, number];  // [min, max] e.g. [3, 5] for "3-5 sets"
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
  // Persisted to IndexedDB on every set completion for crash recovery.
  // SELF-CONTAINED: snapshots all exercise data at session start.
  // Does NOT reference computedSchedule during the workout.
  status: 'in_progress' | 'paused';  // Set to 'paused' on visibilitychange (page hidden)
  templateId: string;
  programWeek: number;
  programSession: number;
  sessionType: 'strength' | 'endurance';
  startedAt: string;
  currentExerciseIndex: number;
  // Exercise snapshot — captured at session start, immutable during session:
  exercises: {
    liftName: string;
    targetWeight: number;
    targetSets: number;          // May be user-selected from range
    targetReps: number | number[];  // number[] for descending
    plateBreakdown: { weight: number; count: number }[];
  }[];
  sets: {
    exerciseIndex: number;
    setNumber: number;
    targetReps: number;
    actualReps: number | null;  // null = not yet attempted
    completed: boolean;
    completedAt: string | null;
  }[];
  weightOverrides: Record<number, number>;  // exerciseIndex -> overridden weight
  restTimerState: {
    running: boolean;
    targetEndTime: number | null;  // Date.now() based
  } | null;
  // Endurance-specific (only if sessionType === 'endurance'):
  enduranceDuration?: string;
  enduranceStartedAt?: string;
  enduranceDurationActual?: number;  // minutes
}

interface SessionLog {
  id: string;            // crypto.randomUUID()
  date: string;
  templateId: string;
  week: number;
  sessionNumber: number;
  status: 'completed' | 'partial' | 'skipped';
  startedAt: string;     // ISO timestamp
  completedAt: string;   // ISO timestamp
  exercises: ExerciseLog[];
  notes: string;         // Max 500 characters
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
  id: string;            // crypto.randomUUID()
  date: string;
  liftName: string;
  weight: number;
  reps: number;
  calculatedMax: number;
  maxType: 'true' | 'training';
  workingMax: number;
}
```

### 7.2 — IndexedDB Schema

```
Database: "tb3"
  Store: "app"       -> single record (key: "data") containing AppData
```

**ID generation:** Use `crypto.randomUUID()` (supported in Safari 15.4+). Fallback: `Date.now().toString(36) + Math.random().toString(36).slice(2)`. Do not use auto-incrementing integers — they collide on import.

**Schema migration:** On app launch, read `schemaVersion`. If less than current code version, run sequential migration functions (v1->v2, v2->v3, etc.) before rendering. See Section 7.4.

### 7.3 — ComputedSchedule Staleness Detection

On every render that reads from `computedSchedule`, compute the current source hash (from lifts + settings + templateId) and compare against `computedSchedule.sourceHash`. If they diverge, trigger silent regeneration. This is a cheap integrity check (~1ms to hash the inputs) that catches stale schedules from missed regeneration triggers.

Regeneration triggers:
1. Program activation (new program started)
2. 1RM value changes (any lift)
3. Settings changes affecting weights: rounding increment, barbell weight, max type
4. Plate inventory changes

If `activeSession` exists during regeneration, the active session's snapshotted exercise data is untouched. Only the `computedSchedule` for future sessions is regenerated.

### 7.4 — Schema Migration Framework

```typescript
type Migration = (data: unknown) => unknown;

const migrations: Record<number, Migration> = {
  // v1 -> v2: example migration
  2: (data: any) => ({
    ...data,
    schemaVersion: 2,
    // ... transformation
  }),
};

function migrateData(data: unknown, targetVersion: number): AppData {
  let current = data as any;
  let version = current.schemaVersion || 1;
  while (version < targetVersion) {
    const migrate = migrations[version + 1];
    if (!migrate) throw new Error(`No migration from v${version} to v${version + 1}`);
    current = migrate(current);
    version = current.schemaVersion;
  }
  return current as AppData;
}
```

**Migration safety — backup before migrate:**
1. Read current data from IndexedDB.
2. Write a backup copy to a separate key (`"data_backup"`) in the same transaction.
3. Run migrations **in memory** (not touching IndexedDB).
4. If all migrations succeed: write migrated data to `"data"` key, delete `"data_backup"`.
5. If any migration throws: do not write. Show error to user. Data remains at old version.
6. On next launch: if `"data_backup"` exists, the previous migration failed. Offer recovery.

**Missing migrations are a build-time error:** Enforce via a test that checks `migrations` has entries for every version from 2 to `CURRENT_SCHEMA_VERSION`.

**Every migration must have a unit test** that takes a fixture of the old schema's data, runs the migration, and validates the output.

### 7.5 — Export/Import Specification

**Export format:**
```json
{
  "tb3_export": true,
  "exportedAt": "2026-02-15T10:30:00Z",
  "appVersion": "1.0.0",
  "schemaVersion": 1,
  "profile": { ... },
  "activeProgram": { ... },
  "sessionHistory": [ ... ],
  "maxTestHistory": [ ... ]
}
```

**Excluded from exports:**
- `computedSchedule` — derived data, regenerated on import
- `activeSession` — transient mid-workout state. If user exports mid-workout, warn: "Your current workout will not be included in the export."

**Import validation checklist (sequential — fail fast):**

1. **File size:** Reject files over 1MB. Display: "File too large."
2. **Valid JSON:** Parse with `JSON.parse()` only (never `eval`). Display: "Invalid file format."
3. **Sentinel check:** Verify `tb3_export === true`. Display: "This file does not appear to be a TB3 backup."
4. **Schema version exists:** Verify `schemaVersion` is a number. Display: "Unrecognized backup version."
5. **Schema version not newer than app:** If `import.schemaVersion > CURRENT_SCHEMA_VERSION`, display: "This backup is from a newer version of TB3. Please update the app first."
6. **Prototype pollution defense:** Recursively reject objects containing `__proto__`, `constructor`, or `prototype` as keys at any nesting depth.
7. **Run migrations:** If `schemaVersion` < current, run migration functions. If they throw, reject with migration error.
8. **Required fields:** Validate `profile`, `sessionHistory`, `maxTestHistory` exist with correct types.
9. **Numeric range validation:** All imported numeric values must pass the same min/max constraints as manual entry (weight 1-1500, reps 1-15, etc.).
10. **String length validation:** All string fields <= 500 characters. Strip HTML tags.
11. **ID uniqueness:** Verify all `SessionLog.id` and `OneRepMaxTest.id` values are unique.
12. **Confirmation prompt:** Show preview: "This will replace all current data. Import contains: 4 lifts, 23 sessions, last updated Feb 10, 2026. Continue?" Offer "Export current data first?" as safety net.

Import is a **full replacement** (no merge). If the user has an active session, warn: "You have a workout in progress. Importing will discard your current session."

### 7.6 — Data Integrity Validation

Create a `validateAppData(data: AppData): ValidationResult` function. Run on:
- App launch (after migration, before rendering)
- After import

**Invariants checked:**
- `activeProgram.templateId` references one of the 7 known templates
- `activeProgram.currentWeek` and `currentSession` are within bounds for the template
- All `SessionLog.id` and `OneRepMaxTest.id` values are unique
- All lift names are from the known set of 5
- `maxTestHistory` has at most one "most recent" entry per lift name (no duplicate dates)
- Numeric fields are within expected ranges

**Severity levels:**
- **Fatal:** Data is unusable. Show error, offer raw export, prompt for re-import.
- **Recoverable:** Data usable after automatic correction. Apply silently, log issue.
- **Warning:** Data usable but suboptimal. Log for debugging.

---

## 8. Navigation

**Bottom tab bar (4 tabs):**

| Tab | Icon | View | `aria-label` |
|---|---|---|---|
| **Home** | House | Dashboard — active program, next session, quick-start | "Home" |
| **Program** | Calendar | Template browser + active program week-by-week schedule | "Program" |
| **History** | Clock | 1RM test log + completed sessions | "History" |
| **Profile** | Person | 1RM entry *(primary position)*, plate config, settings, export/import | "Profile" |

*Renamed "Settings" -> "Profile" to signal it contains primary data (1RM entry), not just preferences.*

**Tab icon states:** Active tab uses filled icon variant + accent color. Inactive tabs use outlined icon variant. Inactive icon color must maintain **3:1 non-text contrast** against tab bar background (minimum #888888 on #111111). State is never communicated by color alone — icon shape (filled vs outlined) is the primary differentiator.

**During active workout:** Tab bar is hidden. "End Workout" available via top-right and Session Actions menu. "Return to Workout" bar visible on all other screens if session is in progress.

**Routing:** Hash-based. `/#/home`, `/#/program`, `/#/program/week/3`, `/#/history`, `/#/profile`, `/#/session`.

---

## 9. Visual Design Direction

### 9.1 — Color Specification

**Dark mode (default):**

| Element | Foreground | Background | Contrast Ratio | Standard |
|---|---|---|---|---|
| Weight numbers (session) | #FFFFFF | #111111 | 17.9:1 | Passes AA (large text 3:1) |
| Body text, descriptions | #FFFFFF | #111111 | 17.9:1 | Passes AA (4.5:1) |
| Muted text (exercise labels) | #999999 | #111111 | 4.67:1 | Passes AA (4.5:1) |
| Orange accent text (normal) | #FF9500 | #111111 | 4.8:1 | Passes AA (4.5:1) |
| Orange accent text (large) | #FF9500 | #111111 | 4.8:1 | Passes AA (3:1) |
| Plate badge text | #FFFFFF | #C62828 (red) | 5.6:1 | Passes AA |
| Plate badge text | #000000 | #F9A825 (yellow) | 10.3:1 | Passes AA |
| Plate badge text | #FFFFFF | #1565C0 (blue) | 5.5:1 | Passes AA |
| Tab bar inactive icons | #888888 | #111111 | 4.0:1 | Passes non-text 3:1 |
| Set circle border (unfilled) | #888888 | #1A1A1A | 3.3:1 | Passes non-text 3:1 |
| Timer progress ring (track) | #555555 | #1A1A1A | 2.0:1 | Borderline — use #666666 (2.7:1) or fill pattern |
| Timer progress ring (fill) | #FF9500 | #1A1A1A | 4.4:1 | Passes non-text 3:1 |
| Error text | #FF6B6B | #111111 | 5.2:1 | Passes AA |
| Success text | #4CAF50 | #111111 | 4.1:1 | Use for large text only; pair with checkmark |
| Disabled elements | #666666 | #111111 | 2.7:1 | No minimum (WCAG exception), but perceivable |
| Placeholder text | #999999 | #1A1A1A | 3.8:1 | Must meet 4.5:1 — use #AAAAAA (5.6:1) |
| Focus indicator | #FF9500 | n/a | 4.8:1 vs #111111 | 2px outline, visible on all backgrounds |

**Primary background:** #111111
**Card background:** #1A1A1A
**Accent color:** #FF9500 (orange/amber)
**Note:** #FF9500 on #FFFFFF = 2.94:1 (**fails**). If light theme is ever implemented, accent must darken to ~#C67000 for text use.

### 9.2 — Typography & Layout

- Large, bold weight numbers (32-40pt, font-weight 700+, white on near-black)
- Plate breakdown in monospace (14pt minimum, `font-variant-numeric: tabular-nums` for stable layout)
- Card-based layout for exercises in session view
- `-apple-system` font stack; `SF Mono` for weight/plate numbers
- Information density prioritized — no unnecessary decoration
- All text minimum 14pt during active sessions (gym glare readability)
- Respect `prefers-reduced-motion` for all animations
- Consistent weight format throughout: always "315 lb" (never "315" alone, never "315lbs", never "315 pounds" mixed)

### 9.3 — Microinteractions

- Set completion: fill + checkmark + scale (105%) + haptic tap
- All sets done on exercise: checkmark overlay + auto-advance (1.5s, skippable, disabled during VoiceOver)
- Session complete: full-screen summary card with stats, "Done" CTA
- Weight increase between weeks: show delta in accent color ("+ 25 lbs")
- All animations have static alternatives when `prefers-reduced-motion` is active

---

## 10. Accessibility

**WCAG 2.2 AA compliance is a v1 requirement.** This section provides implementation-level specifications.

### 10.1 — Color & Contrast

- All text meets **4.5:1** ratio (normal text <18pt) or **3:1** (large text >=18pt / >=14pt bold) against backgrounds. See Section 9.1 color table.
- All non-text UI components (icons, borders, set circles, progress rings, form inputs) meet **3:1** contrast against adjacent colors (WCAG 1.4.11).
- Never convey state by color alone. Every color indicator has a non-color alternative:
  - Set circles: checkmark (complete) / empty (pending), not just color fill
  - Tab icons: filled (active) / outlined (inactive), not just color change
  - Session status in history: text label ("Completed" / "Partial" / "Skipped"), not colored dots alone
- Plate badges use weight numbers as primary content. Competition plate colors are supplementary decoration only.

### 10.2 — Dynamic Type

`rem` units alone are insufficient for iOS Safari PWAs. Dynamic Type support requires:

1. Use the `-apple-system` font stack (already specified).
2. Detect system text size scale via JavaScript probe:
```javascript
function getDynamicTypeScale() {
  const probe = document.createElement('p');
  probe.style.font = '-apple-system-body';
  probe.style.position = 'absolute';
  probe.style.visibility = 'hidden';
  probe.textContent = 'X';
  document.body.appendChild(probe);
  const computedSize = parseFloat(getComputedStyle(probe).fontSize);
  document.body.removeChild(probe);
  return computedSize / 17; // 17px is default body text
}
document.documentElement.style.setProperty('--dt-scale', getDynamicTypeScale());
```
3. Use `calc()` with `--dt-scale` for element sizing.

**Text size specifications:**

| Element | Base (1x) | Min | Max (AX5) | Notes |
|---|---|---|---|---|
| Weight number (session) | 40px | 32px | 72px | Cap to prevent card overflow |
| Set progress ("SET 3/5") | 24px | 20px | 44px | Must remain single-line |
| Exercise name | 14px | 14px | 24px | Uppercase label |
| Plate breakdown | 14px | 14px | 24px | Monospace; may wrap to second line |
| Rep target | 16px | 14px | 28px | |
| Rest timer countdown | 48px | 40px | 80px | |
| Button text | 18px | 16px | 32px | Button height grows proportionally |
| Tab bar labels | 10px | 10px | 14px | May hide at extreme sizes (icon-only) |
| Body text | 16px | 16px | 28px | |

**Layout at extreme sizes (AX3+, ~2x):** Session view switches from horizontal pager to vertical scrollable list with collapsible exercise sections. Plate text wraps (never truncates). Buttons grow proportionally.

### 10.3 — VoiceOver

All interactive elements have descriptive, dynamic labels. Key patterns:

**Session view:**
- Complete Set button: "Complete set 3 of 5, Squat at 315 pounds, button"
- After set completion: announce "Set 3 complete. Rest timer started, 2 minutes. Set 4 of 5 ready."
- Undo toast: `role="alert"` — "Undo last set. Available for 10 seconds."
- Exercise complete: "Squat complete, all 5 sets done. Tap Next Exercise for Bench Press."
- Navigation buttons: "Previous exercise, Squat, button" / "Next exercise, Deadlift, button"
- Plate breakdown: "Per side: two 45-pound plates, one 10, one 5"
- Weight override: "Weight override for Squat, current 295 pounds, text field"

**Dashboard:**
- Progress bar: announced as value, not separate element: "Operator, Week 3 of 6, program progress 50 percent"
- Active session alert: "Workout in progress, Operator Week 3 Session 5. Return to Workout, button"

**Focus management:**
- Onboarding step changes: focus moves to new step's heading
- Exercise auto-advance: focus moves to new exercise content (or stays if VoiceOver active and auto-advance disabled)
- Modal dialogs: focus trapped within dialog, returns to trigger on dismissal
- Undo toast: announced via `role="alert"`, does not steal focus

### 10.4 — Motor Accessibility

- **All swipe gestures have button alternatives.** Exercise navigation has prev/next buttons. Undo toast has close button or timeout. Weight/rep adjustments have explicit edit buttons (or via Session Actions menu).
- **No multi-touch, long-press, or gesture-only primary actions.**
- **Switch Control compatible:** All interactive elements are focusable. Use `role="group"` on exercise cards for scan grouping. "Complete Set" button is first in DOM order within each card group (use CSS `order` for visual positioning).
- **Session Actions menu** consolidates all workout controls into a single navigation point.
- **"End Workout"** accessible from bottom of screen (via Session Actions menu), not just top-right.
- **Skip navigation link:** Visually hidden "Skip to main content" link at top of each screen, visible on `:focus-visible`.

### 10.5 — Timing

- **Rest timer does not block interaction.** User can complete the next set while timer runs.
- **Rest timer is adjustable** (+30s button, global default in settings).
- **Undo toast: 10-second minimum**, or until next set is completed (whichever comes first). Satisfies WCAG 2.2.1.
- **Auto-advance delay: 1.5s, skippable.** Disabled when VoiceOver is active.

### 10.6 — Haptic Feedback Patterns

Distinct patterns for distinct events:

| Event | Pattern | Audio (if Sound=On) |
|---|---|---|
| Set completion | Single short pulse (50ms) | Short click |
| Exercise complete (all sets) | Double pulse (50ms-pause-50ms) | — |
| Rest timer complete | Triple pulse (50ms-pause-50ms-pause-50ms) | Ascending chime |
| Undo action | Single long pulse (150ms) | — |
| Session complete | Long-short-long (150ms-50ms-150ms) | Completion fanfare |
| Error / invalid action | Two rapid pulses (30ms-pause-30ms) | Low buzz |

Audio uses Web Audio API for low-latency. Pre-load during init. Procedurally generated tones preferred over audio files. Total audio assets < 20KB.

If Vibration API is unavailable, the app does not rely on haptic alone — all events pair with visual + optional audio.

### 10.7 — Testing Requirements

- Test at Dynamic Type sizes: Default, Large, xxxLarge, AX1, AX3, AX5
- Test with VoiceOver enabled on iOS
- Test with Switch Control
- Test with external Bluetooth keyboard
- Automated accessibility audit (axe/Lighthouse) catches ~30% of issues — supplement with manual testing

---

## 11. Security

### 11.1 — Content Security Policy

Deploy with strict CSP header:
```
default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' https://cognito-idp.*.amazonaws.com https://*.execute-api.*.amazonaws.com
```
No `eval`, no inline scripts, no external resources.

### 11.2 — Input Handling

- **Never use `innerHTML` or `dangerouslySetInnerHTML` for user-supplied strings.** All user content (session notes, imported text) rendered via Preact JSX only. Add as a code review rule.
- **Numeric inputs:** Validate on input change AND before writing to IndexedDB. Use `Number()` + `isNaN()` + range clamping. Never `eval()`.
- **Session notes:** Max 500 characters, rendered via JSX only.
- **Hash route values:** Validate route segments against known path patterns before use.

### 11.3 — Import Security

See Section 7.5 for the full import validation checklist, including:
- `JSON.parse()` only
- Prototype pollution defense (reject `__proto__`, `constructor`, `prototype` keys)
- 1MB file size limit
- Numeric range validation
- Confirmation prompt before overwriting

### 11.4 — URL Recovery Security

Values decoded from the URL hash must pass the same validation as manual entry:
- Lift name must be one of 5 known lifts
- Weight 1-1500, reps 1-15
- Never render URL-decoded strings as HTML
- Show confirmation prompt before writing to IndexedDB

### 11.5 — Dependencies

- Pin exact versions in `package.json` (not ranges). Commit lockfile.
- Run `npm audit` in CI.
- Small dependency tree (Preact + idb-keyval + Signals) limits supply chain exposure.

### 11.6 — Deployment

- HTTPS-only with HSTS.
- Service worker requires HTTPS (enforced by browsers).
- No `skipWaiting()` — user explicitly triggers updates.

---

## 12. Out of Scope (v1)

- ~~User accounts / cloud sync / backend~~ (moved to in-scope — see Sections 5.8, 5.9)
- Social features / sharing
- Exercise video demos
- Custom template builder (only the 7 predefined templates)
- Zulu I/A variant (insufficient specification — deferred to v1.1)
- kg unit support (data model ready, UI deferred to v1.1)
- Warm-up set display (v1.1 candidate)
- Conditioning protocol programming (beyond endurance duration ranges)
- Android-specific optimizations (PWA will work, but iOS is priority)
- Light theme development (dark-only for v1; theme toggle framework is in place)
- Operator Black / LP variants (v1.1 candidate)
- Fighter Green / hybrid variants (v1.1 candidate)
- Base Building protocol (out of scope for this user's needs; v1.1+ if distributed)
- PIN lock / biometric lock (data sensitivity does not justify; v1.1 if users request)
- Export encryption (data is low-sensitivity fitness metrics)
- IndexedDB encryption at rest (rely on device-level encryption)

---

## 13. Success Criteria

1. User can enter 1RM data and see all 7 templates fully populated with correct weights and plate breakdowns — matching the spreadsheet output for Training Max at 90% of Epley
2. App installs to iOS home screen and works fully offline
3. User can run through a full workout session with tap-to-complete tracking, rest timer, and undo
4. All data persists across sessions via IndexedDB, with export/import backup available
5. Plate calculator output matches `LoadBarbellConstrained` and `PullupWeightConstrained` for all QA test cases (TC-001 through TC-028)
6. App survives force-quit mid-workout and offers session resume on relaunch
7. Storage eviction is detected (standalone mode + empty IndexedDB heuristic) and user is prompted to restore from backup
8. **All text and non-text elements meet WCAG 2.2 AA contrast requirements** in dark mode
9. Full onboarding flow takes a new user from zero to first workout in under 2 minutes
10. **VoiceOver users can complete a full workout session** using only screen reader interaction + prev/next buttons
11. **Gladiator, Mass Protocol, and Grey Man sessions include all cluster lifts in every session** per TB methodology
12. **Import validation rejects malformed, oversized, or prototype-polluting JSON files** with specific error messages
13. **Current lift values are derived from `maxTestHistory`** — no dual-write inconsistency

---

## Appendix A: Review Files

All review documents are preserved at `/reviews/`:

**Round 1 (PRD v1 -> v2):**
- `pm-review.md` — 22 recommendations (9 critical)
- `ios-engineer-review.md` — 20 recommendations, iOS PWA technical deep-dive
- `ux-review.md` — 20 recommendations, gym-environment UX
- `qa-review.md` — 69 regression test cases, 25 recommendations, plate calculator edge case matrix

**Round 2 (PRD v2 -> v3):**
- `tb-domain-review.md` — 5 critical, 4 high-priority TB methodology corrections
- `data-architecture-review.md` — 3 critical, 6 high-priority, 18 total data model recommendations
- `accessibility-review.md` — 25 recommendations, full WCAG 2.2 AA audit
- `security-review.md` — 18 recommendations, no critical security issues

## Appendix B: Key Changes from v1 -> v2

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
| 9 | Renamed Mass Template -> Mass Strength, Mass -> Mass Protocol | PM #15, QA #6 |
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
| 29 | Renamed Settings tab -> Profile | UX #2 |
| 30 | Added Zulu percentage-to-session mapping (Cluster One/Two) | PM #5, QA #12 |
| 31 | Added failed rep logging | UX #11 |
| 32 | Added session notes | UX #12 |
| 33 | Added undo for set completion | iOS #14, UX #13 |
| 34 | Added weight override per session | UX #4 |
| 35 | Orange accent color for gym visibility | UX #20 |

## Appendix C: Key Changes from v2 -> v3

| # | Change | Source | Priority |
|---|---|---|---|
| 1 | Gladiator: ALL cluster lifts in EVERY session (removed A/B split) | TB Domain #2 | Critical |
| 2 | Mass Protocol: ALL cluster lifts in EVERY session (removed A/B split) | TB Domain #3 | Critical |
| 3 | Grey Man: ALL cluster lifts in EVERY session (removed A/B split) | TB Domain #4 | Critical |
| 4 | Operator Week 6 reps: "1-2" not "1" (3-4 x 1-2) | TB Domain #1 | Critical |
| 5 | Mass Strength: "4 tracked sessions per week" (not per cycle); sessions 2/4 are supplemental | TB Domain #5, #10 | Critical |
| 6 | `profile.lifts` derived from `maxTestHistory` (eliminated dual-write) | Data Arch R1 | Critical |
| 7 | `ActiveSessionState` is self-contained (exercise snapshot, templateId, weightOverrides, status) | Data Arch R2, R3, R10 | Critical |
| 8 | Replaced cookie-based eviction detection with standalone-mode + empty-IndexedDB heuristic | Data Arch R4 | Critical |
| 9 | Pre-session set target selector for range-based templates (Operator, Fighter) | TB Domain #6 | High |
| 10 | Zulu A-day default: Military Press, Squat, WPU (per book's example) | TB Domain #7 | High |
| 11 | Fighter allows Weighted Pull-up as selectable lift | TB Domain #8 | High |
| 12 | "Retest 1RM" is primary CTA on program completion | TB Domain #9 | High |
| 13 | Set/rep ranges shown with actual range notation (3-5 x 5) not resolved to max | TB Domain #6 | High |
| 14 | Added `sourceHash` to `ComputedSchedule` for staleness detection | Data Arch R5 | High |
| 15 | Defined explicit export format (sentinel, versioning, exclude computed) | Data Arch R6 | High |
| 16 | Defined import validation as 12-step sequential checklist | Data Arch R7, Security H1-H4 | High |
| 17 | Added `startedAt`/`completedAt` to `SessionLog` | Data Arch R8 | High |
| 18 | Migration framework with backup-before-migrate | Data Arch R9 | High |
| 19 | Backup reminder shortened from 7 days to 5 days | Data Arch R14 | Medium |
| 20 | Section 10 expanded from 6 bullet points to full WCAG 2.2 AA implementation spec | A11y all | Critical |
| 21 | Specified exact color values with contrast ratios for all elements | A11y #1 | Critical |
| 22 | Added explicit prev/next buttons for exercise navigation | A11y #3 | Critical |
| 23 | Undo toast extended to 10 seconds (from 5) | A11y #4 | Critical |
| 24 | Auto-advance disabled when VoiceOver is active | A11y #5 | Critical |
| 25 | Added form error accessibility (aria-invalid, aria-describedby, role=alert) | A11y #6 | Critical |
| 26 | Set indicators use checkmark + color (not color alone) | A11y #7 | Critical |
| 27 | Plate badges: weight number as primary content, color decorative | A11y #8 | Critical |
| 28 | Added focus management spec for onboarding, session, modals | A11y #9 | Critical |
| 29 | Added non-text contrast minimums (3:1) for UI components | A11y #10 | Critical |
| 30 | Added Dynamic Type implementation spec (JS probe + size table) | A11y #14 | Recommended |
| 31 | Added Sound setting (On/Off/Vibrate Only) | A11y #12 | Recommended |
| 32 | Added haptic pattern specification (6 distinct patterns) | A11y #25 | Recommended |
| 33 | Added 8pt minimum spacing between session view targets | A11y #15 | Recommended |
| 34 | Added template recommendation flow in onboarding | A11y #16 | Recommended |
| 35 | Added Session Actions menu for consolidated VoiceOver/Switch access | A11y #22 | Recommended |
| 36 | Added "Delete All Data" to Settings | Security M1 | Medium |
| 37 | Added privacy statement | Security M4 | Medium |
| 38 | Added CSP header specification | Security M6 | Medium |
| 39 | Added prototype pollution defense in import | Security H1 | High |
| 40 | Added Section 11 (Security) | Security all | New section |
| 41 | Added `crypto.randomUUID()` for ID generation | Data Arch R13 | Medium |
| 42 | Added `validateAppData()` integrity check function | Data Arch R15 | Medium |
| 43 | Session notes max 500 characters | Security M5 | Medium |
| 44 | Zulu naming: "Tier 1/Tier 2" -> "Cluster One/Cluster Two" (per TB book) | TB Domain #5.1 | Low |
