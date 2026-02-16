# Accessibility Review: Tactical Barbell PWA

**Reviewer:** Senior Accessibility Specialist (WCAG 2.2 / iOS VoiceOver / Mobile A11y)
**Document reviewed:** PRD_v2.md
**Date:** 2026-02-15

---

## Executive Summary

The PRD's Section 10 establishes baseline accessibility intent (WCAG AA compliance, VoiceOver labels, color-blind safety, reduced motion). However, the section is six bullet points long for an app with seven templates, five major screens, a rest timer, and a session view that users interact with under physical exertion. This review expands accessibility from a checklist into an implementable specification.

The most critical accessibility gap: **the session view is under-specified for non-visual users.** A VoiceOver user performing a squat workout needs to complete sets, track rest, and advance exercises entirely through screen reader interaction -- potentially while sweaty, fatigued, and wearing headphones. The PRD's VoiceOver guidance ("Complete set 3 of 5, squat at 315 pounds") is a good start but does not address navigation flow, rotor actions, focus management, or the rest timer's time-based accessibility requirements.

---

## 1. WCAG 2.2 AA Compliance Audit

This section maps specific WCAG 2.2 success criteria against PRD features. Status: **Addressed** (PRD covers it), **Partial** (PRD touches it but insufficiently), or **Missing** (PRD does not address it).

### 1.1.1 Non-text Content (Level A)

| Feature | Status | Notes |
|---|---|---|
| Plate color badges (Section 5.2) | **Missing** | PRD mentions "color-coded plate badges using competition plate colors." No `alt` text or `aria-label` specification. A red badge for 25kg and a blue badge for 20kg convey weight *only* through color to sighted users. Each badge must have text content (the weight number) as its primary label, with color as supplementary. |
| Set completion circles/dots (Section 5.4) | **Partial** | PRD says "visual dots/circles" for set progress. These are non-text indicators of state (empty = pending, filled = complete). Each dot needs `aria-label="Set 1, completed"` or `aria-label="Set 3, pending"`. |
| Progress bar on dashboard (Section 5.4) | **Missing** | "Week 3 of 6" progress bar has no specified accessible name. Must use `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, and `aria-label="Program progress, week 3 of 6"`. |
| Checkmark overlay on completed exercises | **Missing** | The checkmark is purely visual. Needs `aria-label` on the exercise card indicating completion status. |
| Tab bar icons (Section 8) | **Missing** | Four tabs with icons (House, Calendar, Clock, Person). No `aria-label` specified. Each needs explicit label: "Home", "Program", "History", "Profile". |
| Circular progress ring for rest timer | **Missing** | The timer ring is a visual-only element. Needs `role="timer"` with `aria-live="assertive"` at key intervals (not every second). |
| Dot indicator for exercise navigation | **Missing** | "Dot indicator at top shows position" -- these dots must have `aria-label="Exercise 2 of 4, Bench Press"` or equivalent. |

### 1.3.1 Info and Relationships (Level A)

| Feature | Status | Notes |
|---|---|---|
| Session view card hierarchy | **Partial** | PRD specifies visual hierarchy (exercise name > set progress > weight > plates > reps > button). The semantic hierarchy must match: exercise name as heading (`h2` or `aria-level`), set/weight/plates as descriptive content within a labeled region. |
| Template progression tables (Section 5.3) | **Missing** | Week-by-week percentage tables are presented visually. If rendered as HTML tables, they need `<caption>`, `<th scope="col">`, and `<th scope="row">`. If rendered as cards, each needs proper heading structure. |
| Onboarding wizard steps | **Missing** | The 4-step wizard needs `aria-current="step"` on the active step, and a step indicator accessible as a list: "Step 2 of 4, Choose your template." |
| Form field grouping (1RM entry) | **Missing** | The 1RM form has Weight, Reps, Max Type, and Rounding per lift. These must be grouped with `<fieldset>` and `<legend>` per lift: "Squat -- enter your recent heavy set." |
| A/B split structure in Zulu | **Missing** | The tier 1/tier 2 day structure is complex. Screen readers need clear grouping: "Day A, Tier 1" as a labeled group containing the lift list. |

### 1.4.3 Contrast (Minimum) (Level AA)

| Feature | Status | Notes |
|---|---|---|
| Weight numbers (white on dark) | **Partial** | PRD specifies "bold, white on near-black." If background is #000000 or #111111, white (#FFFFFF) passes at 21:1 or 17.9:1. Verify the actual "near-black" value. |
| Muted text (exercise name, 14pt) | **Missing** | PRD says "muted" for exercise name label. "Muted" typically means reduced opacity or gray. At 14pt (18.67px), this is *not* large text under WCAG. Requires 4.5:1 minimum. If muted = #888888 on #111111, the ratio is only 4.0:1 -- **fails**. Muted text must be no darker than #999999 on #111111 (4.67:1). |
| Plate breakdown text (monospace, 14pt) | **Missing** | Same issue. 14pt monospace on dark background must meet 4.5:1. Specify the exact color. |
| Orange accent (#FF9500) on dark | **Partial** | #FF9500 on #000000 = 5.25:1 (passes AA for normal text). #FF9500 on #111111 = 4.8:1 (passes AA for normal text). But #FF9500 on #1A1A1A = 4.4:1 (**fails**). The exact background matters. If the orange accent is used on card backgrounds that are lighter than pure black, it may fail. Specify the exact card background color and verify. |
| Orange accent on white (light theme future) | **Missing** | #FF9500 on #FFFFFF = 2.94:1 (**fails** for both normal and large text). If light theme is ever implemented, the accent color must darken to approximately #C67000 (4.5:1) or use a different strategy. Note this for the theme toggle framework. |
| "Bar only" / "Not achievable" status text | **Missing** | These special case messages (Section 5.2) have no color spec. They must meet 4.5:1 on whatever background they appear. |

### 1.4.4 Resize Text (Level AA)

| Feature | Status | Notes |
|---|---|---|
| Dynamic Type support | **Partial** | PRD says "use `rem` units." This is necessary but not sufficient. iOS Dynamic Type requires `-apple-system-body` or explicit `font` shorthand referencing the system font to scale with the Accessibility > Display & Text Size > Larger Text setting. `rem` alone only responds to the root font size, which Safari PWAs do not automatically scale with Dynamic Type unless the root is set via `-webkit-text-size-adjust` or system font references. See Section 4 of this review for the full specification. |
| Weight numbers at largest sizes | **Missing** | At the largest Dynamic Type size (AX5), a 40pt weight number could become 80pt+. The three-digit weight ("315") plus "per side" plate text could overflow a single card. Layout must accommodate or cap scaling. |

### 1.4.11 Non-text Contrast (Level AA)

| Feature | Status | Notes |
|---|---|---|
| Set completion circles (unfilled state) | **Missing** | The unfilled circle border must have 3:1 contrast against the card background. If the circle is a thin (#666666) ring on #1A1A1A, the ratio is 2.4:1 (**fails**). Specify minimum border color. |
| Rest timer progress ring | **Missing** | The ring must maintain 3:1 against its background in both the "active" (filling) and "track" (unfilled) states. |
| Tab bar icons (inactive state) | **Missing** | Inactive tab icons are typically muted. They must maintain 3:1 contrast as meaningful UI components. |
| Card borders / separators | **Missing** | If exercise cards have borders or visual separation, these must meet 3:1 if they convey boundaries between distinct regions. |
| Form input borders | **Missing** | All form fields (1RM entry, settings) must have visible borders at 3:1 contrast or be clearly distinguishable from their surroundings. |

### 2.1.1 Keyboard (Level A)

| Feature | Status | Notes |
|---|---|---|
| External keyboard support | **Missing** | iOS supports Bluetooth keyboards. All interactive elements must be reachable via Tab key. The PRD does not mention keyboard navigation at all. While rare in a gym, some users with motor impairments use keyboards with iPad (which could run this PWA). |
| Session view keyboard shortcuts | **Missing** | Consider: Space/Enter to complete set, Escape to undo, arrow keys to navigate exercises. Not required for AA, but strongly recommended for motor accessibility. |

### 2.4.3 Focus Order (Level A)

| Feature | Status | Notes |
|---|---|---|
| Onboarding wizard | **Missing** | When moving between steps, focus must shift to the new step's first interactive element or heading. If the user presses "Next," focus should land on Step 2's heading, not remain on the (now invisible) "Next" button from Step 1. |
| Session view exercise navigation | **Missing** | When auto-advancing to the next exercise (1.5s delay), focus must move to the new exercise's content, not stay on the now-completed exercise. VoiceOver users would be stranded. |
| Modal dialogs (program switch confirmation) | **Missing** | Confirmation dialogs ("Starting a new program will end your current cycle...") must trap focus within the dialog and return focus to the trigger element on dismissal. |
| Rest timer appearance | **Missing** | When the rest timer appears inline within the exercise card, focus should not jump to it automatically (this would be disorienting). Instead, announce the timer start via `aria-live` and let the user navigate to it voluntarily. |
| Undo toast | **Missing** | The 5-second undo toast must be focusable and announced, but must not steal focus from the next action. Use `role="alert"` with `aria-live="assertive"`. |

### 2.4.7 Focus Visible (Level AA)

| Feature | Status | Notes |
|---|---|---|
| All interactive elements | **Missing** | PRD specifies `-webkit-tap-highlight-color: transparent`, which removes the default tap indicator. A custom focus indicator must replace it. For VoiceOver, the system focus ring handles this. For keyboard users, a visible outline (minimum 2px, contrasting color) must appear on `:focus-visible`. Do not apply `:focus { outline: none }` without a replacement. |

### 2.5.5 Target Size (Level AAA) / 2.5.8 Target Size Minimum (Level AA)

| Feature | Status | Notes |
|---|---|---|
| Session-critical targets (56pt) | **Addressed** | 56pt = 74.67px, well above the 44px AA minimum (2.5.8) and the 24px minimum spacing requirement. |
| All other targets (44pt) | **Addressed** | 44pt = 58.67px, exceeds both AA (24x24px) and AAA (44x44px) minimums. |
| Plate inventory stepper controls | **Missing** | Settings allows editing plate quantities (min 0, max 20). If using +/- stepper buttons, each must meet the 44pt minimum. Small steppers are a common failure point. |
| Rep adjustment tap target | **Missing** | "Tap the rep count to adjust actual reps" -- the rep count number may be small (14-16pt text). The tappable area around it must be at least 44pt even if the visible text is smaller. |
| Weight override tap target | **Missing** | Same issue. "Tap the weight number to override" -- ensure the hit area is 44pt minimum, not just the visible text bounds. |

### 3.2.2 On Input (Level A)

| Feature | Status | Notes |
|---|---|---|
| Template selection auto-advancing | **Partial** | If selecting a template in Step 2 auto-advances to Step 3, this violates 3.2.2 (context change on input without prior notice). The user must explicitly confirm their selection via a "Next" or "Continue" button. |
| Theme toggle | **Missing** | Changing theme (Dark/Light/System) causes an immediate visual context change. This is acceptable as long as it does not relocate focus or alter page structure unexpectedly. |
| 1RM recalculation on input | **Missing** | If the percentage table updates live as the user types Weight/Reps, this is fine (no context change, just content update). But if it navigates away or opens a new view, that would violate 3.2.2. Clarify that recalculation is inline. |

### 4.1.2 Name, Role, Value (Level A)

| Feature | Status | Notes |
|---|---|---|
| Set completion button | **Partial** | PRD gives example label: "Complete set 3 of 5, squat at 315 pounds." This is good. Must update dynamically as sets are completed. After completion, the button should become disabled or change to "Set 3 completed" with `aria-disabled="true"` or be removed from tab order. |
| Rest timer controls | **Missing** | "Tap timer to add 30 seconds" -- this needs `aria-label="Add 30 seconds to rest timer"` and `role="button"`. "Skip" needs `aria-label="Skip rest timer"`. The timer display needs `role="timer"`. |
| Exercise pager (swipe navigation) | **Missing** | The swipe-to-navigate exercise pattern must be implemented with proper semantics: either `role="tablist"` with `role="tab"` per exercise, or a `role="region"` with `aria-label` and explicit prev/next buttons as alternatives. |
| Max Type toggle | **Missing** | "True Max" / "Training Max" toggle needs `role="radiogroup"` or `role="switch"` with clear `aria-checked` state. |
| Rounding Increment selector | **Missing** | 2.5 / 5 selector needs appropriate role (`radiogroup` or `listbox`) with `aria-selected` state. |
| Progress dots for exercises | **Missing** | Dot indicators must not be `role="presentation"`. Use `role="tablist"` with `role="tab"` per dot, or `role="status"` with text alternative. |

### WCAG 2.2.1 Timing Adjustable (Level A)

| Feature | Status | Notes |
|---|---|---|
| Rest timer | **Missing** | The rest timer is a time-based UI element. While it does not prevent the user from acting (they can complete the next set whenever they want), the auto-start behavior and the "elapsed time nudge" after zero could create confusion for users who cannot see the countdown. See Section 9 of this review for full timer accessibility specification. |
| Undo toast (5-second timeout) | **Missing** | The 5-second undo window is a timing constraint. Users with motor impairments may not be able to reach and activate the undo button within 5 seconds. WCAG 2.2.1 requires that time limits be adjustable, extendable (by at least 10x), or avoidable. Recommendation: extend to 10 seconds, or keep the undo available until the next set is completed (whichever comes first). |
| Auto-advance after exercise completion (1.5s) | **Missing** | The 1.5-second auto-advance delay is short. The PRD says "skippable," which satisfies 2.2.1 if the user can prevent or extend it. But a VoiceOver user may not even hear the announcement that auto-advance is happening before it fires. Recommendation: do not auto-advance when VoiceOver is active. Instead, announce "All sets complete. Swipe right for next exercise" and wait for user action. |

---

## 2. VoiceOver Interaction Patterns

This section specifies how VoiceOver should behave on each major screen. Announcement text uses the format: **"[Spoken label], [role], [state/value]"**.

### 2.1 Onboarding

**Step 1 -- Enter Your Lifts:**

When the screen loads, VoiceOver focus lands on the heading.

- Heading: "Step 1 of 4, Enter Your Lifts, heading level 1"
- Instruction text: "Enter a recent heavy set. We'll calculate your max."
- Per-lift fieldset: "Squat, group." Contains:
  - Weight field: "Weight, pounds, text field. Required." (`inputmode="decimal"`)
  - Reps field: "Reps, text field. Required." (`inputmode="numeric"`)
- Skip button: "Skip Squat, button" (for lifts the user does not train)
- Continue: "Continue to Choose Your Template, button"

**Step 2 -- Choose Your Template:**

- Heading: "Step 2 of 4, Choose Your Template, heading level 1"
- Each template card: "Operator, Balanced strength plus endurance, 3 strength days, 3 cardio days per week, 6 week cycle, button" (acts as a selectable card, `role="radio"` within a `role="radiogroup"`)
- Selected state: "Operator, selected" (`aria-checked="true"`)
- Continue: "Continue to Preview Your First Week, button"

**Step 3 -- Preview Your First Week:**

- Heading: "Step 3 of 4, Your First Week, heading level 1"
- Each session card: "Session 1, Strength. Squat 260 pounds, per side: two 45-pound plates, one 10, one 5. Bench 185 pounds, per side: one 45-pound plate, one 25. Weighted Pull-up 45 pounds, on belt: one 45-pound plate."
- Continue: "Start Training, button"

**Step 4 -- Start Training:**

- Date picker: "Start date, today, date picker"
- CTA: "Begin Program, button"

**Focus management:** When the user taps Continue, focus moves to the next step's heading. When going back, focus moves to the previous step's heading.

### 2.2 Dashboard (Home)

VoiceOver reads top-to-bottom in DOM order:

1. "Tactical Barbell, heading level 1"
2. "Operator, Week 3 of 6, program progress 50 percent, heading level 2" (the progress bar is announced as a value, not as a separate element)
3. "Next Session, heading level 2. Session 5, Strength. Squat at 295 pounds. Bench at 205 pounds. Deadlift at 340 pounds."
4. "Start Session, button" (the 64pt quick-start button)
5. "Update Maxes, button"

**If a workout is in progress:** Before all other content, announce: "Workout in progress, Operator Week 3 Session 5. Return to Workout, button" with `role="alert"` on first appearance.

### 2.3 Session View (Active Workout) -- CRITICAL SCREEN

This is the screen where accessibility has the highest stakes. A VoiceOver user is performing a physical workout and needs efficient, low-friction access to essential information.

**Initial load announcement (via `aria-live="polite"` region):**
"Workout started. Squat, Set 1 of 5, 295 pounds. 5 reps."

**Exercise card structure:**

Each exercise card should be a `role="region"` with `aria-label="Squat"`:

1. Exercise name: "Squat, heading level 2"
2. Set progress: "Set 3 of 5" (text content, not requiring separate navigation)
3. Working weight: "295 pounds"
4. Plate breakdown: "Per side: two 45-pound plates, one 25, one 5, one 2.5"
5. Reps: "5 reps"
6. **Complete Set button:** "Complete set 3 of 5, Squat at 295 pounds, button"

**After completing a set:**
- Haptic fires (felt, not heard)
- VoiceOver announces: "Set 3 complete. Rest timer started, 2 minutes. Set 4 of 5 ready."
- Undo toast appears: VoiceOver announces "Undo last set, button. Available for 10 seconds." via `role="alert"`
- Focus remains on the Complete Set button (now labeled "Complete set 4 of 5")

**After completing all sets for an exercise:**
- VoiceOver announces: "Squat complete, all 5 sets done. Next exercise: Bench Press."
- If VoiceOver is active: **do not auto-advance.** Wait for user swipe or button tap.
- Provide "Next Exercise, button" as a focusable action.

**Exercise navigation for VoiceOver:**
- The swipe-between-exercises pager pattern is inaccessible to VoiceOver by default (VoiceOver swipe is consumed for element navigation)
- Provide explicit "Previous Exercise" and "Next Exercise" buttons, visible in the DOM but potentially visually positioned as arrow icons at card edges
- These buttons: "Previous exercise, Squat, button" / "Next exercise, Deadlift, button"
- Set `aria-roledescription="exercise pager"` on the container for orientation

**VoiceOver Rotor Actions:**

Custom rotor actions for the session view (via `accessibilityCustomActions` equivalent in web -- use `aria-roledescription` and custom labels on the exercise region):

- Rotor "Actions" on the exercise region:
  - "Complete current set" -- triggers set completion
  - "Skip rest timer" -- dismisses timer if active
  - "Override weight" -- opens weight input
  - "End workout" -- navigates to confirmation

In web, custom rotor actions are not natively available. Instead, provide a visually hidden "Session Actions" menu (`role="menu"`) accessible via a button, containing these actions. This gives VoiceOver users single-point access to all workout controls.

**Rest timer VoiceOver interaction:**
- On timer start: announce "Rest timer, 2 minutes" (once, not repeatedly)
- At 30-second mark: announce "30 seconds remaining" via `aria-live="assertive"`
- At zero: announce "Rest complete" via `aria-live="assertive"` + haptic
- "Add 30 seconds, button" and "Skip timer, button" remain focusable
- Do NOT announce every second. This would make VoiceOver unusable.

**Weight override flow:**
- User taps weight (or activates via VoiceOver): "Weight override for Squat, current 295 pounds, text field"
- On confirmation: "Weight updated to 285 pounds for this session"

**Rep adjustment flow:**
- User taps rep count: "Actual reps for set 3, current target 5, text field"
- On confirmation: "Set 3 logged as 3 reps out of 5 target"

### 2.4 History

**1RM Test History:**
- Heading: "1RM Test History, heading level 1"
- Filter/sort: "Filter by lift, popup button, All lifts"
- Each entry: "February 10, 2026. Squat, 365 pounds times 4 reps, calculated 1RM 414 pounds, Training Max 372 pounds."
- Use `role="list"` with `role="listitem"` for entries

**Completed Sessions:**
- Each entry: "February 12, 2026. Operator Week 3 Session 5, Completed. Squat 5 of 5 sets, Bench 5 of 5 sets, Deadlift 4 of 5 sets."
- Status announced as part of the entry, not as a separate color indicator

### 2.5 Profile & Settings

- Heading: "Profile, heading level 1"
- 1RM section: "Your Maxes, heading level 2. Squat, 1RM 414 pounds, Training Max 372 pounds. Tap to update."
- Each setting: standard form control announcements
  - "Max Type, switch button, Training Max, on" (if using toggle)
  - "Rounding Increment, 2.5 pounds, radio button, 1 of 2, selected"
  - "Barbell Weight, 45 pounds, adjustable"
  - "Rest Timer Default, 120 seconds, adjustable"
  - "Theme, Dark, popup button"
- Export: "Export Data, button"
- Import: "Import Data, button"
- Last backup: "Last backup: February 8, 2026"
- Data warning: read as static text, `role="note"`

---

## 3. Haptic and Non-Visual Feedback

The PRD mentions haptic feedback for set completion and timer completion. This section expands to a full non-visual feedback specification.

### 3.1 Haptic Patterns

iOS Safari supports the Vibration API with limited patterns. Use distinct patterns for distinct events so users can differentiate by feel:

| Event | Haptic Pattern | Rationale |
|---|---|---|
| Set completion (success) | Single short pulse (50ms) | Clean, satisfying confirmation. Matches iOS "notification" tap. |
| All sets complete for exercise | Double pulse (50ms-pause-50ms) | Distinct from single set -- signals a larger milestone. |
| Rest timer complete | Triple pulse (50ms-pause-50ms-pause-50ms) | Signals "time to act." Must be distinct from set completion to avoid confusion. |
| Undo action | Single long pulse (150ms) | Feels like "pulling back." Different texture from completion. |
| Session complete (all exercises done) | Long-short-long (150ms-pause-50ms-pause-150ms) | Celebration pattern. Distinct from all others. |
| Error / invalid action | Two rapid short pulses (30ms-pause-30ms) | Abrupt, distinct from success patterns. |
| Timer +30 seconds | Single light pulse (30ms) | Acknowledgment without suggesting completion. |

**Important:** The Vibration API (`navigator.vibrate()`) has limited support in iOS Safari. Test on target iOS versions. If unavailable, the app must not rely on haptic as the sole feedback -- all haptic events must pair with a visual and/or audio indicator.

### 3.2 Audio Feedback

The PRD mentions "optional audio tone" for timer completion. Expand to cover all significant events:

| Event | Sound | Setting |
|---|---|---|
| Set completion | Short click/tap sound (50ms) | On by default; togglable in settings |
| Rest timer complete | Ascending chime (300ms, medium volume) | On by default; togglable in settings |
| Session complete | Completion fanfare (500ms) | On by default; togglable in settings |
| Error / invalid | Low buzz (100ms) | On by default; togglable in settings |

**Gym context:** Users often wear headphones (noise-canceling or earbuds). Audio feedback is critical for these users because:
1. They cannot see their phone (it is in a pocket or on a bench)
2. They cannot feel haptic through gym gloves (thick padding absorbs vibration)
3. They need to know when rest is over without watching the screen

**Audio implementation:** Use Web Audio API (not `<audio>` elements) for low-latency playback. Pre-load audio buffers during app initialization. Total audio asset size should be under 20KB (procedurally generated tones are preferred over audio files to stay within the 50KB bundle target).

**Settings:** Add a "Sound" toggle to Settings (separate from haptic). Options: On / Off / Vibrate Only. Default: On.

### 3.3 Combined Feedback Matrix

For each event, the user should receive feedback through multiple channels:

| Event | Visual | Haptic | Audio | VoiceOver |
|---|---|---|---|---|
| Set complete | Circle fills + scale animation | Single pulse | Click | "Set N complete" |
| Exercise complete | Checkmark overlay | Double pulse | -- | "Exercise complete, next: [name]" |
| Rest timer start | Timer appears, countdown begins | -- | -- | "Rest timer, N minutes" |
| Rest timer -30s | Visual countdown | -- | -- | "30 seconds remaining" |
| Rest timer complete | Timer shows "0:00", elapsed counter starts | Triple pulse | Chime | "Rest complete" |
| Session complete | Full-screen summary | Long-short-long | Fanfare | "Workout complete. Summary..." |
| Undo | Toast appears | Long pulse | -- | "Set N undone" |
| Error | Red flash / shake | Double rapid | Buzz | Error description |

---

## 4. Dynamic Type Deep Dive

### 4.1 Why `rem` Units Are Insufficient

The PRD states: "Use `rem` units." On iOS Safari, `rem` is relative to the root element's font size, which defaults to 16px. However, iOS Dynamic Type settings (Settings > Accessibility > Display & Text Size > Larger Text) do not automatically scale the root `font-size` in Safari or Safari PWAs.

To properly support Dynamic Type in a PWA, the app must:

1. **Use the system font stack** (`-apple-system`, which the PRD already specifies) -- this allows the system to apply Dynamic Type metrics.
2. **Set the root font size responsively** using a CSS media query or JavaScript detection. Safari does not expose a CSS media feature for Dynamic Type, so the most reliable approach is:

```css
/* Base size */
:root {
  font-size: 16px;
}

/* Respond to iOS text size preference via JavaScript */
/* On load, read the computed font-size of a hidden element using -apple-system-body
   and set --dynamic-type-scale accordingly */
```

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
  // Default body text is 17px at standard size
  return computedSize / 17;
}

// Apply scale to root
const scale = getDynamicTypeScale();
document.documentElement.style.setProperty('--dt-scale', scale);
```

Then use `calc()` with `--dt-scale`:
```css
.weight-number {
  font-size: calc(40px * var(--dt-scale));
}
```

### 4.2 Text Size Specifications

For each element type, specify the base size, the minimum (never shrink below this), and the maximum (cap scaling to prevent layout breakage):

| Element | Base Size (1x) | Min Size | Max Size (AX5) | Notes |
|---|---|---|---|---|
| Weight number (session) | 40px | 32px | 72px | Cap at 72px to prevent card overflow |
| Set progress ("SET 3 / 5") | 24px | 20px | 44px | Must remain single-line |
| Exercise name | 14px | 14px | 24px | Uppercase label; cap to prevent wrapping |
| Plate breakdown | 14px | 14px | 24px | Monospace; may wrap to second line at large sizes |
| Rep target | 16px | 14px | 28px | |
| Rest timer countdown | 48px | 40px | 80px | |
| Dashboard heading | 20px | 18px | 36px | |
| Body text (descriptions) | 16px | 16px | 28px | |
| Button text | 18px | 16px | 32px | Button height must grow proportionally |
| Tab bar labels | 10px | 10px | 14px | Tab bar height grows; cap label to prevent overflow |
| Form labels | 14px | 14px | 24px | |
| Form input text | 16px | 16px | 28px | Input height must grow proportionally |

### 4.3 Layout Behavior at Large Text Sizes

**Standard Dynamic Type (up to xxxLarge, ~1.35x):**
- No layout changes needed. All elements scale proportionally.
- Test that plate breakdown text wraps gracefully (not clipped).

**Accessibility sizes (AX1 through AX5, 1.5x to 3.1x):**

At AX3 and above (approximately 2x scale):

1. **Session view:** Switch from horizontal exercise pager to a vertical scrollable list. The swipe-between-exercises pattern breaks when cards are taller than the viewport. Each exercise becomes a collapsible section: current exercise is expanded, others show only name + completion status.

2. **Dashboard:** The "next session preview" collapses from showing all exercises to showing only the first exercise with a "and N more" summary.

3. **Template selection (onboarding):** Cards switch from side-by-side (if any) to single-column stacked layout.

4. **Plate breakdown:** If the plate string exceeds one line, wrap to a second line. Never truncate with ellipsis -- the user needs the full plate information.

5. **Tab bar:** Icon size grows proportionally. Labels may be hidden at the largest sizes (icon-only tabs), but the `aria-label` persists.

6. **Buttons:** Height grows proportionally with text. The 56pt minimum for session-critical buttons should be treated as a minimum -- at AX5, they may become 80pt+, which is acceptable.

### 4.4 Testing Requirements

Test the app at these specific Dynamic Type sizes:
- Default (1x) -- baseline
- Large (1.12x) -- the most common non-default size
- xxxLarge (1.35x) -- the largest "standard" size
- AX1 (1.5x) -- first accessibility size
- AX3 (2.0x) -- layout breakpoint trigger
- AX5 (3.1x) -- extreme; layout must not crash, though degraded UX is acceptable

---

## 5. Motor Accessibility in Gym Context

### 5.1 Touch Target Adequacy

The PRD specifies 56pt for session-critical actions and 44pt for all others. This exceeds WCAG 2.5.8 (24px minimum) and matches the Apple HIG's recommended minimum for accessibility. However, the gym context introduces additional factors:

**Sweaty/gloved hands:** Users wearing lifting gloves have reduced finger precision. The 56pt targets are adequate for gloved use, but the *spacing* between targets matters as much as size. If two 56pt buttons are adjacent with minimal padding, a gloved tap near the boundary could hit the wrong one. Recommendation: **minimum 8pt spacing** between all adjacent interactive elements in the session view.

**Fatigue tremor:** After heavy sets, hands may shake. This makes precise tapping harder. The 56pt target with 8pt spacing handles this. No additional changes needed.

### 5.2 Switch Control Compatibility

iOS Switch Control allows users to navigate and interact using external switches (physical buttons, head movements, or other adaptive inputs). Switch Control works by scanning through focusable elements.

Requirements:
1. **All interactive elements must be focusable** -- no `tabindex="-1"` on session controls.
2. **Scan order must be logical:** Within the session view, scan order should be: exercise name (info) > set progress (info) > weight (info/action) > plate breakdown (info) > complete set button (action) > next exercise button (action).
3. **No gesture-only interactions:** Every swipe action must have a button alternative. The PRD says "All swipe gestures have button alternatives" (Section 10). Verify this covers:
   - Exercise navigation (swipe left/right) -- needs prev/next buttons
   - Dismiss undo toast (swipe away) -- needs close button or timeout
   - Pull-to-refresh (if any) -- needs refresh button
4. **Group scanning:** Use `role="group"` on exercise cards so Switch Control can scan by card (point mode) rather than by individual element (auto mode). This reduces the number of switch presses needed.

### 5.3 AssistiveTouch Compatibility

AssistiveTouch provides an on-screen menu for users who cannot perform standard gestures. It replaces multi-finger gestures and hard-to-reach buttons with a floating menu.

Requirements:
1. **No multi-touch gestures required.** The PRD does not specify any pinch, rotate, or multi-finger gestures. Confirm this remains true.
2. **No long-press for primary actions.** Long-press is difficult for users with tremor. If any feature uses long-press (e.g., long-press weight to override), provide a tap alternative.
3. **Reachable menu button:** The "End Workout" button is in the top-right (Section 5.4). For AssistiveTouch users, the top-right may be occluded by the floating menu button. Ensure "End Workout" is also accessible via a slide-down panel or bottom-sheet menu.

### 5.4 Gesture-Only Interactions Audit

Review all interactions in the PRD and confirm button alternatives exist:

| Gesture | Location | Button Alternative Needed | Status |
|---|---|---|---|
| Horizontal swipe between exercises | Session view | Prev/Next buttons | **Missing from PRD** |
| Swipe to dismiss undo toast | Session view | Timeout (auto-dismiss) or X button | **Missing from PRD** |
| Tap timer to add 30s | Session view | Explicit "+30s" button with label | **Partial** -- PRD says "tap timer" but does not specify an explicit labeled button |
| Tap weight to override | Session view | Explicit "Edit weight" button or accessible action | **Missing from PRD** |
| Tap rep count to adjust | Session view | Explicit "Edit reps" button or accessible action | **Missing from PRD** |
| Swipe between history entries | History view | Scroll (not gesture-dependent) | Acceptable if standard scroll |

### 5.5 One-Switch Users

For users who operate with a single switch (one button, such as a head switch):
- Scanning through the entire session view is tedious. Minimize the number of focusable elements per exercise card. The "Complete Set" button should be the **first** item in scan order within each card group, since it is the most frequently needed action.
- Consider: reorder the DOM so the Complete Set button comes first (visually position it at the bottom with CSS `order` or absolute positioning). This puts the primary action first in the scan cycle.

---

## 6. Cognitive Accessibility

### 6.1 Information Overload Assessment

The session view shows per exercise: exercise name, set progress, working weight, plate breakdown (multiple plate sizes with counts), rep target, and a complete button. Across a session with 3 exercises at 5 sets each, the user processes:

- 3 exercise names
- 15 set states
- 3 working weights
- 3 plate breakdowns (each with 3-5 plate entries)
- 3 rep targets
- 15 completion actions

This is manageable for neurotypical users because only one exercise is visible at a time (pager pattern). However, for users with cognitive disabilities (intellectual disabilities, brain injury, ADHD, anxiety), even the single-exercise card may present too much information simultaneously.

### 6.2 Simplified View Recommendation

Add an optional **"Simple Mode"** (togglable in Settings) that reduces the session view to:

**Simple Mode exercise card:**
1. Exercise name (large, 20pt)
2. Weight (very large, 48pt)
3. "Tap when done" button (full-width, 64pt)
4. Set counter: "3 done, 2 left" (plain language, not "SET 3 / 5")

**What Simple Mode removes:**
- Plate breakdown (user can access via a "Show plates" expandable)
- Percentage information
- Rep target (assumes user knows their reps from muscle memory)
- Auto-advance (user manually taps "Next exercise")

**What Simple Mode changes:**
- Plain language instead of abbreviations ("2 more sets" instead of "SET 3 / 5")
- Larger text sizes (base 20px instead of 16px)
- Fewer elements on screen simultaneously
- Reduced animation (auto-applies `prefers-reduced-motion` behavior)

### 6.3 Number Presentation

The app is heavily number-driven: percentages, weights, plate counts, sets, reps, timer seconds. For users with dyscalculia or cognitive load sensitivity:

1. **Minimize simultaneous numbers:** On the session view, the essential numbers are: weight and set count. Plate breakdown is important but secondary. Percentage is rarely needed during execution (it is a planning number, not an execution number). Do not show percentage on the session view.

2. **Use consistent formatting:** Always "315 lb" (never "315" alone, never "315lbs", never "315 pounds" in some places and "315 lb" in others). Pick one format and use it everywhere.

3. **Group related numbers:** "295 lb -- 2x45, 1x25, 1x5 per side" is easier to parse than stacking these on separate lines with different visual styles.

4. **Avoid percentage on session screen:** The session view should show the *weight*, not "80% of 372." The user does not need to compute anything. The weight is the actionable number.

### 6.4 Template Selection Complexity

The 7 templates have varying durations (3, 6, 12 weeks), session counts (2-6/week), and structures (A/B splits, tiered percentages). For users with cognitive disabilities:

1. **Add a recommendation flow:** "How many days per week can you lift?" -> filter templates. "2 days" -> Fighter. "3 days" -> Operator, Gladiator, Mass Protocol, Grey Man. "4 days" -> Zulu.

2. **Use plain language descriptions:** Current descriptions use fitness jargon ("hypertrophy focus," "progressive intensification"). Add a plain-language alternative: "Lift 3 days a week. Get stronger over 6 weeks."

3. **Highlight the default choice:** For new users, recommend Operator as the starting template with "Recommended for most users" badge. Reduce decision paralysis.

### 6.5 Error Recovery

For users with cognitive disabilities, error states must be:
1. **Written in plain language:** "The weight you entered is too high for your plates" instead of "Not achievable with current plate inventory."
2. **Actionable:** Every error message must include what to do next. "Try a lower weight" or "Tap here to change your plates."
3. **Non-punishing:** Never lose user data on error. If they enter an invalid weight, preserve what they typed and highlight the issue. Never clear the field.

---

## 7. Color and Visual Design

### 7.1 Specified Colors and Contrast Ratios

Based on PRD Section 9 (dark mode default, orange accent, white text):

Assumed palette (derived from PRD specifications):

| Element | Foreground | Background | Ratio | WCAG AA |
|---|---|---|---|---|
| Weight numbers | #FFFFFF | #000000 | 21:1 | Pass |
| Weight numbers | #FFFFFF | #111111 | 17.9:1 | Pass |
| Weight numbers | #FFFFFF | #1A1A1A | 15.4:1 | Pass |
| Exercise name (muted) | #999999 | #111111 | 4.67:1 | Pass (normal text) |
| Exercise name (muted) | #888888 | #111111 | 4.0:1 | **Fail** (normal text) |
| Orange accent text | #FF9500 | #000000 | 5.25:1 | Pass |
| Orange accent text | #FF9500 | #1A1A1A | 4.4:1 | **Fail** (if < 18pt) |
| Orange accent text | #FF9500 | #111111 | 4.8:1 | Pass |
| Plate badge text | #FFFFFF | #C62828 (red plate) | 5.6:1 | Pass |
| Plate badge text | #FFFFFF | #1565C0 (blue plate) | 5.5:1 | Pass |
| Tab bar inactive icon | #666666 | #111111 | 2.7:1 | **Fail** (3:1 needed for non-text) |

**Required fixes:**
1. Muted text must use #999999 minimum on #111111 backgrounds, or #8E8E8E minimum on #000000 (4.5:1 threshold).
2. Orange accent (#FF9500) must only be used on backgrounds no lighter than #111111 for normal-sized text. On card backgrounds, verify the exact hex. For large text (18pt+/24px+ or 14pt+/18.67px+ bold), 3:1 is sufficient and #FF9500 passes on all dark backgrounds.
3. Inactive tab icons must use #888888 minimum on #111111 (4.0:1 -- passes non-text 3:1 requirement). Note: 3:1 applies to non-text contrast (1.4.11), not 4.5:1.

### 7.2 Competition Plate Color-Coding vs Color Vision Deficiency

The PRD mentions "color-coded plate badges using competition plate colors." Standard competition plate colors:

| Weight | Color | Hex (approx) |
|---|---|---|
| 45 lb (20 kg) | Red | #C62828 |
| 35 lb (15 kg) | Yellow | #F9A825 |
| 25 lb (10 kg) | Green | #2E7D32 |
| 10 lb (5 kg) | White/Silver | #E0E0E0 |
| 5 lb (2.5 kg) | Red/Small | #C62828 |
| 2.5 lb (1.25 kg) | Green/Small | #2E7D32 |
| 1.25 lb | Silver/Small | #9E9E9E |

**Color vision deficiency analysis:**

| Condition | Confusable Pairs | Impact |
|---|---|---|
| Protanopia (no red) | Red(45) and Green(25) appear similar (both olive/brown) | High -- 45 and 25 are the most common plates |
| Deuteranopia (no green) | Red(45) and Green(25) appear similar (both yellow-brown) | High -- same issue |
| Tritanopia (no blue) | Yellow(35) and Green(25) appear similar (both pale green) | Medium |

**This is a critical failure.** If plate colors are the primary visual differentiator, protanopic and deuteranopic users cannot distinguish between 45 lb and 25 lb plates -- the two most commonly used plates.

**Required fix:** Plate badges must **always** show the weight number as primary content, with color as supplementary decoration. The PRD's preferred rendering (`45 x3  10  5  2.5  per side`) already handles this correctly by using numbers. If color badges are used as an alternative visual style, they must include the weight number inside each badge in high-contrast text.

Additionally, consider adding a distinct shape or pattern per plate weight for users who have difficulty with both color and small numbers:
- 45 lb: Circle (or square with rounded corners)
- 35 lb: Pentagon
- 25 lb: Hexagon
- 10 lb and below: Circle (differentiated by size)

This is not required for WCAG AA but significantly improves usability for color-deficient users.

### 7.3 State Communication Without Color

The PRD states: "Never convey state by color alone." Verify for each stateful element:

| Element | States | Color Indicator | Non-Color Indicator | Status |
|---|---|---|---|---|
| Set completion circle | Pending / Complete | Empty / Filled (accent color) | Empty / Checkmark icon | **Partial** -- PRD mentions checkmark for exercise completion but not individual set completion. Each completed set circle should contain a checkmark or fill pattern, not just a color fill. |
| Rest timer | Active / Expired / Elapsed | Accent / Green / Red? | Countdown number / "0:00" / Elapsed counter text | **Partial** -- states are distinguishable by text content, but verify no color-only transitions. |
| Session status (history) | Completed / Partial / Skipped | Green / Yellow / Gray? | Status text: "Completed" / "Partial" / "Skipped" | **OK** if text labels are always shown. Do not use colored dots without text. |
| Exercise card | Active / Complete / Upcoming | Highlighted / Green checkmark / Dimmed | Expanded (active) / Checkmark overlay (complete) / Collapsed (upcoming) | **OK** -- structural difference. |
| Tab bar tab | Active / Inactive | Accent / Muted | Filled icon (active) / Outlined icon (inactive) | **Partial** -- specify icon variant change, not just color change. |

### 7.4 Minimum Contrast Specification Per UI Element Category

| Category | Min Contrast | Standard | Notes |
|---|---|---|---|
| Body text (< 18pt) | 4.5:1 | WCAG 1.4.3 AA | All descriptions, labels, plate text |
| Large text (>= 18pt or >= 14pt bold) | 3:1 | WCAG 1.4.3 AA | Weight numbers, headings, buttons |
| UI components (icons, borders, controls) | 3:1 | WCAG 1.4.11 AA | Tab icons, set circles, progress rings, form borders |
| Disabled elements | No minimum | WCAG exception | But should still be perceivable as present; 2:1 recommended |
| Placeholder text | 4.5:1 | Treat as text | Form input placeholders must meet contrast |
| Focus indicators | 3:1 | WCAG 2.4.7 AA | Custom focus ring against both the background and the element |

---

## 8. Form Accessibility

### 8.1 1RM Entry Form (Section 5.1 and Onboarding Step 1)

**Field specifications:**

```html
<fieldset>
  <legend>Squat -- Enter a recent heavy set</legend>

  <label for="squat-weight">Weight (lb)</label>
  <input id="squat-weight"
         type="text"
         inputmode="decimal"
         pattern="[0-9]*\.?[0-9]*"
         aria-required="true"
         aria-describedby="squat-weight-help squat-weight-error"
         autocomplete="off" />
  <span id="squat-weight-help">Enter weight in pounds (1-1500)</span>
  <span id="squat-weight-error" role="alert" aria-live="polite"></span>

  <label for="squat-reps">Reps</label>
  <input id="squat-reps"
         type="text"
         inputmode="numeric"
         pattern="[0-9]*"
         aria-required="true"
         aria-describedby="squat-reps-help squat-reps-error"
         autocomplete="off" />
  <span id="squat-reps-help">Whole number, 1-15</span>
  <span id="squat-reps-error" role="alert" aria-live="polite"></span>
</fieldset>
```

**Error messaging requirements:**
1. Errors appear inline below the field, not in a toast or modal
2. Error text uses `role="alert"` and `aria-live="polite"` (not "assertive" -- polite is sufficient for form validation and prevents interrupting the user)
3. The input itself gets `aria-invalid="true"` when in error state
4. Error messages are specific: "Weight must be between 1 and 1500 pounds" not "Invalid input"
5. On form submission with errors, focus moves to the first field with an error

**Input type considerations:**
- Use `type="text"` with `inputmode="decimal"` for weight (allows decimal input without browser-imposed constraints)
- Use `type="text"` with `inputmode="numeric"` for reps (integer only)
- Do NOT use `type="number"` -- it has inconsistent behavior across iOS versions and VoiceOver announces it as "incrementable" which is confusing for direct text entry

**Max Type toggle:**
```html
<fieldset>
  <legend>Max Type</legend>
  <label>
    <input type="radio" name="max-type" value="training" checked
           aria-describedby="training-max-desc" />
    Training Max (recommended)
  </label>
  <span id="training-max-desc">90% of calculated 1RM. Standard Tactical Barbell convention.</span>
  <label>
    <input type="radio" name="max-type" value="true"
           aria-describedby="true-max-desc" />
    True Max
  </label>
  <span id="true-max-desc">Full calculated 1RM used for all percentages.</span>
</fieldset>
```

### 8.2 Settings Forms

**Plate Inventory Editor:**

Each plate size row must be a labeled group:

```html
<div role="group" aria-label="45-pound plates, per side">
  <label for="plate-45-qty">45 lb quantity</label>
  <button aria-label="Decrease 45-pound plate count">-</button>
  <input id="plate-45-qty" type="text" inputmode="numeric"
         value="4" min="0" max="20"
         aria-valuenow="4" aria-valuemin="0" aria-valuemax="20" />
  <button aria-label="Increase 45-pound plate count">+</button>
</div>
```

- The +/- buttons must be 44pt minimum (they are not session-critical, so 56pt is not required, but 44pt is the floor)
- Do not use a slider/range for plate counts -- imprecise and difficult for motor-impaired users
- Each count change should announce the new value via `aria-live="polite"` on the input

**Barbell Weight:**
```html
<label for="barbell-weight">Barbell Weight (lb)</label>
<input id="barbell-weight" type="text" inputmode="decimal"
       value="45" aria-describedby="barbell-weight-help" />
<span id="barbell-weight-help">Standard bar: 45 lb. Women's bar: 35 lb.</span>
```

**Rest Timer Default:**
```html
<label for="rest-timer">Default Rest Timer (seconds)</label>
<input id="rest-timer" type="text" inputmode="numeric"
       value="120" min="0" max="600"
       aria-describedby="rest-timer-help" />
<span id="rest-timer-help">0 to disable. Range: 0-600 seconds.</span>
```

**Theme Selector:**
```html
<fieldset>
  <legend>Theme</legend>
  <label><input type="radio" name="theme" value="dark" checked /> Dark</label>
  <label><input type="radio" name="theme" value="light" /> Light</label>
  <label><input type="radio" name="theme" value="system" /> System</label>
</fieldset>
```

### 8.3 Template Selection (Onboarding Step 2)

Template cards act as a single-select choice:

```html
<div role="radiogroup" aria-label="Choose your training template">
  <div role="radio" aria-checked="false" tabindex="0"
       aria-label="Operator. Balanced strength plus endurance. 3 strength days, 3 cardio days per week. 6 week cycle.">
    <!-- Card content -->
  </div>
  <div role="radio" aria-checked="true" tabindex="0"
       aria-label="Zulu. 4 strength sessions per week. A B split with two intensity levels. 6 week cycle.">
    <!-- Card content -->
  </div>
  <!-- ... -->
</div>
```

- Arrow keys should navigate between options (standard `radiogroup` keyboard interaction)
- Selected card gets `aria-checked="true"` and a visual selected indicator (border, checkmark, background change -- not color alone)
- Selection does NOT auto-advance to the next step (3.2.2 compliance)

### 8.4 Zulu/Fighter Lift Selection

The lift selection dropdowns for cluster customization:

```html
<fieldset>
  <legend>Day A Lifts (select 2-3)</legend>
  <label for="day-a-slot-1">Slot 1</label>
  <select id="day-a-slot-1" aria-required="true">
    <option value="">Choose a lift</option>
    <option value="squat">Squat (1RM: 414 lb)</option>
    <option value="bench">Bench (1RM: 275 lb)</option>
    <!-- Only lifts with 1RM entered are shown -->
  </select>
  <!-- ... -->
</fieldset>
```

- Show the 1RM value in the option text so the user can verify they selected the correct lift
- If fewer than 2 lifts have 1RM data, show a message: "Enter at least 2 lift maxes before selecting this template" with a link to 1RM entry
- Validation error: "Day A requires at least 2 lifts" -- announced via `aria-live`

---

## 9. Timer Accessibility

### 9.1 WCAG 2.2.1 Timing Adjustable

The rest timer is a countdown that auto-starts after set completion. While it does not *prevent* user action (the user can start the next set at any time), it creates time pressure through the countdown visual and the "elapsed time nudge" after zero.

**Requirements:**

1. **The timer must not block interaction.** The user can complete the next set while the timer is still running. This is already the case in the PRD. Confirm it remains true -- the "Complete Set" button must be accessible and focusable even while the timer is active.

2. **Timer duration must be adjustable.** The PRD allows global default override in Settings. This satisfies 2.2.1's "adjustable" requirement. However, add the ability to adjust per-session as well: the "+30 seconds" tap extends the current timer, but there is no "-30 seconds" or direct time entry. Add a way for the user to set a custom time before the timer starts (e.g., long-press the timer button to set a custom duration, or provide a setting within the session actions menu).

3. **Timer must be dismissible.** The PRD includes a "Skip" button. Confirm this immediately stops the timer and all associated feedback (visual, haptic, audio). The "elapsed time nudge" after zero should also be dismissible.

### 9.2 Timer for Non-Visual Users

For users who cannot see the countdown:

1. **Audio countdown option:** In addition to the completion chime, offer an optional audio tick at 10-second intervals (or 30-second intervals for longer timers). This gives auditory time awareness without being annoying. Default: off. Setting: "Timer audio countdown: Off / 30s intervals / 10s intervals."

2. **VoiceOver announcements:** As specified in Section 2.3 of this review:
   - Timer start: announce duration once
   - 30 seconds remaining: announce once
   - Timer complete: announce + haptic + optional audio

3. **Do not repeatedly update the VoiceOver live region.** Updating `aria-live` every second would make VoiceOver speak continuously, which is unusable. Only announce at key intervals.

4. **Provide timer value on demand.** If the user navigates to the timer element with VoiceOver, it should announce the current remaining time: "Rest timer, 1 minute 23 seconds remaining." Use `aria-label` that updates every 5 seconds (not every second) to balance accuracy with performance.

### 9.3 Timer Visual Requirements

1. **The countdown number must meet contrast requirements** at all times (4.5:1 for text under 18pt; 3:1 for 18pt+). Since the timer is 48pt+, the 3:1 large-text standard applies.

2. **The progress ring must meet non-text contrast requirements** (3:1) for both the filled and unfilled portions against the card background.

3. **At timer completion (0:00):** The visual state must change through more than color alone. Options: the "0:00" text pulses (animation), the ring fills completely, a "Rest Over" text label appears. The PRD mentions showing elapsed time ("Resting: 2:45") which serves as a non-color state change. This is adequate.

4. **Reduced motion:** When `prefers-reduced-motion` is active, the progress ring should show a static filled state rather than a smooth animation. The countdown number still counts down (text changes are not motion). The pulsing at completion should be replaced with a static bold/highlighted state.

---

## 10. Specific Recommendations

The following numbered list represents concrete changes and additions to the PRD, prioritized by impact. Items marked **[Critical]** are required for WCAG 2.2 AA compliance. Items marked **[Recommended]** significantly improve usability for disabled users. Items marked **[Enhancement]** go beyond AA but represent best practice.

### Section 10 Expansion (replace current 6 bullet points)

**[Critical]**

1. **Specify exact color values for all text and background combinations.** The PRD must define: primary background, card background, muted text color, accent color, error color, and success color. Each combination must be verified at 4.5:1 (normal text) or 3:1 (large text / non-text). Add a color specification table to Section 9.

2. **Add `role`, `aria-label`, and `aria-live` specifications for all interactive components.** The session view alone requires: `role="region"` per exercise card, `role="timer"` for rest countdown, `role="alert"` for undo toast, `role="progressbar"` for program progress, `role="radiogroup"` for template selection, and custom labels for every button. Add an "Accessible Names" subsection to Section 5.4.

3. **Add explicit prev/next buttons for exercise navigation.** The horizontal swipe pager is inaccessible to VoiceOver, Switch Control, and keyboard users. Add persistent "Previous" and "Next" buttons (can be arrow icons) that are always present in the DOM. Reference: Section 5.4, exercise navigation.

4. **Extend the undo toast timeout to 10 seconds minimum, or keep undo available until the next set is completed.** Five seconds is insufficient for users with motor impairments to locate and activate the undo button, especially through VoiceOver or Switch Control. WCAG 2.2.1 requires timing to be adjustable or sufficient. Reference: Section 5.4, set completion interaction.

5. **Disable auto-advance when VoiceOver is active.** The 1.5-second auto-advance after exercise completion will fire before a VoiceOver user can process the announcement. Instead, announce the completion and provide a "Next Exercise" button. Detect VoiceOver via `UIAccessibility.isVoiceOverRunning` (not available in web -- instead, check if the user has only interacted via VoiceOver gestures, or simply always provide the Next button and make auto-advance a visual convenience that does not affect focus). Reference: Section 5.4.

6. **Add `aria-invalid`, `aria-describedby`, and `role="alert"` for all form error states.** The 1RM entry form, settings forms, and template selection forms need proper error association. Errors must be announced, specific, and inline. Reference: Section 5.1, Section 5.7.

7. **Use individual set indicators with both icon and color.** Each set completion circle must contain a checkmark (completed) or remain empty (pending), not rely on fill color alone. Reference: Section 5.4.

8. **Plate badges must always display the weight number as primary content.** Color-coded plate badges using competition colors are confusable under protanopia and deuteranopia. The weight number (text) must be the primary identifier, with color as supplementary. Reference: Section 5.2.

9. **Add focus management specification for onboarding wizard, session auto-advance, and modal dialogs.** When views change, focus must move to the appropriate element. This prevents VoiceOver users from being stranded on invisible elements. Reference: Section 5.0, Section 5.4.

10. **Specify non-text contrast minimums (3:1) for all UI components.** Set circles, timer ring, tab bar icons, card borders, and form input borders must all meet 3:1 contrast. The PRD only specifies text contrast. Reference: Section 9.

**[Recommended]**

11. **Add a "Simple Mode" setting.** Reduces session view to: exercise name, weight, "Tap when done" button, and plain-language set counter. Removes plate breakdown, percentages, and auto-advance. Improves usability for users with cognitive disabilities. Reference: new item in Section 5.7.

12. **Add a "Sound" setting with options: On / Off / Vibrate Only.** Specify audio feedback for set completion, timer completion, session completion, and errors. Audio is critical for users wearing headphones in a gym who cannot see or feel their phone. Reference: new item in Section 5.7.

13. **Add audio countdown option for rest timer.** Offer optional audio ticks at configurable intervals (off / 30s / 10s). Helps non-visual users track time without constant VoiceOver announcements. Reference: Section 5.5.

14. **Specify Dynamic Type support implementation.** `rem` units alone are insufficient for iOS Safari PWA. Document the JavaScript probe technique for detecting the system text size scale factor, specify base/min/max sizes for every text element, and define layout breakpoints for accessibility text sizes (AX3+). Reference: Section 10, Section 6.

15. **Add minimum 8pt spacing between adjacent interactive elements in session view.** Sweaty/gloved hands and fatigue tremor reduce tap precision. Spacing prevents accidental activation of adjacent targets. Reference: Section 6.3.

16. **Add a template recommendation flow in onboarding.** "How many days per week can you lift?" reduces 7 options to 1-3, helping users with cognitive disabilities and decision fatigue. Reference: Section 5.0.

17. **Ensure the "End Workout" action is accessible from the bottom of the screen.** It is currently specified as top-right, which is unreachable for one-handed use and potentially occluded by AssistiveTouch. Add it to a bottom-sheet actions menu or as a second path. Reference: Section 5.4.

18. **Reorder DOM in session view so "Complete Set" button is first focusable element in each exercise card.** Use CSS visual ordering to maintain the design hierarchy while putting the most-needed action first in the tab/scan order. This reduces the number of switch presses or tab key presses needed for single-switch and keyboard users. Reference: Section 5.4.

**[Enhancement]**

19. **Add distinct shapes or patterns to plate badges for color-deficient users.** Beyond weight numbers, different shapes per plate weight provide an additional non-color differentiator. This goes beyond AA but is valuable for users with both color deficiency and small-text reading difficulty.

20. **Add `aria-roledescription` to the exercise pager container.** Value: "exercise pager." This orients screen reader users to the navigation model.

21. **Specify VoiceOver announcement text for every state change.** The PRD provides one example. This review provides full announcement specifications in Section 2. Integrate these into the PRD as an appendix or subsection of Section 10.

22. **Add a "Session Actions" menu accessible via a single button for VoiceOver users.** Contains: Complete Set, Skip Timer, Override Weight, Edit Reps, End Workout. This consolidates all workout actions into a single navigation point, reducing the number of swipe gestures needed.

23. **Test with real assistive technology users.** Include at least one VoiceOver user, one Switch Control user, and one user with low vision in the QA testing plan. Automated accessibility testing (axe, Lighthouse) catches only ~30% of accessibility issues. Reference: Section 12 (success criteria).

24. **Add a skip navigation link.** At the top of each screen, include a visually hidden "Skip to main content" link that becomes visible on focus. This helps keyboard and Switch Control users bypass the navigation structure.

25. **Document the complete haptic pattern language.** The PRD mentions "haptic tap" for set completion and "haptic pulse" for timer. This review specifies 7 distinct patterns (Section 3.1). Include the full pattern specification to ensure developers implement distinguishable haptic events.

---

## Summary of Missing WCAG 2.2 AA Criteria

| Criterion | Status in PRD | This Review Section |
|---|---|---|
| 1.1.1 Non-text Content | Partially addressed | 1 (audit table) |
| 1.3.1 Info and Relationships | Not addressed | 1, 8 |
| 1.4.3 Contrast | Partially addressed | 1, 7.1 |
| 1.4.4 Resize Text | Partially addressed | 1, 4 |
| 1.4.11 Non-text Contrast | Not addressed | 1, 7.4 |
| 2.1.1 Keyboard | Not addressed | 1 |
| 2.2.1 Timing Adjustable | Not addressed | 1, 9 |
| 2.4.3 Focus Order | Not addressed | 1 |
| 2.4.7 Focus Visible | Not addressed | 1 |
| 2.5.5 / 2.5.8 Target Size | Addressed | 1 |
| 3.2.2 On Input | Partially addressed | 1 |
| 4.1.2 Name, Role, Value | Partially addressed | 1, 2, 8 |

**Bottom line:** The PRD's Section 10 establishes intent but lacks the specificity needed for implementation. Of the 12 WCAG 2.2 AA success criteria audited, only 1 is fully addressed (target size), 4 are partially addressed, and 7 are not addressed at all. This review provides the implementation-level detail needed to close these gaps.
