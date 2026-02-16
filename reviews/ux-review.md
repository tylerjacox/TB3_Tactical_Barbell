# UX Review: Tactical Barbell PWA

**Reviewer:** Senior UX Designer (Mobile Fitness / Apple HIG)
**Document reviewed:** PRD.md
**Date:** 2026-02-15

---

## 1. Gym Environment Constraints

The PRD acknowledges iOS optimization and minimum 44x44pt touch targets, but does not explicitly design for the real-world conditions of a gym floor. These constraints are non-negotiable and should inform every screen:

**Sweaty hands / chalk residue.** Touch targets at 44pt are the Apple minimum, not a gym-appropriate target. Sweaty or chalky fingers reduce touch accuracy significantly. Primary actions during a workout (completing a set, starting a rest timer) should use oversized tap zones — 56pt minimum, ideally 64pt for the set-completion buttons. The PRD's "circles or checkboxes per set" risks being too small. A full-width row tap or large circular button per set is safer.

**Bright overhead lighting and screen glare.** The PRD specifies dark mode default, which is correct. However, gym overhead fluorescent or LED lighting creates significant screen glare. The design needs to go further:
- Weight numbers should be extra-bold (700+) and high-contrast white on near-black, not medium gray.
- The accent color choice matters — blue washes out under fluorescent light more than warm colors. Orange or amber is a better gym-readable accent.
- Plate breakdown text is specified as "smaller monospace" — it needs to remain at least 14pt even as secondary information, or it becomes unreadable on a glare-washed screen.

**Distraction between sets.** Users check their phone, reply to a text, switch apps. When they come back to the PWA, they need instant re-orientation: "What set am I on? What's the weight? How long have I been resting?" The PRD does not address app re-entry state or visual anchoring. There is no mention of keeping the active session view as the locked/default view when the user returns.

**One-handed operation.** The PRD mentions this as a goal but does not map controls to thumb-reachable zones. On modern iPhones (6.1"+ screens), the top 30% of the screen is unreachable with one hand. All primary session actions (complete set, next exercise, start timer) must sit in the bottom 60% of the viewport. The exercise name and weight can sit higher as read-only information.

**Phone laying flat on a bench.** Many lifters set their phone on a flat bench between sets and glance down at it. This means:
- Viewing angle is steep — text must be large enough to read from ~2 feet away at a downward angle.
- The most important information (current weight, set count, rest timer) should be in the vertical center of the screen, not the top — the top is hardest to read at a steep angle.
- Auto-brightness or a "gym mode" with boosted brightness would help, though this is out of PWA scope.

**Recommendations for Section 5.4 and Section 9:**
- Increase minimum touch targets for session-critical actions to 56pt.
- Move all interactive session controls to the bottom half of the screen.
- Specify a "sticky session" behavior so returning to the PWA always shows the active workout.
- Use orange/amber as the primary accent for gym-light readability.
- Set a minimum font size of 14pt for all text visible during a session.

---

## 2. Information Hierarchy in Session View

The Session View is the most important screen in the app — the user will spend 90%+ of their in-app time here. The PRD (Section 5.4) lists the following per exercise: exercise name, working weight (bold, large), plate breakdown, prescribed sets x reps, tap-to-complete set tracker, and an optional rest timer. The ordering and emphasis need refinement.

**What the user needs at a glance (0.5 seconds):**
1. **Which set am I on?** — This is the single most critical piece of information when glancing down at a phone on a bench. The current set number out of total (e.g., "Set 3 of 5") should be the most visually prominent element, not buried in a row of circles.
2. **What's the weight?** — Bold and large, as specified. Correct.
3. **Rest timer countdown** — If resting, this replaces set count as the primary glance information.

**What the user needs at a read (2-3 seconds):**
4. **Plate breakdown** — So they can load the bar. Important at the start of an exercise, less so mid-sets.
5. **Exercise name** — Usually already known from context, but serves as a label.
6. **Reps target** — Needed before each set, but usually memorized after set 1.

**Current hierarchy problem:** The PRD puts exercise name first, weight second, plates third, sets x reps fourth. This is an information-entry hierarchy (how you'd read a spreadsheet), not a workout-execution hierarchy. During execution, the user already knows the exercise — they're standing in front of the squat rack. They need set progress and weight.

**Recommended hierarchy (top to bottom of exercise card):**
1. Exercise name — small, uppercase label (12-14pt, muted color)
2. Set progress — large, prominent (e.g., "SET 3 / 5" or visual dots with the current one highlighted)
3. Working weight — largest number on screen (32-40pt, bold)
4. Plate breakdown — secondary line below weight (14-16pt, monospace)
5. Reps target — next to or below set progress ("x 5 reps")
6. Tap target to complete set — full-width button at bottom of card

**Additional concern:** The PRD shows a flat list of exercises. In practice, the user is only working on one exercise at a time. The active exercise should be expanded/focused, with completed and upcoming exercises collapsed. A vertically-scrolling card stack where the current exercise is full-screen and the user swipes to advance would reduce cognitive load.

---

## 3. First-Time User Experience

The PRD does not address onboarding at all. Walking through the new-user flow as described:

1. **Install:** User navigates to URL in Safari, taps Share > Add to Home Screen. This is a well-known iOS friction point — there is no in-app prompt for this. The PRD should specify a "Add to Home Screen" instructional banner on first web visit.

2. **First launch:** User sees... the Dashboard? It will be empty — no program, no 1RM data, no sessions. The PRD's Dashboard shows "Active Program" and "Today's Session," both of which will be blank. This is a dead-end first impression.

3. **Enter 1RM data:** The user must navigate to Settings (tab 4) to find 1RM Entry. This is unintuitive — new users expect Settings to contain preferences, not primary data entry. The 1RM entry is the foundational action of the entire app and is buried in the last tab.

4. **Select a template:** User must then go to Program (tab 2) and pick a template. But they need to understand the Tactical Barbell system to know which template to pick. The PRD provides no guidance, comparison, or recommendation.

5. **Start a program:** User sets a start date or taps "Start Today." Now the Dashboard populates.

**Friction points identified:**
- Empty state on Dashboard offers no guidance.
- 1RM entry is in Settings, not in the onboarding flow.
- No template comparison or recommendation for new users.
- No progressive disclosure — the user must configure everything before seeing any value.
- No sample data or preview mode ("Here's what your workout will look like").

**Recommended onboarding flow:**
1. First launch shows a focused setup wizard (not the tab bar).
2. Step 1: "Enter your lifts" — 1RM entry for core lifts, with clear explanation.
3. Step 2: "Choose your template" — cards with brief descriptions, session frequency, and duration. Highlight recommended template for beginners (Operator or Fighter).
4. Step 3: "Review your first week" — show the generated program with real weights so the user sees immediate value.
5. Step 4: "Start training" — drops user into Dashboard with program active.
6. "Add to Home Screen" prompt appears after setup completion, not before.

---

## 4. Navigation & Flow

**4-tab bottom bar assessment:**
The 4-tab structure (Home, Program, History, Settings) is standard and appropriate for the app's information architecture. Four tabs are within Apple's recommended range (3-5) and keep the bar uncluttered.

**Problem: 1RM Entry location.** As noted in Section 3, 1RM Entry is under Settings. This is the second most important feature after Session View. It should either:
- Live under a dedicated tab, or
- Be accessible from the Home/Dashboard with a prominent entry point, or
- The Settings tab should be renamed to something like "Profile" or "Lifts" to signal that it contains primary data, not just preferences.

**During an active workout:**
The PRD does not address navigation behavior during an active session. This is a critical gap. When a workout is in progress:
- The bottom tab bar should either be hidden or visually de-emphasized. Accidentally tapping "History" mid-workout and losing your place is a real scenario with sweaty-hand mis-taps.
- A persistent mini-bar or floating indicator should show "Workout in progress" on all other tabs, with a tap to return.
- The Session View should be the default view when the app is foregrounded during an active workout, regardless of which tab was last active.

**Moving between exercises:**
The PRD shows a list of exercises but does not specify the navigation pattern between them. Options:
- **Vertical scroll (current implicit design):** Simple, but the user must scroll past completed exercises. Gets worse as the session progresses.
- **Horizontal swipe / pager (recommended):** Each exercise is a full card. Swipe left to advance to the next exercise. Swipe right to review a previous one. A dot indicator or small progress bar at the top shows position. This keeps focus on one exercise at a time and is natural for one-handed use.
- **Auto-advance:** After completing all sets for an exercise, auto-scroll or auto-advance to the next one with a brief animation.

**Endurance sessions:**
The PRD mentions these show "prescribed duration range" but does not detail the UX. An endurance session (e.g., "30-60 min") needs: a start button, a running clock, and a completion button. This is a fundamentally different interaction from the strength session and should have its own simplified view.

---

## 5. Plate Breakdown Display

The current format from the spreadsheet is: `3x45 | 1x10 | 1x5 | 1x2.5`

This is functional but optimized for a spreadsheet cell, not a phone screen. Problems:
- Pipe separators add visual noise.
- "3x45" requires mental parsing — is that 3 plates of 45, or 3 times 45?
- All plates have equal visual weight, but the user cares most about "how many 45s?" since those are the big plates they grab first.

**Recommended alternatives:**

**Option A: Visual plate stack (preferred).** Render colored rectangles or rounded badges proportional to plate size, arranged horizontally to mimic the barbell. Each badge shows the plate weight. This is immediately scannable — the user sees the physical shape of what they need to load. Similar to what apps like Strong and Caliber use.

```
[45][45][45][10][5][2.5]    per side
```

Color-code by plate size (45=red, 35=blue, 25=yellow, 10=green, 5=white, 2.5=gray) using standard competition plate colors that lifters already know.

**Option B: Grouped text with emphasis.** Keep text-based but improve scanability:
```
45 x3   10   5   2.5       per side
```
The largest plate and its count are emphasized (bold/larger). Smaller plates are listed individually since there's usually only one of each. Drop the pipe separators and "1x" prefixes.

**Option C: Icon-based.** Small circle icons sized relative to plate weight, with the weight number inside. Quick to scan, more compact than Option A.

**Regardless of format:**
- Always label "per side" explicitly — ambiguity about whether the breakdown is per side or total is dangerous (could result in loading double the intended weight).
- For weighted pull-ups, label "on belt" instead.
- Consider a "tap to expand" detail view that shows total weight on each side for verification.

---

## 6. Rest Timer UX

The PRD mentions "optional rest timer (configurable default: 2:00 for strength, 1:00 for accessories)" but does not specify the interaction design. This is a heavily-used feature that needs detailed UX work.

**Trigger behavior:**
- **Auto-start after set completion (recommended).** When the user taps to complete a set, the rest timer should begin automatically. This removes a tap and matches the natural workflow — you finish a set, you rest. The timer should be dismissible/skippable for users who don't want it.
- Manual start adds an unnecessary tap every single set. Over a 25-set workout, that's 25 extra taps.

**Display during rest:**
- **Inline with expansion (recommended over full-screen takeover).** The rest timer should expand within the current exercise card, pushing content down slightly. It should show a large countdown number (48pt+) and a circular progress ring.
- Full-screen takeover is disruptive — the user loses context of what exercise they're on and what weight they need.
- However, if the user locks their phone and returns, the timer should be the dominant visual element for immediate re-orientation.

**Completion notification:**
- **Haptic feedback is essential.** A strong haptic tap (UIImpactFeedbackGenerator equivalent — achievable via the Vibration API where supported) when the timer reaches zero. The phone may be in a pocket or on a bench.
- A brief, non-annoying audio tone as a secondary cue (optional, user-configurable).
- Visual: the timer area flashes or changes color (green pulse) to indicate "rest complete."

**Additional timer features to specify:**
- Tap timer to add 30 seconds (common need — "I'm not ready yet").
- Tap timer to skip/dismiss ("I'm ready early").
- Show elapsed time after timer completes ("You've been resting for 3:45") as a passive nudge without being aggressive.
- Timer should continue running even if the user switches to another app — use `setTimeout` with drift correction or the `Page Visibility API` to show accurate time on return.

**Per-exercise timer defaults:**
The PRD mentions 2:00 for strength and 1:00 for accessories, but Tactical Barbell programs don't typically include accessories in the strength templates. The relevant distinction is:
- Heavy sets (90%+ / low rep): 3-5 minutes rest
- Moderate sets (70-85%): 2-3 minutes rest
- The timer default should be percentage-aware, not just a global setting.

---

## 7. Accessibility

The PRD does not mention accessibility at all. For a v1 app in 2026, WCAG AA compliance should be a baseline requirement, not an afterthought.

**Dynamic Type support:**
- All text must respond to iOS Dynamic Type settings. Users who set larger text sizes must not have their content clipped or overlapping.
- The weight numbers (32px+) and plate breakdowns must scale proportionally.
- Test at the largest three Dynamic Type sizes to ensure layout doesn't break.
- Use relative units (rem) not fixed px for typography.

**VoiceOver considerations:**
- Every interactive element needs a meaningful accessibility label. "Circle 3" is not helpful — "Complete set 3 of 5, squat at 315 pounds" is.
- The plate breakdown needs a spoken equivalent: "Per side: three forty-five pound plates, one ten, one five, one two-and-a-half."
- The rest timer must announce time remaining at intervals (every 30 seconds and final 10-second countdown).
- Set completion should announce the result: "Set 3 complete. 2 sets remaining."

**Color contrast:**
- Dark mode: ensure all text meets WCAG AA contrast ratio (4.5:1 for normal text, 3:1 for large text).
- The "smaller monospace" plate breakdown text on a dark background is a risk area — light gray on dark gray often fails contrast checks.
- Accent color on dark background must also meet contrast requirements. Orange (#FF9500) on black (#000000) passes, but many oranges on dark gray do not.

**Color-blind safe palette:**
- The PRD mentions "one accent color" which is fine. But if the plate visual uses competition plate colors (red, blue, green, yellow), these must be distinguishable by color-blind users. Add text labels to all colored elements — never rely on color alone to convey information.
- Set completion (done vs. remaining) should use iconography (checkmark vs. empty circle) in addition to color change.
- Rest timer states (counting vs. complete) should differ in shape/icon, not just color.

**Motor accessibility:**
- Touch targets of 56pt+ (recommended above) also benefit users with motor impairments.
- Ensure no interaction requires a precise gesture — swipe gestures should have button alternatives.
- No time-limited interactions (the rest timer is informational, not a forced-action countdown).

**Reduced Motion:**
- Respect `prefers-reduced-motion` for all animations.
- Set completion animations and celebration screens should have static alternatives.

---

## 8. Microinteractions

The PRD mentions CSS `:active` states for tap feedback but does not specify any other microinteractions. For a workout app, microinteractions are motivational and functional.

**Set completion animation:**
- On tap: the set circle/button should fill with color, scale up briefly (105%), and show a checkmark. A subtle haptic tap accompanies this.
- The animation should feel "weighty" — not a light bounce, but a satisfying thud. Use a spring animation with moderate damping.
- Each completed set should feel like progress. The visual weight of completed sets should grow (filled circles accumulate).

**All sets complete for an exercise:**
- Brief celebration: the card gets a green border or checkmark overlay, and auto-advances to the next exercise after a 1.5-second pause.
- Do not block — the user should be able to manually advance immediately.

**Session complete celebration:**
- This deserves a dedicated moment. A full-screen "Session Complete" card with:
  - Template name + week + session number.
  - Summary of what was accomplished (e.g., "5 sets of squat at 315, 5 sets of bench at 275...").
  - An encouraging but not patronizing message. Rotate between a few: "Solid work." / "Session logged." / "Strength earned."
- Brief confetti or pulse animation (respectful of `prefers-reduced-motion`).
- Large "Done" button to return to Dashboard.

**Weight increase indicators:**
- When the user advances to a new week with higher percentages, show the weight change: "315 -> 340 (+25 lbs)" with the increase in the accent color. This is motivating and helps the user prepare mentally.
- On the Dashboard's "next session" preview, show if any weights increased from the previous session.

**Swipe gestures:**
- Horizontal swipe between exercises in Session View (as recommended in Section 4).
- Swipe down on a completed session to dismiss and return to Dashboard.
- Long-press on a set circle to undo completion (with haptic confirmation).
- Swipe gestures should have visible affordances (edge peek, dot indicators) so they're discoverable.

**Loading/calculating states:**
- When the app generates a full program schedule, show a brief loading state with the plate-loading animation (plates sliding onto a bar graphic). This turns a wait into a branded moment.

---

## 9. Missing UX Patterns

The following are standard patterns in fitness apps (Strong, Hevy, JEFIT, Caliber) that users will expect but are absent from the PRD:

**1. Weight unit toggle (lb/kg).**
The PRD assumes pounds throughout. Many Tactical Barbell users train in metric. A unit toggle in Settings is essential, and it affects plate inventory (standard metric plates: 25kg, 20kg, 15kg, 10kg, 5kg, 2.5kg, 1.25kg).

**2. Workout notes / per-set notes.**
Users need to annotate: "Left knee felt tight on set 3," "Grip failed on rep 4," "Used belt starting set 3." A small text input per exercise or per set is standard.

**3. Failed rep tracking.**
The PRD tracks sets completed and reps per set but does not address partial completion. What happens if the user attempts 5 reps but only gets 3? Can they log "3/5"? This is critical data for progression decisions.

**4. Quick weight adjustment.**
During a workout, the user may need to adjust weight on the fly (deload mid-exercise, or the plates available don't match). There should be a way to override the prescribed weight for a single session without changing the 1RM.

**5. Program progress overview.**
A visual showing where the user is in their 6-week (or 12-week) cycle: "Week 3 of 6, Session 2 of 3 this week." Progress bars or a calendar heat map. The PRD mentions "week at a glance" on the Dashboard but doesn't detail it.

**6. Data export.**
Even without cloud sync, users expect to be able to export their data (CSV, JSON) for backup or migration. The PRD lists this as out of scope, but data loss is a top concern for local-storage-only apps. At minimum, a manual export/import of the localStorage JSON should be available.

**7. Undo / mistake correction.**
What if the user accidentally marks a set complete or marks the wrong exercise? There's no undo pattern specified. A brief "Undo" toast (Snackbar pattern, 5-second window) after set completion is standard.

**8. Session abandonment.**
What happens if the user closes the app mid-workout or decides to stop early? The PRD only mentions "Mark session complete." There should be: auto-save of partial progress, a "Resume workout" prompt on next open, and an option to mark a session as "partial/incomplete" rather than only "complete."

**9. Body weight tracking.**
For weighted pull-ups, the user's body weight matters for relative strength tracking. The PRD's data model doesn't include body weight. It also affects how users interpret their pull-up numbers over time.

**10. Warm-up sets.**
The PRD only addresses working sets. Most lifters perform warm-up sets (empty bar, 50%, 70% of working weight). Either auto-generate suggested warm-up sets with plate breakdowns, or let the user toggle warm-up visibility.

---

## 10. Specific Recommendations

The following are concrete, numbered changes to the PRD:

1. **Add an "Onboarding" section (new Section 5.0).** Define a 3-4 step setup wizard for first-time users: enter lifts, choose template, preview program, start. The Dashboard should never be the first screen a new user sees.

2. **Relocate 1RM Entry from Settings to a primary position.** Either give it its own tab, make it the first item under a renamed "Lifts & Profile" tab, or make it accessible from the Dashboard with a prominent "Update Maxes" button.

3. **Add a "During Active Session" navigation specification to Section 8.** Define: tab bar behavior (hidden or locked), "Return to Workout" floating indicator on other tabs, auto-focus Session View on app foreground, and swipe-to-advance between exercises.

4. **Revise Session View information hierarchy (Section 5.4).** Reorder to: set progress (most prominent) > working weight > plate breakdown > reps target > exercise name. Specify that the current exercise is focused/expanded and other exercises are collapsed.

5. **Specify rest timer interaction design (Section 5.4).** Add: auto-start on set completion, inline countdown display with circular progress, haptic + optional audio on completion, tap-to-add-30-seconds, tap-to-skip, elapsed time after completion, percentage-aware default durations.

6. **Replace the plate breakdown text format.** Change `3x45 | 1x10 | 1x5 | 1x2.5` to either a visual plate stack with color-coded badges or a cleaner text format: `45 x3  10  5  2.5  per side`. Always label "per side" or "on belt."

7. **Add a unit system toggle to Settings (Section 5.6).** Support lb and kg. Include standard metric plate inventories as defaults when kg is selected. All weight displays and plate calculations must respect the selected unit.

8. **Add an Accessibility section (new Section 6.x).** Require: WCAG AA contrast compliance, Dynamic Type support with relative units, VoiceOver labels for all interactive elements, `prefers-reduced-motion` support, and color-blind-safe design (never use color alone to convey state).

9. **Increase session-critical touch targets to 56pt minimum.** The 44pt minimum in Section 6.3 is for general UI. Set completion buttons, rest timer controls, and exercise navigation should use 56-64pt targets for sweaty/chalked hands.

10. **Add session state persistence and recovery.** Specify auto-save of in-progress sessions to localStorage on every set completion. On next app open, detect incomplete sessions and prompt "Resume workout?" or "Discard?" This prevents data loss from accidental closure, phone death, or mid-workout app switches.

11. **Add failed rep logging to the data model.** Change `ExerciseLog.repsPerSet: number[]` to track both target and actual reps: `setsCompleted: { targetReps: number, actualReps: number, completed: boolean }[]`. This captures partial sets and failures.

12. **Add per-exercise and per-session notes.** Add an optional `notes: string` field to `ExerciseLog` and `SessionLog` in the data model. Surface this as a small text input (expandable, not always visible) in Session View.

13. **Add an undo mechanism for set completion.** After marking a set complete, show a brief (5-second) "Undo" toast/snackbar. Alternatively, support long-press to toggle a set back to incomplete.

14. **Add weight change indicators to program view and session view.** When weights increase from the previous week, display the delta (e.g., "+25 lbs") in the accent color. Show this on the Dashboard's next-session preview and at the top of each exercise card in Session View.

15. **Define the endurance session UX.** Endurance sessions need their own view: a start button, a running clock (count-up), the prescribed duration range displayed prominently, and a "Complete" button. This is a fundamentally different interaction from strength sessions.

16. **Add microinteraction specifications to Section 9.** Define: set completion animation (fill + scale + haptic), all-sets-complete transition (auto-advance with brief pause), session complete screen (summary + encouragement + "Done" CTA), and weight increase callouts.

17. **Add a data export feature to Settings.** Even for v1, provide a "Export Data" button that generates a JSON file of all user data (1RM history, session logs, settings). This is critical trust-building for a local-storage-only app — users need to know their data isn't trapped.

18. **Define empty states for all views.** Dashboard with no program, History with no sessions, Program with no 1RM data — each needs a purposeful empty state with a clear call-to-action guiding the user to the next step.

19. **Add warm-up set generation.** For each working weight, optionally display suggested warm-up sets (e.g., empty bar x 10, 50% x 5, 70% x 3) with plate breakdowns. Togglable in Settings, visible in Session View as collapsible rows above working sets.

20. **Specify the accent color as orange/amber rather than blue.** Per Section 1 analysis, warm colors maintain readability under gym fluorescent lighting better than blue, and orange is the standard high-visibility color in fitness/safety contexts.

---

## Summary

The PRD has a solid technical foundation and correctly identifies the core value proposition: replacing a spreadsheet with a purpose-built mobile experience. The template logic, plate calculator, and data model are well-specified. However, the UX layer needs significant development. The document reads as an engineering specification, not a design specification — it describes *what* the app contains but not *how* the user interacts with it under real conditions.

The three highest-priority gaps are:

1. **Session View interaction design** — this screen is 90% of the user experience and needs detailed hierarchy, navigation, timer, and gesture specifications.
2. **First-time user experience** — without an onboarding flow, the app will feel broken on first launch.
3. **Gym-environment optimization** — touch targets, information hierarchy, session persistence, and visual design must be tested against the reality of sweaty hands, glaring lights, and distracted attention.

The remaining recommendations (accessibility, microinteractions, missing patterns) elevate the app from functional to genuinely good. Tactical Barbell users are serious, committed athletes — they deserve an app that respects their time and their environment.
