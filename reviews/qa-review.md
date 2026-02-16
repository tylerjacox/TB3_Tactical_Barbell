# QA Review: Tactical Barbell PWA (TB3)

**Reviewer:** Senior QA Engineer
**Date:** 2026-02-15
**Document Reviewed:** PRD.md (v1)
**Risk Level:** HIGH -- plate calculator and template generation are core features with significant edge-case exposure

---

## 1. Plate Calculator Edge Cases

The plate calculator is the highest-risk component. Every weight displayed in every session depends on it. Below are exhaustive test scenarios for both `LoadBarbellConstrained` (barbell) and `PullupWeightConstrained` (belt).

### 1.1 Barbell Loading (`LoadBarbellConstrained`)

Bar weight = 45 lb. Per-side weight = (totalWeight - 45) / 2. Greedy algorithm, largest plates first.

| # | Scenario | Input Weight | Per-Side Calculation | Expected Output | Notes |
|---|----------|-------------|---------------------|-----------------|-------|
| 1 | Empty bar | 45 | (45-45)/2 = 0 | "45 = empty bar" or "45 = bar only" | PRD does not specify display for zero plates. Must define. |
| 2 | Minimum increment above bar | 46.25 | (46.25-45)/2 = 0.625 | "Not achievable with available plates" | 0.625 lb per side -- smallest plate is 1.25 lb. Cannot be achieved. |
| 3 | Smallest achievable above bar | 47.5 | (47.5-45)/2 = 1.25 | "47.5 = 1 x 1.25" | Uses 1x1.25 per side. |
| 4 | Below bar weight | 44 | (44-45)/2 = -0.5 | "Not achievable with available plates" OR error state | Negative per-side. PRD says "insufficient plates" but this is a different class of error. |
| 5 | Zero weight | 0 | (0-45)/2 = -22.5 | Error / "Not achievable" | Same as below-bar but more extreme. |
| 6 | Negative weight | -10 | (-10-45)/2 = -27.5 | Error / "Not achievable" | Should never occur from valid 1RM calculations, but must be guarded. |
| 7 | Weight below bar (e.g., 30) | 30 | (30-45)/2 = -7.5 | "Not achievable with available plates" | User could enter a 1RM of 30 for Military Press. This is a realistic scenario. |
| 8 | Odd decimal per side | 50 | (50-45)/2 = 2.5 | "50 = 1 x 2.5" | Uses 1x2.5 per side. |
| 9 | Max inventory test | 495 | (495-45)/2 = 225 | "495 = 4 x 45, 1 x 25, 1 x 10, 1 x 5" | 180+25+10+5 = 220. Wait -- 225 = 4(45)+1(25)+1(10)+1(5)+1(2.5)+1(1.25) = 180+25+10+5+2.5+1.25 = 223.75. Not achievable. Let me recalculate: 225 per side needs 5x45=225, but only 4x45 available. So 4x45=180, 1x35=35, 1x10=10 = 225. Yes: "495 = 4 x 45, 1 x 35, 1 x 10" |
| 10 | Exceeds max inventory | 600 | (600-45)/2 = 277.5 | "Not achievable with available plates" | Max per side with default inventory: 4(45)+1(35)+1(25)+2(10)+1(5)+1(2.5)+1(1.25) = 180+35+25+20+5+2.5+1.25 = 268.75. So max barbell = 45 + 268.75*2 = 582.5. Anything above 582.5 is not achievable. |
| 11 | Exact max inventory | 582.5 | (582.5-45)/2 = 268.75 | "582.5 = 4 x 45, 1 x 35, 1 x 25, 2 x 10, 1 x 5, 1 x 2.5, 1 x 1.25" | Every plate used. |
| 12 | Non-plate-divisible weight | 46 | (46-45)/2 = 0.5 | "Not achievable with available plates" | 0.5 is not achievable with any standard plate. |
| 13 | Very large weight | 1000 | (1000-45)/2 = 477.5 | "Not achievable with available plates" | Well beyond inventory. |
| 14 | Weight = 45.01 (floating point) | 45.01 | 0.005 per side | "Not achievable" | Floating point dust from rounding. This should never appear if rounding logic is correct, but must be handled. |
| 15 | Weight requiring 35-lb plate | 115 | (115-45)/2 = 35 | "115 = 1 x 35" | Validates 35-lb plate path in greedy algorithm. |
| 16 | Weight that skips 35 | 135 | (135-45)/2 = 45 | "135 = 1 x 45" | Greedy picks 45 first, not 35+10. |
| 17 | Weight needing mixed plates | 260 | (260-45)/2 = 107.5 | "260 = 2 x 45, 1 x 10, 1 x 5, 1 x 2.5" | 90+10+5+2.5 = 107.5. Correct. |

### 1.2 Weighted Pull-up Loading (`PullupWeightConstrained`)

No bar subtraction. Total weight goes directly on belt. Different inventory (2x45 max instead of 4x45).

| # | Scenario | Input Weight | Expected Output | Notes |
|---|----------|-------------|-----------------|-------|
| 18 | Zero weight | 0 | "0 = no plates" or empty state | Weighted pull-up at bodyweight only. PRD does not define this display. |
| 19 | Small weight | 1.25 | "1.25 = 1 x 1.25" | Minimum achievable. |
| 20 | Moderate weight | 45 | "45 = 1 x 45" | Standard case. |
| 21 | Max inventory | 2(45)+1(35)+1(25)+2(10)+1(5)+1(2.5)+1(1.25) = 178.75 | All plates listed | Max achievable belt weight. |
| 22 | Exceeds max | 180 | "Not achievable with available plates" | Above 178.75 max. |
| 23 | Negative weight | -5 | Error / "Not achievable" | Should never occur but must be guarded. |
| 24 | Decimal weight | 2.5 | "2.5 = 1 x 2.5" | Simple case. |
| 25 | Non-achievable decimal | 0.5 | "Not achievable with available plates" | Below smallest plate. |

### 1.3 Critical Questions for PRD

- **Q1:** What is displayed when barbell weight = bar weight (45)? "Bar only"? Empty plate list? The display format in the PRD (`"350 = 3 x 45, 1 x 10, 1 x 5, 1 x 2.5"`) does not cover this.
- **Q2:** What is displayed for weighted pull-up at 0 lbs? This is a valid state when a template prescribes a low percentage of a small 1RM.
- **Q3:** Should weights below bar weight show a distinct error message vs. "not achievable with available plates"? The failure modes are different -- one is a configuration issue (need more plates), the other is a fundamental impossibility.
- **Q4:** Is floating-point tolerance needed? If rounding produces 47.500000001 due to IEEE 754, does the plate calc handle it correctly?

---

## 2. 1RM Calculation Edge Cases

Formula: `1RM = Weight * (1 + Reps / 30)` (Epley). If Reps = 1, 1RM = Weight.

### 2.1 Input Edge Cases

| # | Scenario | Weight | Reps | Expected 1RM | Notes |
|---|----------|--------|------|-------------|-------|
| 1 | Reps = 0 | 200 | 0 | UNDEFINED | PRD says Reps range is 1-15, but does not specify validation behavior. Epley gives 200*(1+0/30) = 200, which is mathematically valid but semantically wrong (0 reps means lift was not completed). |
| 2 | Reps = 1 | 200 | 1 | 200 | PRD specifies: "If Reps = 1, then 1RM = Weight." Bypasses formula. |
| 3 | Reps = 1 via formula | 200 | 1 | 200*(1+1/30) = 206.67 | Formula gives different result than the special case. PRD correctly specifies to use Weight directly. Verify implementation honors this. |
| 4 | Reps = 15 (max stated) | 200 | 15 | 200*(1+15/30) = 300 | Upper bound of stated range. |
| 5 | Reps = 16+ | 200 | 16 | 306.67 | PRD says 1-15 range. Should the input be clamped? Rejected? The Epley formula becomes increasingly inaccurate above 10 reps. |
| 6 | Reps = 30 | 200 | 30 | 200*(1+30/30) = 400 | Mathematically valid but wildly inaccurate for real-world use. |
| 7 | Reps > 30 | 200 | 50 | 200*(1+50/30) = 533.33 | Absurd but unguarded. |
| 8 | Weight = 0 | 0 | 5 | 0*(1+5/30) = 0 | Valid math, but 0 1RM means all percentages are 0. Program becomes meaningless. Should be rejected. |
| 9 | Negative weight | -100 | 5 | -100*(1+5/30) = -116.67 | Negative 1RM. Must be rejected. |
| 10 | Decimal reps | 200 | 3.5 | 200*(1+3.5/30) = 223.33 | PRD says "Number" type. Should reps be integer-only? The `inputmode="decimal"` hint in section 6.3 suggests decimal input is possible. |
| 11 | Very large weight | 1000 | 1 | 1000 | Valid, but will exceed plate inventory for most loads. |
| 12 | Small weight (Military Press) | 65 | 5 | 65*(1+5/30) = 75.83 | Realistic. At 70% = 53.08, rounded to 52.5 (with 2.5 increment). Barbell = 52.5, per side = 3.75. Not achievable. |

### 2.2 Rounding Boundary Cases

Rounding formula: `Math.round(calculatedWeight / roundingIncrement) * roundingIncrement`

| # | Calculated Weight | Increment | Rounded | Notes |
|---|------------------|-----------|---------|-------|
| 1 | 101.25 | 2.5 | 101.25/2.5 = 40.5, round = 41, 41*2.5 = **102.5** | Standard round-up at midpoint. |
| 2 | 101.24 | 2.5 | 101.24/2.5 = 40.496, round = 40, 40*2.5 = **100.0** | Just below midpoint, rounds down. |
| 3 | 101.25 | 5 | 101.25/5 = 20.25, round = 20, 20*5 = **100.0** | Same weight, different increment, different result. |
| 4 | 102.5 | 5 | 102.5/5 = 20.5, round = 21, 21*5 = **105.0** | Midpoint rounds up with Math.round. |
| 5 | 0 | 2.5 | 0 | Zero stays zero. |
| 6 | 1.25 | 2.5 | 1.25/2.5 = 0.5, round = 1, 1*2.5 = **2.5** | Rounds up from half. |
| 7 | 1.24 | 2.5 | 1.24/2.5 = 0.496, round = 0, 0*2.5 = **0** | Rounds to zero. Weight disappears. |
| 8 | 46.25 | 5 | 46.25/5 = 9.25, round = 9, 9*5 = **45** | Rounds down to bar weight. Per side = 0. Empty bar. |

### 2.3 Critical Questions for PRD

- **Q5:** Should reps input be restricted to integers? The PRD says "Number" type but the range "1-15" implies integers. The `inputmode="decimal"` in section 6.3 is a general note and may inadvertently allow decimal reps.
- **Q6:** What happens if 1RM calculates to a weight below bar weight (45)? This is realistic for Military Press or Weighted Pull-ups at low percentages. Should it show "bar only" or show the percentage as unachievable?
- **Q7:** What validation occurs on the Weight input? Minimum? Maximum? The PRD specifies no constraints.
- **Q8:** When rounding produces 0 (see case 7 above), what is displayed? A zero-weight exercise is meaningless.
- **Q9:** The PRD shows 1RM formula but does not specify what "Training Max" vs "True Max" means for the calculation. Is Training Max = some percentage of True Max (commonly 85-90%)? Or is it just a label? This fundamentally changes all calculated weights.

---

## 3. Template Logic Validation

For each template, I evaluate whether an engineer can implement it unambiguously.

### 3.1 Operator (Section 5.3.1)

**Status: AMBIGUOUS -- multiple issues**

| Issue | Detail | Severity |
|-------|--------|----------|
| Sets range "3-5 x 5" | Does the user choose 3, 4, or 5 sets? Is this a user decision per workout? Or is there a default? The PRD does not say. | HIGH |
| Session numbering vs day | "Sessions 1, 3" and "Sessions 2, 4, 6" -- are these sequential within a week (Mon=1, Tue=2, etc.)? Or is Session 1 = first strength, Session 2 = first endurance? | HIGH |
| Session 5 lift swap | Sessions 1 & 3: Squat, Bench, Weighted Pull-up. Session 5: Squat, Bench, **Deadlift**. The Weighted Pull-up is dropped for Deadlift. Is this correct? What if user has no Deadlift 1RM? | MEDIUM |
| Endurance sessions | "User-defined duration ranges" shown as "30-60" etc. Is this just a text label? Does the user input actual duration? Is it tracked? | MEDIUM |
| 6 sessions per week | PRD says "6 (3 strength + 3 endurance)" but the session structure only names 6 sessions total. Are they always alternating (strength, endurance, strength, endurance, strength, endurance)? | MEDIUM |

**Sets/Reps ambiguity detail:** "3-5 x 5" means the user performs somewhere between 3 and 5 sets of 5 reps. The engineer must decide: does the app show "3x5" as default with ability to add sets? Does it show "5x5" and let user skip? Does it prompt the user? This is a UX decision masked as a data specification.

### 3.2 Mass Template (Section 5.3.2)

**Status: AMBIGUOUS -- moderate issues**

| Issue | Detail | Severity |
|-------|--------|----------|
| Sessions 2, 4 undefined | PRD defines Sessions 1, 3, 5 (upper/lower) and Session 6 (Deadlift). What are Sessions 2 and 4? Rest days? Endurance? The "6 per cycle" claim does not match 4 defined sessions. | HIGH |
| "Upper/lower" label | Sessions 1, 3, 5 are described as "upper/lower" but the lifts are Squat, Bench, Weighted Pull-up -- same as Operator. Is "upper/lower" just a label, or are there different exercises on different days? | HIGH |
| 3-week duration | Is this a single 3-week cycle that repeats? Or run once? The PRD does not say how many cycles. | MEDIUM |

### 3.3 Zulu (Section 5.3.3)

**Status: AMBIGUOUS -- significant issues**

| Issue | Detail | Severity |
|-------|--------|----------|
| "Two percentage sets per 6-week block" | The table shows "Weeks 1-3" and "Weeks 4-6" both with "70, 80, 90" and "75, 80, 90". These are identical. Are the two rows (A/B One, A/B Two) performed in the same week? Are they the two sessions per split? | HIGH |
| A/B performed twice each | "A/B split, each performed twice" = 4 sessions/week. So the weekly schedule is A, B, A, B? Or A, A, B, B? | HIGH |
| Standard vs I/A variant | No specification of how the I/A variant differs from Standard. The PRD mentions a dropdown but no structural difference is defined. | CRITICAL |
| "(optional 3rd slot)" on B day | What does this mean? Can the user add a third lift? What lift? This is completely unspecified. | HIGH |
| Which percentage set applies to which session? | If A is performed twice, does session A1 use "A/B One" percentages and A2 use "A/B Two"? Or does week 1 use One and week 2 use Two? | HIGH |

### 3.4 Fighter (Section 5.3.4)

**Status: MOSTLY CLEAR -- minor issues**

| Issue | Detail | Severity |
|-------|--------|----------|
| "User-selected" cluster lifts | All 4 lifts listed (Squat, Bench, Military Press, Deadlift). Does the user pick a subset? How many? All 4 in each session? | MEDIUM |
| Sets range "3-5 x 5" | Same ambiguity as Operator. | HIGH |
| "No back-to-back days" | Is this enforced by the app? Or just guidance? If the user starts the program on Saturday, does the app prevent them from doing session 2 on Sunday? | MEDIUM |

### 3.5 Gladiator (Section 5.3.5)

**Status: AMBIGUOUS**

| Issue | Detail | Severity |
|-------|--------|----------|
| "5 x 3-2-1" in Week 6 | Does this mean 5 sets where: set 1 = 3 reps, set 2 = 2 reps, set 3 = 1 rep, sets 4-5 = ? This notation is unclear. Or is it "5 sets of either 3, 2, or 1 reps"? | CRITICAL |
| 4 lifts, 3 sessions | All 4 lifts listed, 3 sessions per week. Which lifts go in which session? All 4 every session? Rotating? | HIGH |
| No session structure defined | Unlike Operator and Mass Template, there is no session-by-session breakdown. Engineer must guess. | HIGH |

### 3.6 Mass (Section 5.3.6) -- Note: different from "Mass Template" (5.3.2)

**Status: AMBIGUOUS**

| Issue | Detail | Severity |
|-------|--------|----------|
| Naming collision | "Mass Template" (5.3.2) and "Mass" (5.3.6) are different templates. This will cause confusion in code, UI, and conversation. | HIGH |
| 4 lifts, 3 sessions | Same ambiguity as Gladiator. Which lifts in which session? | HIGH |
| "No rest minimums" | Does this mean no rest timer? Or rest timer starts at 0? Or the rest timer feature is hidden for this template? | MEDIUM |

### 3.7 Grey Man (Section 5.3.7)

**Status: MOSTLY CLEAR -- minor issues**

| Issue | Detail | Severity |
|-------|--------|----------|
| 4 lifts, 3 sessions | Same as Gladiator/Mass -- which lifts per session? | HIGH |
| 12-week duration | Longest template. What happens at week 12 completion? Auto-restart? Prompt for new 1RM test? Return to dashboard? | MEDIUM |
| Weeks 9, 12: "3x1" | Single rep sets. These effectively become near-max singles. The plate calculator will be exercised at 95% which is the highest percentage in any template. | LOW |

### 3.8 Cross-Template Summary of Unresolved Issues

| Issue | Affected Templates | Count |
|-------|-------------------|-------|
| Sets range ambiguity (e.g., "3-5 x 5") | Operator, Fighter | 2 |
| Lift-to-session assignment undefined | Gladiator, Mass (5.3.6), Grey Man | 3 |
| Session structure undefined | Gladiator, Mass (5.3.6), Grey Man | 3 |
| Naming collision | Mass Template vs Mass | 2 |
| Variant specification missing | Zulu (Standard vs I/A) | 1 |
| Percentage-to-session mapping unclear | Zulu | 1 |

---

## 4. State Machine for Session Tracking

The PRD describes session tracking (section 5.4) but does not define states or transitions. This must be fully specified.

### 4.1 Proposed Session States

```
States:
  NOT_STARTED  -- Session exists in schedule but user has not opened it
  IN_PROGRESS  -- User has opened the session and completed at least one set (or tapped start)
  PAUSED       -- User navigated away from session view while in progress
  COMPLETED    -- User explicitly marked session as complete
  SKIPPED      -- User skipped this session (moved to next)
  ABANDONED    -- Session was in progress but never completed (stale)
```

### 4.2 Valid State Transitions

```
NOT_STARTED  --> IN_PROGRESS   (user taps "Start Session")
NOT_STARTED  --> SKIPPED       (user skips ahead)
IN_PROGRESS  --> PAUSED        (user leaves session view, app backgrounded, or force quit)
IN_PROGRESS  --> COMPLETED     (user taps "Complete Session")
IN_PROGRESS  --> ABANDONED     (timeout / manual abandon -- see 4.3)
PAUSED       --> IN_PROGRESS   (user returns to session)
PAUSED       --> ABANDONED     (stale timeout exceeded)
PAUSED       --> COMPLETED     (user marks complete from history/dashboard)
SKIPPED      --> NOT_STARTED   (user un-skips? -- PRD does not address)
```

### 4.3 Unspecified Scenarios

| # | Scenario | Question | Recommendation |
|---|----------|----------|----------------|
| 1 | Force-quit mid-session | What state is the session in when the user returns? How is partially-completed set data preserved? | Save state to localStorage on every set completion. On app reopen, detect IN_PROGRESS session and prompt: "Resume session from Week 3, Session 2?" |
| 2 | Open session from 3 days ago | Can the user go back and complete/edit a past session? What if they already started the next one? | Allow viewing past sessions in read-only mode. Allow marking as COMPLETED retroactively if no sets were logged. If sets were logged (PAUSED/ABANDONED), allow resuming. |
| 3 | Multiple sessions in one day | User does two sessions in one day. How is "today's session" determined? | "Today's Session" should show the next NOT_STARTED session in sequence, regardless of date. |
| 4 | Missed weeks | User misses an entire week. Does the program advance? Does week numbering shift? | Program should NOT auto-advance based on calendar dates. It should track by session completion sequence. The user progresses to the next session only when they complete or skip the current one. |
| 5 | Session ordering | Can the user do sessions out of order (e.g., Session 3 before Session 1)? | Recommend: allow it but warn. Log the actual completion order. |
| 6 | App reinstall | localStorage is wiped. What happens? | All data lost. This is a known limitation (PRD section 10: no cloud sync). Should be documented as user-facing warning in Settings. |
| 7 | Auto-abandon timeout | How long until a PAUSED session becomes ABANDONED? | Suggest: 24 hours. Configurable. On next app open, if a session has been PAUSED for >24h, prompt: "You have an incomplete session from [date]. Resume or abandon?" |
| 8 | Completing session with 0 sets done | User opens session, does nothing, taps "Complete." Is this valid? | Should require at least 1 set completed OR show a confirmation: "No sets were recorded. Mark as complete anyway?" |

### 4.4 Data Persistence Points

The following must be saved to localStorage immediately (not just on session completion):

- Each set completion (rep count, timestamp)
- Session state transitions
- Current exercise index within session
- Rest timer state (running/paused/remaining)

---

## 5. Data Validation Rules

The PRD is vague on input constraints. Below is a complete specification for every user-input field.

### 5.1 1RM Entry Fields

| Field | Type | Required | Min | Max | Default | Validation Notes |
|-------|------|----------|-----|-----|---------|-----------------|
| Lift/Movement | enum/string | Yes | -- | -- | None (must select) | One of: "Squat", "Bench", "Deadlift", "Military Press", "Weighted Pull-up". PRD says user can "leave lifts empty" -- unclear if this means they can save without a lift selected or if they skip a lift entirely. |
| Weight | number | Yes | 1 | 1500 | None | Must be positive. Integer or decimal (to 0.25 lb granularity). Zero and negative must be rejected. Max 1500 is generous safety cap. |
| Reps | integer | Yes | 1 | 15 | None | PRD specifies 1-15 range. Must be integer. Enforce in input and validation. |
| Max Type | enum | Yes | -- | -- | "Training Max" | "True Max" or "Training Max". PRD does not define the computational difference. |
| Rounding Increment | enum | Yes | -- | -- | 2.5 | Either 2.5 or 5. No other values. |

### 5.2 Settings Fields

| Field | Type | Required | Min | Max | Default | Validation Notes |
|-------|------|----------|-----|-----|---------|-----------------|
| Barbell Weight | number | Yes | 1 | 100 | 45 | Must be positive. Typical range 15-55 (women's bars, specialty bars). |
| Plate Inventory (qty per plate size) | integer | Yes (per plate) | 0 | 20 | See PRD defaults | Per plate size. Zero means that plate is unavailable. Max 20 is safety cap. |
| Rest Timer Default | integer | Yes | 0 | 600 | 120 | In seconds. 0 = disabled. 600 = 10 minutes (reasonable upper bound). |
| Theme | enum | Yes | -- | -- | "system" | "light", "dark", "system" |

### 5.3 Session Tracking Fields

| Field | Type | Required | Min | Max | Default | Validation Notes |
|-------|------|----------|-----|-----|---------|-----------------|
| Sets Completed (per exercise) | integer | Auto-tracked | 0 | max_sets_for_template | 0 | Incremented by tap. Cannot exceed prescribed sets (or can it? PRD does not specify extra set logging). |
| Reps Per Set | integer | Auto-filled | 0 | 99 | Prescribed reps | Can the user override reps? If they got 4 reps instead of 5, is this logged? PRD does not address failed reps. |
| Session Completion | boolean | User action | -- | -- | false | User explicitly marks complete. |

### 5.4 Program Selection Fields

| Field | Type | Required | Min | Max | Default | Validation Notes |
|-------|------|----------|-----|-----|---------|-----------------|
| Template | enum | Yes | -- | -- | None | One of 7 templates. |
| Start Date | date | Yes | today-7 | today+30 | today | Should not allow start dates far in the past (accidental). Reasonable future limit. |
| Lift Selections (Zulu/Fighter) | enum per slot | Depends on template | -- | -- | None | Template-specific. PRD does not define defaults for customizable slots. |

### 5.5 Critical Questions for PRD

- **Q10:** Can the user log more sets than prescribed? (e.g., template says 3x5 but user does 5x5)
- **Q11:** Can the user log fewer reps than prescribed? (e.g., prescribed 5 reps but only got 3)
- **Q12:** What is the computational difference between "True Max" and "Training Max"? Is Training Max = True Max * 0.9? Or just a label?
- **Q13:** Can the user edit plate inventory to have 0 of all plates? If so, every weight shows "Not achievable."
- **Q14:** What is the minimum/maximum for barbell weight? Can a user set it to 0 (eliminating bar weight)? To 35 (women's bar)?

---

## 6. Destructive Actions & Data Loss

### 6.1 Scenario Matrix

| # | Action | Current Data at Risk | Expected Behavior | PRD Coverage |
|---|--------|---------------------|-------------------|--------------|
| 1 | Change 1RM mid-program | All future session weights change. Past sessions become inconsistent (logged at old 1RM percentages, future at new). | Recalculate all future sessions. Past sessions retain their logged weights. Warn user: "Changing your 1RM will update all remaining sessions in your current program." | NOT SPECIFIED |
| 2 | Switch templates mid-program | Current program progress lost. | Require confirmation: "Switching templates will end your current program. Session history will be preserved. Continue?" | NOT SPECIFIED |
| 3 | Clear history | 1RM test log and completed sessions lost. | Two-step confirmation. Never auto-clear. Consider: "Clear session history" vs "Clear 1RM history" as separate actions. | NOT SPECIFIED |
| 4 | Reinstall / clear browser data | ALL data lost (localStorage wiped). | No recovery possible (no cloud sync). Show warning in Settings: "All data is stored locally on this device. Clearing browser data or reinstalling will erase all data." | PARTIALLY (Section 10 mentions no cloud sync but no user-facing warning specified) |
| 5 | Change rounding increment mid-program | All displayed weights shift. | Recalculate all future sessions. Past sessions retain logged weights. | NOT SPECIFIED |
| 6 | Change barbell weight | All plate breakdowns change. | Recalculate. Warn if new bar weight causes more "Not achievable" results. | NOT SPECIFIED |
| 7 | Change plate inventory | Some previously achievable weights may become unachievable. | Recalculate all plate breakdowns. Highlight any sessions where weights are now unachievable. | NOT SPECIFIED |
| 8 | Change start date of active program | Shifts entire schedule. | Should be allowed but warn about completed sessions becoming "before start date." | NOT SPECIFIED |
| 9 | Delete a lift's 1RM data | Templates referencing that lift lose their weights. | Require confirmation. Affected template sessions should show "1RM not set" instead of crashing. | NOT SPECIFIED |

### 6.2 Data Preservation Rules (Recommended)

1. **Past session logs are IMMUTABLE.** Once completed, they record what actually happened. Changing settings/1RMs never retroactively modifies completed session data.
2. **Future sessions are DYNAMIC.** They reflect current settings and 1RMs at the time they are viewed.
3. **1RM history is append-only.** New entries do not delete old entries. The most recent entry per lift is used for calculations.
4. **Template switching preserves history.** Completed sessions from the previous template remain in the log.
5. **Provide explicit "Export Data" option.** Even without cloud sync, allow JSON export to clipboard or file for manual backup.

---

## 7. Regression Test Suite

Organized by priority. Tests marked [P0] must pass before any release. [P1] for major releases. [P2] for polish.

### 7.1 Plate Calculator Tests

| # | Test Case | Priority | Expected Result |
|---|-----------|----------|-----------------|
| TC-001 | LoadBarbell(135) | P0 | Per side = 45. Output: "1 x 45" |
| TC-002 | LoadBarbell(225) | P0 | Per side = 90. Output: "2 x 45" |
| TC-003 | LoadBarbell(315) | P0 | Per side = 135. Output: "3 x 45" |
| TC-004 | LoadBarbell(405) | P0 | Per side = 180. Output: "4 x 45" |
| TC-005 | LoadBarbell(45) (empty bar) | P0 | Output: "bar only" or empty plate list (define convention) |
| TC-006 | LoadBarbell(50) | P0 | Per side = 2.5. Output: "1 x 2.5" |
| TC-007 | LoadBarbell(47.5) | P0 | Per side = 1.25. Output: "1 x 1.25" |
| TC-008 | LoadBarbell(46.25) | P0 | Per side = 0.625. Output: "Not achievable with available plates" |
| TC-009 | LoadBarbell(44) | P0 | Below bar weight. Output: "Not achievable" or distinct error |
| TC-010 | LoadBarbell(0) | P0 | Output: "Not achievable" |
| TC-011 | LoadBarbell(-10) | P0 | Output: "Not achievable" |
| TC-012 | LoadBarbell(582.5) (max inventory) | P0 | All plates used. Output: "4 x 45, 1 x 35, 1 x 25, 2 x 10, 1 x 5, 1 x 2.5, 1 x 1.25" |
| TC-013 | LoadBarbell(585) (exceeds max) | P0 | Output: "Not achievable with available plates" |
| TC-014 | LoadBarbell(260) (mixed plates) | P0 | Per side = 107.5. Output: "2 x 45, 1 x 10, 1 x 5, 1 x 2.5" |
| TC-015 | LoadBarbell(115) (uses 35-lb plate) | P1 | Per side = 35. Output: "1 x 35" |
| TC-016 | LoadBarbell(185) | P0 | Per side = 70. Output: "1 x 45, 1 x 25" |
| TC-017 | LoadBarbell(155) | P0 | Per side = 55. Output: "1 x 45, 1 x 10" |
| TC-018 | PullupWeight(0) | P0 | Output: "no plates" or equivalent |
| TC-019 | PullupWeight(45) | P0 | Output: "1 x 45" |
| TC-020 | PullupWeight(90) | P0 | Output: "2 x 45" |
| TC-021 | PullupWeight(95) | P0 | Output: "2 x 45, 1 x 5" |
| TC-022 | PullupWeight(178.75) (max belt) | P0 | All belt plates used |
| TC-023 | PullupWeight(180) (exceeds max belt) | P0 | Output: "Not achievable" |
| TC-024 | PullupWeight(1.25) | P1 | Output: "1 x 1.25" |
| TC-025 | PullupWeight(-5) | P1 | Output: "Not achievable" |
| TC-026 | LoadBarbell with custom inventory (0 of all plates) | P1 | All weights show "Not achievable" |
| TC-027 | LoadBarbell with custom inventory (10x45 per side) | P1 | Handles expanded inventory correctly |
| TC-028 | Floating point: LoadBarbell(47.5000001) | P1 | Handles gracefully, same as 47.5 |

### 7.2 1RM Calculation Tests

| # | Test Case | Priority | Expected Result |
|---|-----------|----------|-----------------|
| TC-029 | Epley: W=200, R=5 | P0 | 200*(1+5/30) = 233.33... rounded per increment |
| TC-030 | Reps=1 bypass: W=300, R=1 | P0 | 1RM = 300 (not 310) |
| TC-031 | Boundary: W=200, R=15 | P0 | 200*(1+15/30) = 300 |
| TC-032 | Rounding: 233.33 with increment 2.5 | P0 | 233.33/2.5 = 93.33, round=93, 93*2.5 = 232.5 |
| TC-033 | Rounding: 233.33 with increment 5 | P0 | 233.33/5 = 46.67, round=47, 47*5 = 235 |
| TC-034 | Percentage: 1RM=300, 70% | P0 | 210, plate calc output valid |
| TC-035 | Percentage: 1RM=300, 95% | P0 | 285, plate calc output valid |
| TC-036 | Percentage table shows all 8 values | P0 | 65%, 70%, 75%, 80%, 85%, 90%, 95%, 100% all present |
| TC-037 | Small 1RM: W=65, R=5 = 75.83 at 70% = 53.08, round to 52.5 | P0 | Plate calc for barbell: per side = 3.75, not achievable. Should show error. |
| TC-038 | Small 1RM for pull-up: W=10, R=5 = 11.67 at 70% = 8.17, round to 7.5 | P0 | Plate calc for belt: 7.5 = "1 x 5, 1 x 2.5". Valid. |

### 7.3 Template Generation Tests

| # | Test Case | Priority | Expected Result |
|---|-----------|----------|-----------------|
| TC-039 | Operator: All 6 weeks generate correctly | P0 | 6 weeks, correct percentages per week, correct session structure |
| TC-040 | Operator: Week 3 shows 90% weights | P0 | All lifts at 90% of 1RM, correctly rounded and plate-loaded |
| TC-041 | Operator: Deadlift only in Session 5 | P0 | Sessions 1,3: no Deadlift. Session 5: has Deadlift, no Weighted Pull-up |
| TC-042 | Operator: Endurance sessions show duration | P0 | Sessions 2,4,6 show duration ranges, no plate math |
| TC-043 | Mass Template: 3 weeks generate | P0 | Correct percentages, Session 6 has different sets for Deadlift |
| TC-044 | Zulu: A/B split sessions generated | P0 | 4 sessions/week, correct lift assignments |
| TC-045 | Fighter: 2 sessions/week | P0 | Only 2 sessions per week generated |
| TC-046 | Gladiator: Week 6 "5 x 3-2-1" parsed correctly | P0 | Whatever interpretation is chosen, it renders without error |
| TC-047 | Grey Man: Full 12 weeks generated | P0 | All 12 weeks, 3 sessions each, correct percentages |
| TC-048 | Grey Man: Week 9 at 95% | P0 | 3x1 at 95%. Near-max singles load correctly. |
| TC-049 | Template with missing 1RM for a lift | P0 | Graceful handling: show "Set 1RM for [Lift]" instead of NaN/crash |
| TC-050 | Template with all lifts at 0 | P1 | All weights show 0 or "Set 1RM" |

### 7.4 Session Tracking Tests

| # | Test Case | Priority | Expected Result |
|---|-----------|----------|-----------------|
| TC-051 | Start session, complete all sets, mark complete | P0 | Session moves to COMPLETED, appears in history |
| TC-052 | Start session, force-quit app, reopen | P0 | Session is resumable from last saved state |
| TC-053 | Complete session, verify history entry | P0 | History shows date, template, week, session number, exercises |
| TC-054 | Skip a session | P1 | Next session becomes available. Skipped session is marked. |
| TC-055 | Open app after 1 week of inactivity | P1 | App shows correct "next session" based on completion, not calendar |
| TC-056 | Complete final session of program | P0 | Program marked complete. Dashboard updates. User prompted for next action. |
| TC-057 | Tap set complete, then undo | P1 | Set count decrements. Data saved correctly. |

### 7.5 Data Persistence Tests

| # | Test Case | Priority | Expected Result |
|---|-----------|----------|-----------------|
| TC-058 | Enter 1RM, close app, reopen | P0 | 1RM data persists |
| TC-059 | Change settings, close app, reopen | P0 | Settings persist |
| TC-060 | Active program state persists across app restarts | P0 | Week, session, completion status all preserved |
| TC-061 | History entries persist across app restarts | P0 | All logged sessions and 1RM tests remain |
| TC-062 | localStorage full (5MB limit in Safari) | P1 | Graceful error message, not silent failure |
| TC-063 | Seed data (section 5.5) loads on first launch | P1 | 8 historical 1RM entries present |

### 7.6 PWA / iOS Tests

| # | Test Case | Priority | Expected Result |
|---|-----------|----------|-----------------|
| TC-064 | Add to Home Screen, launch as standalone | P0 | No Safari chrome, standalone display |
| TC-065 | Airplane mode: full functionality | P0 | All features work offline |
| TC-066 | Safe area insets respected (notch, home indicator) | P0 | No content hidden behind hardware elements |
| TC-067 | Touch targets >= 44x44pt | P0 | All interactive elements meet Apple HIG minimum |
| TC-068 | Number input triggers numeric keyboard | P1 | Weight and reps fields show number pad |
| TC-069 | Pull-to-refresh disabled | P1 | overscroll-behavior prevents accidental refresh |

---

## 8. Specific Recommendations

Numbered list of concrete changes to the PRD, ordered by severity.

### Critical (Must fix before engineering starts)

1. **Define "Training Max" computation.** The PRD references "True Max" vs "Training Max" toggle but never defines the computational difference. If Training Max = 90% of calculated 1RM (the Tactical Barbell convention), this must be stated explicitly with the exact multiplier. This changes every weight in every template.

2. **Resolve Gladiator Week 6 "5 x 3-2-1" notation.** This is unparseable as written. Clarify whether this means: (a) 5 sets descending: 3, 2, 1, ?, ? reps; (b) 3 sets of 3, then 1 set of 2, then 1 set of 1; (c) some other scheme. Provide exact set/rep structure.

3. **Specify Zulu "Standard vs I/A" variant differences.** The PRD offers a dropdown to select the variant but provides zero specification of how they differ. An engineer cannot implement this.

4. **Define session structures for Gladiator, Mass (5.3.6), and Grey Man.** These templates list 3-4 lifts and 3 sessions/week but never specify which lifts go in which session. Provide a session-by-session breakdown like Operator has.

5. **Resolve sets-range ambiguity ("3-5 x 5").** Define whether the app should: (a) show a fixed default (e.g., 5x5) with ability to remove sets; (b) let the user choose before starting; (c) always show the minimum (3x5). This affects Operator, Fighter, and potentially others. Pick one approach and apply consistently.

6. **Rename "Mass Template" (5.3.2) or "Mass" (5.3.6).** Having two templates both named "Mass" is a naming collision that will cause bugs, user confusion, and UI ambiguity. Suggest: rename 5.3.2 to "Mass Protocol" or "Hypertrophy Block."

### High (Should fix before engineering starts)

7. **Define display format for empty bar (weight=45).** Add to section 5.2: "If total weight equals barbell weight, display 'Bar only' with no plate list."

8. **Define display format for weighted pull-up at 0 lbs.** Add to section 5.2: "If weighted pull-up weight equals 0, display 'Bodyweight only' with no plate list."

9. **Specify what happens when calculated weight is below bar weight.** This is realistic for low percentages of small 1RMs (Military Press at 65% of a 100 lb 1RM = 65 lb, which is fine, but 65% of a 70 lb 1RM = 45.5, which rounds to 45 = empty bar). Define behavior.

10. **Add input validation constraints to section 5.1.** Specify: Weight min=1, max=1500; Reps min=1, max=15 (integer only); Weight must be positive number. Currently the PRD says "Number" with no bounds.

11. **Specify behavior for Mass Template Sessions 2 and 4.** Section 5.3.2 claims "6 per cycle" but only defines Sessions 1, 3, 5, and 6. What are Sessions 2 and 4?

12. **Define Zulu percentage-to-session mapping.** The table shows "A/B One" and "A/B Two" rows but does not specify which row applies to which of the two A (or B) sessions in a week.

13. **Define "optional 3rd slot" for Zulu B day.** What lift options are available? Is this configurable? Can it be left empty?

14. **Specify failed rep handling.** Can users log fewer reps than prescribed? If a user gets 3 reps instead of 5, is this tracked? This is extremely common in training.

### Medium (Should fix before beta)

15. **Add destructive action confirmations.** Section 5.4 should specify confirmation dialogs for: changing 1RMs mid-program, switching templates, clearing history. Define the dialog text and user options.

16. **Add session state machine.** Include the states (NOT_STARTED, IN_PROGRESS, PAUSED, COMPLETED, SKIPPED) and valid transitions in the PRD. Define force-quit recovery behavior.

17. **Specify program completion behavior.** What happens when the user finishes the last session of a template? Options: show completion summary, prompt for new 1RM test, prompt for template reselection, or return to dashboard.

18. **Add data backup/export recommendation.** Even without cloud sync, allow JSON export to clipboard. Add to section 5.6 Settings: "Export Data" and "Import Data" options.

19. **Define localStorage quota handling.** Safari limits localStorage to ~5MB. With session history accumulating, specify what happens when storage is full. Options: delete oldest sessions, warn user, switch to IndexedDB.

20. **Add floating-point tolerance to plate calculator.** Specify that the plate calculator should round the per-side weight to the nearest 0.01 before attempting plate matching, to handle IEEE 754 floating-point artifacts.

### Low (Nice to have)

21. **Clarify Reps=0 behavior in 1RM entry.** Even though the stated range is 1-15, add explicit rejection behavior: "Reps must be between 1 and 15. If 0 is entered, show validation error."

22. **Clarify whether plate inventory quantities can be 0.** If a user sets all plate quantities to 0, every weight becomes "Not achievable." This is technically valid but useless. Consider a minimum of 1 for at least the 45-lb plate.

23. **Add accessibility note for color-blind users.** If completion status uses only color (green=done, red=missed), add a secondary indicator (checkmark, X) for accessibility.

24. **Define rest timer behavior when app is backgrounded.** Does the timer continue in the background? iOS PWAs have limited background execution. The timer likely needs to compare timestamps rather than use setInterval.

25. **Specify seed data behavior.** Section 5.5 shows 8 historical 1RM entries. Are these hard-coded on first launch? Or is this just test data for development? If hard-coded, the 2025 dates will look odd if the user installs in 2026+.

---

## Appendix A: Maximum Achievable Weights

For reference during testing, here are the maximum achievable weights with default plate inventories.

**Barbell (default inventory, per side):**
- 4x45 + 1x35 + 1x25 + 2x10 + 1x5 + 1x2.5 + 1x1.25 = 268.75 per side
- Max barbell weight = 45 + (268.75 * 2) = **582.5 lb**

**Belt/Pull-up (default inventory):**
- 2x45 + 1x35 + 1x25 + 2x10 + 1x5 + 1x2.5 + 1x1.25 = **178.75 lb**

## Appendix B: Percentage Table for Common 1RMs

For spot-checking template generation (rounding increment = 2.5):

| 1RM | 65% | 70% | 75% | 80% | 85% | 90% | 95% |
|-----|-----|-----|-----|-----|-----|-----|-----|
| 300 | 195 | 210 | 225 | 240 | 255 | 270 | 285 |
| 315 | 205 | 220 | 236.25->237.5 | 252->252.5 | 267.75->267.5 | 283.5->282.5* | 299.25->300 |
| 400 | 260 | 280 | 300 | 320 | 340 | 360 | 380 |
| 75  | 48.75->50 | 52.5 | 56.25->57.5 | 60 | 63.75->62.5* | 67.5 | 71.25->72.5 |

*Note: 283.5/2.5 = 113.4, rounds to 113, 113*2.5 = 282.5 (rounds DOWN). Verify this is acceptable vs. always rounding up.

*Note: 63.75/2.5 = 25.5, rounds to 26, 26*2.5 = 65... wait, 25.5 rounds to 26 via Math.round (banker's rounding does not apply in JS). 26*2.5 = 65. Let me recheck: 75 * 0.85 = 63.75. 63.75/2.5 = 25.5. Math.round(25.5) = 26 in JavaScript. 26*2.5 = 65. So the table entry should be 65, not 62.5. This highlights why precise test vectors matter.

## Appendix C: Epley Formula Verification

| Weight | Reps | Calculated 1RM | Notes |
|--------|------|----------------|-------|
| 355 | 5 | 355 * (1 + 5/30) = 355 * 1.1667 = 414.17 | PRD seed data says 359.5 -- MISMATCH. 355*(1+5/30) = 414.17, not 359.5. The seed data appears to use a DIFFERENT formula or represents a training max adjustment. |
| 315 | 3 | 315 * (1 + 3/30) = 315 * 1.1 = 346.5 | PRD seed data says 300.2 -- MISMATCH. |
| 405 | 3 | 405 * (1 + 3/30) = 405 * 1.1 = 445.5 | PRD seed data says 386.0 -- MISMATCH. |
| 45 | 5 | 45 * (1 + 5/30) = 45 * 1.1667 = 52.5 | PRD seed data says 45.6 -- MISMATCH. |

**CRITICAL FINDING:** The seed data in PRD section 5.5 does NOT match the Epley formula specified in section 5.1. Either:
1. The seed data uses a different formula (possibly Brzycki: `Weight * 36 / (37 - Reps)`).
2. The seed data represents Training Max values (some percentage of the calculated 1RM).
3. The seed data is simply incorrect.

Let me check Brzycki for the first entry: 355 * 36 / (37 - 5) = 355 * 36 / 32 = 399.375. Still not 359.5.

Let me check if 359.5 is a Training Max at some percentage: 414.17 * X = 359.5 gives X = 0.868. Not a standard percentage.

**This discrepancy must be resolved before implementation.** Engineers will not know which numbers are correct: the formula or the seed data.

---

*End of QA Review*
