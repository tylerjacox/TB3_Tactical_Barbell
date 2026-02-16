# Tactical Barbell Domain Review

**Reviewer:** TB Methodology Expert
**Date:** 2026-02-15
**Document Reviewed:** PRD_v2.md
**Scope:** Validate all training methodology claims against the Tactical Barbell book series (TB1: Strength, TB2: Conditioning, TB3: Base Building & Protocols)

---

## Executive Summary

The PRD v2 gets the broad strokes of Tactical Barbell correct but contains several meaningful deviations from the published methodology. The most significant issues are: (1) Operator set/rep schemes differ from the book, (2) Zulu's Tier 1/Tier 2 model oversimplifies what the book actually prescribes, (3) Gladiator Week 6 interpretation is wrong, (4) Mass Strength session numbering misrepresents the program, and (5) several templates have session structures that don't match TB's cluster-based approach. Below is a point-by-point analysis.

---

## 1. Training Max Definition

**PRD says:** Training Max = 90% of True Max (calculated 1RM).

**TB Methodology:** The book prescribes that all percentage work is based on a **Training Max (TM)**, which is **90% of your tested or calculated 1RM**. This is stated explicitly in TB1. The 90% figure is canonical. Some online discussions reference 85%, but that is from other programs (notably 5/3/1 by Jim Wendler). TB specifically uses 90%.

**Verdict: CORRECT.** The PRD's 90% Training Max is faithful to the TB methodology.

**One nuance:** TB also allows athletes to use their "True Max" if they are experienced and have tested it recently (e.g., a true 1RM performed in the gym). The toggle between True Max and Training Max in the PRD is a reasonable UX decision. However, TB's default recommendation is always to use the Training Max for programming percentages. The PRD correctly makes Training Max the default.

---

## 2. Template Percentage Progressions

### 2.1 Operator

**PRD says:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 70 | 80 | 90 | 75 | 85 | 95 |
| Sets x Reps | 5x5 | 5x5 | 4x3 | 5x5 | 5x3 | 4x1 |

**TB Methodology (Operator Standard):**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 70 | 80 | 90 | 75 | 85 | 95 |
| Sets x Reps | 3-5x5 | 3-5x5 | 3-4x3 | 3-5x5 | 3-5x3 | 3-4x1 |

**Verdict: PERCENTAGES CORRECT, SETS DEVIATE.**

The percentages are correct. The set/rep scheme has been "resolved" in the PRD by picking the maximum of the range (5x5 instead of 3-5x5, etc.), but the book's original notation is ranges, not fixed numbers. This matters because:

- TB explicitly says the athlete should choose their set count within the range based on how they feel that day. A beginner or someone running a high-conditioning load might do 3x5. An experienced lifter feeling good does 5x5.
- **Week 6 is listed as 4x1 in the PRD**, but the book says **3-4 x 1-2**. The "1-2" reps part is missing. Some athletes do doubles at 95%, which is within the book's prescription. The PRD drops this option entirely.

**Recommendation:** Display the set count as the maximum (5 sets for "3-5" range), but also display a note like "minimum 3 sets" so the user knows they can stop early. For Week 6, the rep target should be "1-2" (user can do singles or doubles), not fixed at 1.

### 2.2 Mass Strength (formerly Mass Template)

**PRD says:**

| Week | 1 | 2 | 3 |
|---|---|---|---|
| % (Sessions 1,3,5) | 65 | 75 | 80 |
| Sets x Reps | 4x8 | 4x6 | 4x3 |

Session 6 (Deadlift):

| Week | 1 | 2 | 3 |
|---|---|---|---|
| % | 65 | 75 | 80 |
| Sets x Reps | 4x5 | 4x5 | 1x3 |

**TB Methodology:** The Mass Template in TB1 prescribes a 3-week block used as a hypertrophy wave. The percentages 65/75/80 and the 4x8, 4x6, 4x3 progression match the book for the main lifts. The deadlift day percentages and sets also match.

**Verdict: CORRECT.** The percentages and set/rep schemes match TB for Mass Strength.

### 2.3 Zulu

**PRD says:**

| Week pattern | Tier 1 % (A1, B1) | Tier 2 % (A2, B2) | Sets x Reps |
|---|---|---|---|
| Weeks 1, 4 | 70 | 75 | 3x5 |
| Weeks 2, 5 | 80 | 80 | 3x5 |
| Weeks 3, 6 | 90 | 90 | 3x3 |

**TB Methodology:** Zulu is a 4-day-per-week template with an A/B split. Each day is performed twice per week. The book prescribes two "clusters" of percentages for each half of the 6-week block:

- **Cluster One (first pass through A or B in a given week):** 70, 80, 90 across weeks 1-3, repeated weeks 4-6
- **Cluster Two (second pass through A or B in a given week):** 75, 80, 90 across weeks 1-3, repeated weeks 4-6

So in Week 1: A-day first occurrence uses 70%, A-day second occurrence uses 75%. B-day first occurrence uses 70%, B-day second occurrence uses 75%.

The PRD's "Tier 1 / Tier 2" naming is non-standard but the mapping is essentially correct for weeks 1 and 4 (70 vs 75). However, in weeks 2/5 (both 80%) and weeks 3/6 (both 90%), the two tiers converge and both sessions are at the same percentage. This is actually what the book prescribes -- the differentiation only exists in weeks 1 and 4.

**Set/rep scheme:** The book prescribes **3x5** for weeks 1-2 and 4-5, and **3x3** for weeks 3 and 6. The PRD matches this.

**Verdict: MOSTLY CORRECT.** The percentages and sets match. The "Tier 1/Tier 2" naming is non-standard but functionally equivalent. The key point is that in weeks 2-3 and 5-6, both instances of each day are at the same percentage, which the PRD correctly captures.

**Minor issue:** The PRD says the A/B split defaults are:
- A: Squat, Weighted Pull-up, (optional: Military Press)
- B: Bench, Deadlift, (optional 3rd)

The book's example Zulu cluster is Military Press, Squat, WPU for Day A and Bench, Deadlift for Day B. The PRD drops Military Press from the A-day default and makes it optional, which is a reasonable UX decision but deviates from the book's example. Since Zulu is meant to be customizable, this is acceptable.

### 2.4 Fighter

**PRD says:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 75 | 80 | 90 | 75 | 80 | 90 |
| Sets x Reps | 5x5 | 5x5 | 5x3 | 5x5 | 5x5 | 5x3 |

**TB Methodology (Fighter Bangkok):** The Fighter template has multiple sub-variants. The most commonly referenced is Fighter Bangkok:

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 75 | 80 | 90 | 75 | 80 | 90 |
| Sets x Reps | 3-5x5 | 3-5x5 | 3-5x3 | 3-5x5 | 3-5x5 | 3-5x3 |

**Verdict: PERCENTAGES CORRECT, SETS DEVIATE.**

Same issue as Operator -- the PRD resolves the range to the maximum (5). The book says 3-5 sets. The percentages are correct.

**Additional note:** The book specifies that Fighter is designed for athletes whose primary training is in another domain (martial arts, military selection, etc.) and who need to maintain strength with minimal gym time. The 2 sessions/week is correct.

### 2.5 Gladiator

**PRD says:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 70 | 80 | 90 | 75 | 85 | 95 |
| Sets x Reps | 5x5 | 5x5 | 5x3 | 5x5 | 5x5 | 5x descending (3,2,1,3,2) |

**TB Methodology:** Gladiator uses a 5x5 base with the following progression:

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 70 | 80 | 90 | 75 | 85 | 95 |
| Sets x Reps | 5x5 | 5x5 | 5x3 | 5x5 | 5x5 | 5x3-2-1 |

The percentages match the book. The set/rep scheme for weeks 1-5 is correct (no ranges -- Gladiator uses fixed 5x5 and 5x3, unlike Operator/Fighter which use ranges).

**Week 6 is addressed separately in section 7 below.**

**Verdict: PERCENTAGES CORRECT.** Sets for weeks 1-5 are correct. Week 6 needs correction (see section 7).

### 2.6 Mass Protocol (formerly "Mass")

**PRD says:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|
| % | 75 | 80 | 90 | 75 | 85 | 90 |
| Sets x Reps | 4x6 | 4x5 | 4x3 | 4x6 | 4x4 | 4x3 |

**TB Methodology:** The "Mass" program in TB1 (which the PRD renames "Mass Protocol") is a hypertrophy-focused template. The percentages and rep schemes in the PRD match the book's prescription.

**Verdict: CORRECT.** Percentages and sets/reps match the TB methodology.

### 2.7 Grey Man

**PRD says:**

| Week | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| % | 70 | 80 | 90 | 70 | 80 | 90 | 75 | 85 | 95 | 75 | 85 | 95 |
| Sets x Reps | 3x6 | 3x5 | 3x3 | 3x6 | 3x5 | 3x3 | 3x6 | 3x5 | 3x1 | 3x6 | 3x5 | 3x1 |

**TB Methodology:** Grey Man is a 12-week "low-profile" program designed for situations where you need to train with minimal equipment or visibility. It uses 3 sets throughout (no ranges) and the percentage progression builds across two 6-week waves: the first wave (weeks 1-6) tops out at 90%, and the second wave (weeks 7-12) tops out at 95%.

The book's prescription matches the PRD exactly: 70/80/90 repeated, then 75/85/95 repeated, with 3x6, 3x5, 3x3 for the first wave and 3x6, 3x5, 3x1 for the second wave.

**Verdict: CORRECT.** All percentages and set/rep schemes match.

---

## 3. Set/Rep Schemes and the "3-5 x 5" Convention

**PRD says:** "When a template specifies a range (e.g., '3-5 x 5'), the app displays the maximum set count (e.g., 5 sets of 5 reps). The user completes sets by tapping; they can stop early (completing only 3 of 5 sets is valid and logged)."

**TB Methodology:** The book gives set ranges (e.g., "3-5 sets of 5 reps") and tells the athlete to choose based on:
- How many lifts are in their cluster (more lifts = fewer sets per lift)
- How they feel that day (autoregulation)
- Their training experience
- Their conditioning load outside the gym

The athlete is supposed to **decide before the session** how many sets they will do, not start at 5 and "stop when tired." The TB philosophy is that you commit to a number and execute it. Starting at 5 and stopping at 3 because you're tired is not the same as planning 3 sets because you have a heavy conditioning day after.

**Verdict: PARTIALLY FAITHFUL.** The PRD's approach (show max, complete what you can) is a pragmatic UX choice but subtly changes the training philosophy. A more faithful implementation would let the user choose their set count before starting (e.g., a selector: "How many sets today? 3 / 4 / 5") and then track completion against that target.

**Recommendation:** Consider adding a "target sets" selector at the start of each session for templates with set ranges. Default to the maximum. This preserves the TB intent of pre-committing to a number while still being easy to use.

---

## 4. Session Structures

### 4.1 Operator

**PRD says:**
- Session 1 (Strength): Squat, Bench, Weighted Pull-up
- Session 2 (Endurance): Duration-based
- Session 3 (Strength): Squat, Bench, Weighted Pull-up
- Session 4 (Endurance): Duration-based
- Session 5 (Strength): Squat, Bench, Deadlift
- Session 6 (Endurance): Duration-based

**TB Methodology:** The book prescribes Operator as having 3 strength sessions per week plus conditioning work. The user selects a "cluster" of 2-3 lifts. The classic Operator cluster is Squat, Bench, Weighted Pull-up. The third strength session can swap one lift (e.g., Deadlift for WPU on the third day). The alternating strength/endurance pattern is correct.

**Verdict: CORRECT.** The session structure matches the book's standard Operator template. The Deadlift swap on Session 5 is a common and book-supported variation.

**Note:** The book actually says the user picks their cluster of 2-3 lifts, and those lifts appear in every strength session. The Deadlift-on-day-3 swap is a popular variation but is not the only way to run Operator. The PRD hardcodes this specific configuration, which is fine for the user's spreadsheet replacement but is less flexible than TB intends. For v1 this is acceptable.

### 4.2 Gladiator

**PRD says:**
- Session 1: Squat, Bench
- Session 2: Deadlift, (Military Press if configured)
- Session 3: Squat, Bench

**TB Methodology:** Gladiator is described in TB1 as a 3-day-per-week template. The book prescribes that you select your cluster of lifts and perform **all cluster lifts in every session**. Gladiator does not use an A/B split or session-specific lift assignments. A typical Gladiator cluster might be Squat, Bench, Deadlift -- and you do all three lifts in all three sessions.

**Verdict: INCORRECT.** The PRD's session structure (splitting lifts across sessions) does not match the book. In Gladiator, all cluster lifts should appear in every session. The A/B split with Squat/Bench on days 1 and 3 and Deadlift/MP on day 2 is not how the book prescribes it.

**Recommendation:** Change Gladiator so that all selected cluster lifts appear in every session. The user should select 2-4 lifts for their cluster, and every session includes all of them. This is the book's intent -- high volume across all lifts, 3x per week.

### 4.3 Mass Protocol

**PRD says:**
- Session 1: Squat, Bench
- Session 2: Deadlift, (Military Press if configured)
- Session 3: Squat, Bench

**TB Methodology:** Mass Protocol (the 6-week hypertrophy template) follows the same cluster-based approach. The book prescribes that you select your cluster and perform all lifts in every session.

**Verdict: INCORRECT.** Same issue as Gladiator. All cluster lifts should appear in every session, not split across days.

**Recommendation:** Same as Gladiator -- all selected cluster lifts in every session.

### 4.4 Grey Man

**PRD says:**
- Session 1: Squat, Bench
- Session 2: Deadlift, Weighted Pull-up
- Session 3: Squat, Bench

**TB Methodology:** Grey Man is designed for minimal equipment situations and uses a cluster approach. However, Grey Man is somewhat unique in that the book does allow for splitting lifts across sessions when training with limited time or equipment. The split shown in the PRD (upper/lower or push/pull pattern) is a reasonable interpretation.

That said, the canonical Grey Man approach still has the trainee performing their full cluster in each session. The 3-session structure with all cluster lifts per session is the default.

**Verdict: LIKELY INCORRECT but more defensible than Gladiator/Mass Protocol.** Grey Man's "low profile" nature means some flexibility in session structure. However, the default should still be all cluster lifts in every session unless the user has a reason to split.

**Recommendation:** Default to all cluster lifts in every session. If the user's spreadsheet specifically used this split, it can be offered as a customization option, but it should not be the only option.

---

## 5. Zulu Specifics

### 5.1 Tier 1 / Tier 2 and A/B Structure

**PRD says:** "Each A and B day is performed twice per week. The first instance of each uses Tier 1 percentages; the second instance uses Tier 2 percentages."

**TB Methodology:** This is essentially correct. The book calls them "Cluster One" and "Cluster Two" (not "Tier 1" and "Tier 2"), but the concept is the same. The first time you perform Day A in a week, you use Cluster One percentages. The second time, Cluster Two. Same for Day B.

The weekly schedule is: A1, B1, A2, B2 (with rest days interspersed). The book does not mandate specific days of the week but suggests spacing them out (e.g., Mon A1, Tue B1, Thu A2, Fri B2).

**Verdict: CORRECT in concept, non-standard naming.**

### 5.2 Standard vs I/A

**PRD says:** "Standard only for v1. I/A variant deferred to v1.1 (insufficient specification)."

**TB Methodology:** Zulu has two main variants:

- **Standard:** Same percentages for all lifts. This is what the PRD implements.
- **I/A (Intensive/Accumulation):** The first instance of each day (Cluster One) uses higher intensity / lower reps, and the second instance (Cluster Two) uses lower intensity / higher volume. Specifically:
  - Cluster One (I): Heavier percentages, lower reps (e.g., 3x3 at 90%)
  - Cluster Two (A): Lighter percentages, higher reps (e.g., 3x6 at 70%)

  The I/A variant provides daily undulating periodization within the week.

**Verdict: Deferral is REASONABLE.** The I/A variant is more complex and would require different set/rep schemes per instance. Deferring to v1.1 is a sound decision. When implemented, the key change is that Cluster One and Cluster Two would have different rep schemes (not just different percentages).

### 5.3 Lift Selection

**PRD says:** A day defaults to Squat, WPU, (optional Military Press). B day defaults to Bench, Deadlift, (optional 3rd).

**TB Methodology:** The book's example cluster is:
- A: Military Press, Squat, Weighted Pull-up (3 lifts)
- B: Bench, Deadlift (2 lifts)

The book allows customization of lift selection but the examples always show Military Press as a core A-day lift, not optional. The user can choose any combination, but the defaults in the PRD should match the book's example more closely.

**Recommendation:** Change A-day default to: Military Press, Squat, Weighted Pull-up (matching the book). Keep B-day default as Bench, Deadlift with optional 3rd slot.

---

## 6. Fighter Specifics

**PRD says:** "User selects 2-3 lifts from: Squat, Bench, Military Press, Deadlift. All selected lifts are performed in both sessions."

**TB Methodology:** The book prescribes Fighter for athletes who need minimal gym time. The user selects **2-3 lifts** (the book is explicit about this -- not 1, not 4). Those lifts appear in **every session**. The book's examples include:
- Fighter 2-lift: Squat, Bench Press
- Fighter 3-lift: Squat, Bench Press, Deadlift

The PRD is correct that the user selects 2-3 lifts and all selected lifts appear in both sessions.

**Verdict: CORRECT.** The PRD's Fighter implementation matches the book.

**One note:** The book also mentions Weighted Pull-up as a valid Fighter lift choice. The PRD limits the selection to Squat, Bench, Military Press, Deadlift. Weighted Pull-up should be added to the selectable list.

**Recommendation:** Add Weighted Pull-up to Fighter's selectable lift pool.

---

## 7. Gladiator Week 6 "5 x 3-2-1"

**PRD says:** "5 sets with reps: 3, 2, 1, 3, 2. Total: 11 reps across 5 sets at 95%."

**TB Methodology:** The book's notation "5 x 3-2-1" means:

**5 sets total using a descending rep scheme of 3, 2, 1, repeated.** The pattern is 3, 2, 1, 3, 2 for 5 sets. This interpretation is actually consistent with what the PRD states.

However, there is debate in the TB community about this notation. Some interpret it as:
- 5 sets cycling through 3, 2, 1 reps = 3, 2, 1, 3, 2 (PRD interpretation)
- 3 mini-sets of 3-2-1 within each of 5 "super sets" (less common)

The most widely accepted interpretation, and the one that makes programming sense at 95% of TM, is the PRD's interpretation: 5 sets with reps descending as 3, 2, 1, 3, 2.

**Verdict: CORRECT (most accepted interpretation).** The PRD's interpretation of 3, 2, 1, 3, 2 across 5 sets is the standard community interpretation and makes physiological sense at 95%.

---

## 8. Mass Strength (formerly Mass Template) Sessions

**PRD says:** "This template has 4 training sessions per cycle (not 6). Sessions 2 and 4 are rest/recovery days."

**Session structure:**
- Session 1: Squat, Bench, WPU
- Session 3: Squat, Bench, WPU
- Session 5: Squat, Bench, WPU
- Session 6: Deadlift only

**TB Methodology:** The Mass Template in the book is structured as a 3-week block with the following weekly structure:

- **Day 1:** Main lifts (Squat, Bench, WPU) at prescribed percentages
- **Day 2:** Supplemental / accessory work (the book suggests rows, curls, etc.)
- **Day 3:** Main lifts (same as Day 1)
- **Day 4:** Supplemental / accessory work
- **Day 5:** Main lifts (same as Day 1)
- **Day 6:** Deadlift day

So the "6 sessions per cycle" in the original PRD v1 was actually **6 sessions per week**, not per cycle (the cycle is 3 weeks). Sessions 2 and 4 are not rest days -- they are supplemental/accessory days. However, since the PRD app only tracks the main barbell lifts and not accessories, treating them as rest days is a pragmatic simplification.

**Verdict: PARTIALLY CORRECT.** The PRD is correct that there are effectively 4 tracked sessions per week (not per cycle). Sessions 2 and 4 are supplemental days in the book, not pure rest days. The PRD's simplification of ignoring them is acceptable for v1 since accessory work is out of scope, but calling them "rest/recovery days" is misleading.

**Recommendation:** Change the description to: "Sessions 2 and 4 are supplemental/accessory days (not tracked in the app)." This is more accurate than "rest/recovery" and sets expectations for future accessory tracking.

**Important correction:** The PRD says "4 training sessions per cycle" but should say "4 tracked training sessions per week" (the cycle is 3 weeks, so 12 tracked sessions total). The current wording implies 4 sessions across all 3 weeks, which would be too infrequent.

---

## 9. Endurance Sessions in Operator

**PRD says:** Endurance sessions with duration ranges (30-60 min, 60-90 min, 90-120 min depending on week).

**TB Methodology:** TB2 (Conditioning) provides extensive protocols for conditioning work. Within the Operator template context, the endurance sessions are from TB's "Green Protocol" (lower intensity, base-building focused) or "Black Protocol" (higher intensity, sport-specific). The book prescribes:

- **Type:** Running, rucking, swimming, rowing, cycling -- any sustained aerobic activity. The user chooses.
- **Duration:** The duration ranges in the PRD approximately match the book's guidance for Operator's conditioning sessions, though the exact ranges depend on which conditioning protocol the user follows (Green vs Black).
- **Intensity:** The book distinguishes between LSS (Long Slow Steady) and HIC (High Intensity Conditioning). The PRD does not capture this distinction.

**Verdict: APPROXIMATELY CORRECT but oversimplified.** The duration ranges are reasonable approximations. The PRD correctly presents them as duration-based with user discretion.

**Missing context:** The book prescribes that endurance type (LSS vs HIC) should vary across the week. A typical Operator week might be: Strength, LSS, Strength, HIC, Strength, LSS/long run. The PRD treats all endurance sessions identically.

**Recommendation for v1:** The current approach is sufficient. In a future version, consider adding a toggle for endurance session type (LSS / HIC / SE) with suggested durations per type.

---

## 10. Program Completion / Retest

**PRD says:** "After the final session, show completion screen. Prompt: 'Start a new cycle' (same template, fresh) or 'Choose new template' or 'Retest 1RM.'"

**TB Methodology:** The book prescribes the following at the end of a cycle:

1. **Retest or recalculate your 1RM.** After completing a block, you should test your maxes (or use a recent heavy set to estimate) before starting a new block.
2. **Decide on continuation.** If your numbers went up, increase your TM and run another block. If they stalled, consider switching templates or adjusting volume.
3. **No mandatory deload week between blocks.** TB does not prescribe a deload week between strength blocks (unlike 5/3/1). The training max and the percentage-based progression already manage fatigue. However, many experienced TB practitioners take a light week or 3-5 rest days between blocks.

**Verdict: MOSTLY CORRECT.** The three options offered (new cycle, new template, retest) cover the main paths. The book emphasizes retesting before starting a new cycle, so "Retest 1RM" should be the **primary/recommended** option, not just one of three equal choices.

**Recommendation:** Make "Retest 1RM" the primary CTA on the completion screen, with "Start new cycle" and "Choose new template" as secondary options. Add a brief note: "TB recommends retesting your maxes before starting a new block."

---

## 11. Missing TB Concepts

### 11.1 Base Building (SIGNIFICANT OMISSION for general TB users, ACCEPTABLE for this specific app)

TB's Base Building protocol is a multi-week conditioning-focused block that precedes the strength templates. It includes:
- 5 weeks of strength endurance circuits
- 3 weeks of max strength testing
- Conditioning work throughout

Base Building is typically the first thing a new TB athlete does before running Operator, Fighter, etc. The PRD omits it entirely.

**Assessment:** Since this app is replacing a specific user's spreadsheet that already assumes the user is past Base Building, this omission is acceptable for v1. However, if the app is ever distributed more broadly, Base Building should be added.

### 11.2 Conditioning Protocols (PARTIALLY ADDRESSED)

The Operator endurance sessions capture the bare minimum of TB's conditioning framework. TB2 prescribes detailed protocols:
- **Green Protocol:** LSS-heavy, 3-5 sessions/week
- **Black Protocol:** HIC-heavy, more intense, fewer sessions
- **Professional Protocol:** Combines both for operational athletes

The PRD mentions endurance duration ranges but does not distinguish between conditioning protocols.

**Assessment:** Acceptable for v1. The endurance sessions are tracked as duration-based activities, which is sufficient for the spreadsheet replacement use case.

### 11.3 Cluster Selection Rules (PARTIALLY ADDRESSED)

TB has rules about how to select lift clusters:
- **Operator:** Maximum 3 lifts per cluster. Must include at least one lower body and one upper body push.
- **Fighter:** 2-3 lifts. Same body coverage rules.
- **Zulu:** A-day and B-day clusters should cover different movement patterns.
- **All templates:** Deadlift typically gets limited frequency (1-2x/week) due to recovery demands. This is why Operator swaps WPU for DL on the third day.

The PRD addresses this implicitly through its hardcoded session structures but does not enforce these rules when the user selects lifts.

**Recommendation:** Add validation or guidance when users customize lift selections. At minimum, warn if a cluster has no lower body lift or no upper body push.

### 11.4 Continuation Protocol (NOT ADDRESSED)

After completing a block, TB offers a "Continuation" protocol where the athlete can extend their training by running modified blocks without a full reset. The concept of continuation vs. starting fresh is part of the TB philosophy but is relatively advanced.

**Assessment:** Not needed for v1.

### 11.5 Operator Variations (NOT ADDRESSED)

The book describes several Operator sub-variants:
- **Operator Standard:** What the PRD implements
- **Operator Black:** Higher intensity, for experienced athletes
- **Operator LP (Linear Progression):** For beginners

The PRD only implements Operator Standard, which is the correct default.

**Assessment:** Acceptable for v1. Could be added in v1.1+.

### 11.6 Fighter Sub-Variants (NOT ADDRESSED)

Fighter has multiple sub-variants in the book:
- **Fighter Bangkok:** The one the PRD implements (75/80/90 repeating)
- **Fighter Green:** Modified percentages for concurrent conditioning
- **Fighter/Gladiator Hybrid:** Alternating Fighter and Gladiator blocks

The PRD implements Fighter Bangkok, which is the most common variant.

**Assessment:** Acceptable for v1.

### 11.7 Warm-Up Sets (NOT ADDRESSED)

The book prescribes warm-up sets before working sets, typically:
- Bar x 10
- 40% x 5
- 60% x 3
- Working sets begin

The PRD does not include warm-up set display.

**Assessment:** This was already noted as a v1.1 candidate. Acceptable for v1.

---

## Summary of Corrections Needed

### Critical (affects training accuracy)

| # | Issue | PRD Section | Correction |
|---|-------|-------------|------------|
| 1 | Operator Week 6 reps should be "1-2" not "1" | 5.3.1 | Change 4x1 to 4x(1-2) -- user can do singles or doubles |
| 2 | Gladiator session structure should have ALL cluster lifts in EVERY session | 5.3.5 | Remove the A/B split; all selected lifts appear in all 3 sessions |
| 3 | Mass Protocol session structure should have ALL cluster lifts in EVERY session | 5.3.6 | Same correction as Gladiator |
| 4 | Grey Man session structure should default to ALL cluster lifts in EVERY session | 5.3.7 | Same correction as Gladiator/Mass Protocol |
| 5 | Mass Strength: "4 sessions per cycle" should be "4 tracked sessions per week" | 5.3.2 | Clarify that the 3-week cycle has 4 tracked sessions per WEEK (12 total) |

### High (affects user experience or methodology fidelity)

| # | Issue | PRD Section | Correction |
|---|-------|-------------|------------|
| 6 | Operator/Fighter set ranges should offer a target-set selector, not just "complete what you can" | 5.3.1, 5.3.4 | Consider pre-session "How many sets?" selector defaulting to max |
| 7 | Zulu A-day default should include Military Press (not optional) | 5.3.3 | Change default A cluster to: Military Press, Squat, WPU |
| 8 | Fighter should allow Weighted Pull-up as a selectable lift | 5.3.4 | Add WPU to Fighter's lift pool |
| 9 | "Retest 1RM" should be the primary CTA on program completion | 5.4 | Elevate retest as primary action, demote "start new cycle" |
| 10 | Mass Strength sessions 2/4 are supplemental days, not rest days | 5.3.2 | Update description to "supplemental/accessory days (not tracked)" |

### Low (nice to have, methodology enhancements)

| # | Issue | PRD Section | Correction |
|---|-------|-------------|------------|
| 11 | No cluster selection validation (e.g., must include upper + lower body) | 5.3 | Add guidance/warning when clusters violate TB rules |
| 12 | Endurance sessions don't distinguish LSS vs HIC | 5.3.1 | Future: add endurance type toggle |
| 13 | No warm-up set display | 5.4 | Already deferred to v1.1 |
| 14 | Only one Operator variant (Standard) | 5.3.1 | Future: add Operator Black, LP variants |

---

## Cross-Reference: Original Spreadsheet Data

Based on the PM review's description of the original spreadsheet:

- **1RM values (Squat 438, Bench 359, Deadlift 499, WPU 102, Military Press empty):** These appear to be True Max values. The Training Max at 90% would be: Squat 394.2, Bench 323.1, Deadlift 449.1, WPU 91.8.

- **Operator had 6 sessions (3 strength + 3 endurance):** Matches the PRD and the book.

- **Zulu had "A/B One" and "A/B Two" with A lifts (Mil Press, Squat, WPU) and B lifts (Bench, DL):** Note that the spreadsheet has Military Press as a primary A-day lift, not optional. The PRD should match this default.

- **Gladiator, Mass, Grey Man had plate loading strings:** This confirms these templates were being used with the same plate calculator, supporting the PRD's approach.

---

*End of Domain Review*
