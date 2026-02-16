# PM Review: Tactical Barbell PWA PRD

**Reviewer:** Senior PM
**Date:** 2026-02-15
**PRD Version Reviewed:** Current (PRD.md)
**Verdict:** Strong foundation, but has several specification gaps that will block engineering. Needs one revision pass before sprint planning.

---

## 1. Requirements Completeness

### What's well-covered
- Plate calculator logic is precisely specified (Section 5.2) with both barbell and belt variants, default inventories, greedy algorithm, and error states.
- 1RM calculation formula is clear (Section 5.1) with Epley formula and rounding logic.
- iOS PWA constraints are thoroughly documented (Section 6) with specific meta tags, safe area handling, and touch targets.
- Data model (Section 7) provides a solid starting schema.

### Gaps and missing user stories

**G1 — No "Training Max" vs "True Max" calculation specified.** Section 5.1 lists a "Max Type" toggle for "True Max" or "Training Max" but never defines what "Training Max" means computationally. Tactical Barbell uses Training Max = 90% of True 1RM. If the user enters a True Max, does the app auto-calculate Training Max? Do templates use Training Max or True Max for percentage calculations? This is a critical gap — every single weight in the app depends on this answer.

**G2 — No Military Press 1RM in seed data or Entry tab.** The spreadsheet Entry tab lists Squat (438), Bench (359), Deadlift (499), and Weighted Pull-up (102). The PRD seed data (Section 5.5) has Squat, Bench, Deadlift, and Weighted Pull-up. However, templates Zulu (5.3.3), Fighter (5.3.4), Gladiator (5.3.5), and Mass (5.3.6) all include Military Press as a prescribed lift. There is no Military Press 1RM anywhere in the system. How does the user add it? Is it always optional? What happens when a template calls for Military Press but no 1RM exists?

**G3 — No data export or backup mechanism.** Section 10 explicitly marks "Export/import from Google Sheets" as out of scope, but there is no alternative backup mechanism. All data lives in localStorage, which can be wiped by Safari's aggressive ITP storage policies (7-day cap for non-frequently-visited sites), iOS storage pressure, or a user clearing browser data. A user could lose months of training history with no recovery path. At minimum, a JSON export/import or copy-to-clipboard feature should be considered MVP.

**G4 — No onboarding flow specified.** What does a brand new user see? The PRD jumps straight to "1RM Entry" but there's no walkthrough, empty states for the dashboard, or guidance on which template to pick. First-time user experience is undefined.

**G5 — No units system specified.** The PRD assumes pounds throughout (45 lb barbell, plate weights in lb). Is kg support needed? The spreadsheet uses pounds. If pounds-only is intentional, state it explicitly. If kg is planned for later, the data model needs a `unit` field now.

**G6 — No warm-up set logic.** Most lifters following Tactical Barbell perform warm-up sets before working sets. The spreadsheet may handle this implicitly. The PRD has no mention of warm-up sets, ramp-up percentages, or whether the session view should display them.

**G7 — Missing "deload" or "test week" concept.** Tactical Barbell programs typically end a block with a 1RM test or deload week. The PRD doesn't address what happens at the end of a 6- or 12-week cycle. Does the program just stop? Does it prompt for a new 1RM test? Does it auto-repeat?

---

## 2. Edge Cases & Ambiguity

**E1 — Sets x Reps ranges are ambiguous (Section 5.3.1, 5.3.4).** Operator Week 1 says "3-5 x 5" — does this mean the user chooses between 3, 4, or 5 sets of 5 reps? How is this presented in the UI? A dropdown? A default with override? The Mass template (5.3.6) has fixed "4 x 6" which is unambiguous, but Operator and Fighter use ranges. An engineer will not know how to render this.

**E2 — Gladiator Week 6 "5 x 3-2-1" (Section 5.3.5).** What does "3-2-1" mean? Is it 5 sets where the rep scheme is 3, 2, 1, then what? 3, 2, 1, 3, 2? Or is it a descending scheme across 3 sets (3 reps, 2 reps, 1 rep) and the "5 x" is misleading? This needs explicit clarification with the exact rep count per set.

**E3 — Zulu "Standard vs I/A" variant (Section 5.3.3).** The PRD mentions a "Standard or I/A" variant selectable via dropdown but never defines what the I/A variant changes. Different percentages? Different lifts? Different rep scheme? An engineer cannot implement this.

**E4 — Zulu "Two percentage sets per 6-week block" (Section 5.3.3).** The table shows "A/B One" and "A/B Two" with percentages 70/80/90 and 75/80/90. It's unclear what "One" and "Two" refer to. Are these two sessions per week for each A/B day? Which session on which day uses which percentage set? The mapping from the 4 weekly sessions to these percentage clusters needs to be explicit.

**E5 — Mass Template vs Mass (Sections 5.3.2 and 5.3.6).** There are two templates with "Mass" in the name — "Mass Template" (3 weeks, 6 sessions) and "Mass" (6 weeks, 3 sessions). This will confuse users and engineers alike. They need distinct, unambiguous names.

**E6 — Weighted Pull-up body weight handling.** The `LiftEntry` interface has `isBodyweight: boolean` but the 1RM entry (Section 5.1) asks for "Weight" — does the user enter the added weight only (e.g., 70 lb plate) or total weight (bodyweight + plate)? The seed data shows "Weighted Pull-up: 45 weight, 5 reps, 45.6 1RM" which suggests just the added weight. But then the plate calculator needs to load just the added weight on a belt, while the percentage calculations might need to account for bodyweight. This distinction is critical and unspecified.

**E7 — What happens when plate inventory can't make the weight?** Section 5.2 says show "Not achievable with available plates" — but then what? Does the user get a suggested alternative weight? Can they still track the session? This error state needs UX treatment.

**E8 — Session numbering inconsistencies.** Operator (5.3.1) references "Sessions 1, 3, 5" for strength and "Sessions 2, 4, 6" for endurance. Mass Template (5.3.2) references "Sessions 1, 3, 5" for upper/lower and "Session 6" for deadlift but never mentions Sessions 2 and 4. Are Sessions 2 and 4 rest days? Other training? This is a gap.

**E9 — Historical 1RM data inconsistencies.** The seed data in Section 5.5 shows "Bench 315x3 = 300.2" for Feb 2025. Using Epley: 315 * (1 + 3/30) = 315 * 1.1 = 346.5, not 300.2. Similarly, "Weighted Pull-up 45x5 = 45.6" would be 45 * (1 + 5/30) = 45 * 1.167 = 52.5, not 45.6. Either the formula is wrong, the seed data is wrong, or there's a different calculation being used. This will cause the engineer to question which is the source of truth.

---

## 3. Prioritization — MVP vs v1.1

### Currently in scope that should be deferred to v1.1

**P1 — Theme toggle (light/dark/system).** Dark mode default is fine. Adding a full theme toggle with three states adds UI complexity. Ship dark-only for MVP, add theme switching in v1.1.

**P2 — Rest timer configurability.** A fixed 2:00 rest timer is sufficient for MVP. Making it configurable per-exercise type adds settings UI work for marginal benefit.

**P3 — All 7 templates in MVP is aggressive.** Consider shipping with the 3-4 most-used templates (Operator, Fighter, Zulu are the TB3 staples) and adding Gladiator, Mass, Mass Template, and Grey Man in v1.1. This significantly reduces QA surface area.

**P4 — Completed Sessions Log (Section 5.5).** Session-level history is a "nice to have" for MVP. The 1RM test log is more critical for tracking progression. A simple "sessions completed" counter per program would suffice for MVP.

### Currently out of scope that should be MVP

**P5 — Data backup/export (JSON or clipboard).** As noted in G3, localStorage is fragile on iOS Safari. A simple "Export Data" / "Import Data" button that copies/pastes a JSON blob should be launch-blocking. Without it, a single Safari data clear destroys everything.

**P6 — Empty states and first-run experience.** The app needs to gracefully handle having zero 1RM data, no active program, and no history. These empty states are not specified but are essential for the first launch.

---

## 4. User Journey Gaps

### First-time user flow (walking through it)

1. **User installs PWA from home screen.** OK — Section 6 covers this well.
2. **User opens app for the first time.** Sees... what? The Dashboard (Section 5.4) shows "Active Program" and "Today's Session" — but there is no active program and no sessions. Empty state is undefined.
3. **User needs to enter 1RM data.** Where do they go? Section 4 puts "1RM Entry" under "Settings / Entry." A first-time user looking at a bottom nav with Home / Program / History / Settings would not intuitively go to Settings to start. **Recommendation:** The empty dashboard should have a prominent CTA: "Enter your lift data to get started" that links directly to 1RM entry.
4. **User enters 1RM for Squat.** They enter weight and reps. The Percentage Table (Section 5.1) shows 65-100% values. Good. But how do they enter multiple lifts? Is there a "Save and Add Another" flow? Do they go back and forth? This flow isn't specified.
5. **User tries to select a template.** They go to the Program tab and see 7 templates. How do they decide? There are no descriptions, no recommendations, no comparison view. The user is expected to already know Tactical Barbell methodology. **Recommendation:** Add a brief one-line description per template (e.g., "Operator: Balanced strength + endurance. 3 strength days, 3 cardio days per week").
6. **User selects Operator and starts a program.** Section 5.4 says they pick a start date and the schedule generates. Good. But what if they only entered Squat and Bench 1RMs, and Operator requires Weighted Pull-up too? Is there a validation step? An error? This is unspecified.
7. **User does their first workout.** Session View (Section 5.4) shows exercises, weights, plate breakdown, tap-to-complete. This is well-specified. But what about navigating between sessions? If they miss a day, can they go back? Can they skip ahead? Can they do sessions out of order?
8. **User finishes 6-week cycle.** What happens? Program screen says "Completed"? They're prompted to retest 1RM? They can restart? This end-of-program flow is absent.

### Mid-program scenarios not covered

- **Missed sessions.** No guidance on whether to skip or reschedule.
- **Partial completion.** What if the user does 3 of 5 sets? The `setsCompleted` field in the data model supports this, but the UI behavior isn't described.
- **Mid-cycle 1RM change.** If a user retests mid-program, do all future sessions recalculate? Does the current week change? This is addressed further in Section 6 below.

---

## 5. Template Logic Gaps

### Per-template issues

**T1 — Operator (5.3.1): Endurance sessions are underspecified.** Duration ranges are listed (e.g., "30-60 minutes") but there's no mention of activity type, intensity, or whether the user logs anything beyond "completed." The data model's `ExerciseLog` doesn't accommodate duration-based sessions — it only has `liftName`, `targetWeight`, `setsCompleted`, `repsPerSet`.

**T2 — Mass Template (5.3.2): Sessions 2 and 4 are undefined.** The template says "6 sessions per cycle" but only defines Sessions 1, 3, 5 (Squat/Bench/WPU) and Session 6 (Deadlift). What are Sessions 2 and 4? Rest? Conditioning? Accessory work? This is a significant gap.

**T3 — Zulu (5.3.3): Lift selection is vague.** "User picks lifts from dropdown menus per cluster slot" — but the A/B split shows specific lifts (Military Press, Squat, WPU for A; Bench, Deadlift for B). Is the user required to use these, or can they substitute? If substitutable, from what list? How does this interact with the 1RM entries (you can only pick lifts you've entered 1RM data for)?

**T4 — Zulu (5.3.3): The "optional 3rd slot" for Day B is undefined.** What options go here? Is it user-selected from all lifts? Is it optional to leave empty?

**T5 — Fighter (5.3.4): "User-selected" cluster lifts.** Lists Squat, Bench, Military Press, Deadlift but says "user-selected." How many must they select? All 4? A minimum of 2? The Tactical Barbell book specifies 2-3 lifts for Fighter. This constraint needs to be in the PRD.

**T6 — All templates: No specification for how many exercises per session.** Operator explicitly defines session structures (Sessions 1/3 = SQ/BP/WPU, Session 5 = SQ/BP/DL). But Gladiator, Mass, and Grey Man just say "Cluster lifts: Squat, Bench, Military Press, Deadlift" without defining which lifts appear in which session. Are all 4 lifts performed every session? That's unusual for strength programming.

**T7 — Grey Man (5.3.7): No session structure defined.** 3 sessions per week with 4 cluster lifts — but no mapping of which lifts go on which day. Does every session include all 4 lifts? That would be 4 compound lifts 3x/week, which is a very different program than if they're split across sessions.

**T8 — No accessory work slots.** Most Tactical Barbell users add accessory exercises (rows, curls, ab work) after their main lifts. The PRD has no concept of user-added exercises within a session. Consider at minimum a free-text "notes" field per session.

---

## 6. Data & State Management

**D1 — Mid-program 1RM change.** If a user updates their Squat 1RM from 400 to 425 while in Week 3 of Operator, what happens to Weeks 4-6? Options: (a) recalculate all future sessions, (b) only apply to new programs, (c) ask the user. The PRD is silent. Recommendation: recalculate future sessions automatically with a confirmation prompt.

**D2 — Template switching mid-program.** Can a user switch from Operator to Fighter mid-cycle? Does this abandon the current program? Is there a warning? The `ActiveProgram` data model only holds one template. Switching needs explicit handling.

**D3 — Multiple simultaneous programs.** Can a user run Operator strength sessions alongside a separate conditioning program? The data model's single `ActiveProgram` suggests no, but this is a common Tactical Barbell use case (Base Building + Continuation).

**D4 — localStorage size limits.** Safari's localStorage is capped at ~5MB. If a user runs multiple 12-week Grey Man cycles with full session logs, they could hit this limit. The PRD mentions IndexedDB as an alternative (Section 6.4) but doesn't specify when to use which. Recommendation: use IndexedDB for session logs and 1RM history; localStorage for settings only.

**D5 — Data migration strategy.** No versioning on the data model. When the app updates and the schema changes, how is existing data migrated? A `schemaVersion` field in the stored data is essential from day one.

**D6 — Seed data injection.** Section 5.5 lists historical 1RM test data to seed. How is this injected? Hardcoded on first launch? Importable? If hardcoded, it's specific to one user (the spreadsheet owner). This should be an import mechanism, not hardcoded data.

---

## 7. Specific Recommendations

### Critical (must address before engineering starts)

1. **Define "Training Max" vs "True Max" computation and specify which value templates use for percentage calculations.** This is the single most important gap — every weight in the app depends on it.

2. **Clarify the set/rep range UI pattern.** For ranges like "3-5 x 5," specify: does the user see a default (e.g., 5 sets) with the ability to adjust? Or do they choose before starting? Provide a single consistent interaction model.

3. **Specify Gladiator Week 6 "5 x 3-2-1" rep scheme** with the exact rep count per set.

4. **Define the Zulu I/A variant completely** or remove it from v1 scope.

5. **Map Zulu's "A/B One" and "A/B Two" percentage clusters to specific sessions within the week.** An engineer needs to know: Monday = A-One @ 70%, Wednesday = B-One @ 70%, Thursday = A-Two @ 75%, Saturday = B-Two @ 75% (or whatever the intended mapping is).

6. **Specify session structures for Gladiator, Mass, and Grey Man** — which lifts on which session day, not just a cluster list.

7. **Define what happens to Sessions 2 and 4 in Mass Template.** If they don't exist, call it 4 sessions per cycle, not 6.

8. **Fix the seed data 1RM calculations** (Section 5.5) — the numbers don't match the Epley formula. Specify which is correct: the formula or the data.

9. **Add Military Press to the default lift list** in Section 5.1 and clarify behavior when a template requires a lift the user hasn't entered.

### High Priority (should address before MVP launch)

10. **Add a data export/import feature** (JSON blob) to protect against Safari localStorage eviction. This should be MVP, not v1.1.

11. **Add a `schemaVersion` field** to the data model for future migrations.

12. **Specify first-time user experience** — empty states for Dashboard, Program, and History tabs, plus a clear onboarding path from "no data" to "first workout."

13. **Define end-of-program behavior** — what the user sees after completing a full cycle, and how they transition to a new cycle or 1RM retest.

14. **Specify the data model for endurance/duration-based sessions.** The current `ExerciseLog` interface doesn't support time-based activities.

15. **Rename "Mass Template" and "Mass" to distinct, unambiguous names** (e.g., "Mass Protocol" and "Mass Block" — or use the official TB names if they differ).

16. **Specify how Weighted Pull-up weight input works** — added weight only vs total weight — and how it interacts with the plate calculator and percentage calculations.

### Nice to Have (can address post-launch)

17. **Add brief template descriptions** visible during template selection to help users choose.

18. **Consider a "notes" field per session** for accessory work or user annotations.

19. **Define missed session / out-of-order session behavior** — can users skip ahead or go back?

20. **Add warm-up set display** as a toggle (e.g., show 40%, 50%, 60% of working weight as warm-up ramps).

21. **Specify units explicitly** — pounds-only for v1 is fine, but state it in the PRD and add a `unit` field to the data model for future kg support.

22. **Consider IndexedDB-first architecture** over localStorage to avoid the 5MB cap and get better performance with structured data.

---

## Summary

The PRD is a solid starting point with clear technical constraints and a well-defined plate calculator. However, it has three categories of problems:

1. **Blocking ambiguities** that will immediately stall engineering: Training Max definition (#1), set/rep range UI (#2), Zulu/Gladiator specifics (#3-5), and incomplete template session structures (#6-7).

2. **Missing user journeys** that will result in a confusing first experience: no onboarding, no empty states, no end-of-program flow, no handling of missing 1RM data for required lifts.

3. **Data fragility** that will cause user trust issues post-launch: no backup/export, no schema versioning, reliance on Safari localStorage without eviction protection.

I recommend a focused revision pass addressing items #1-9 (critical) before sprint planning, with items #10-16 tracked as launch-blocking tickets alongside feature development.
