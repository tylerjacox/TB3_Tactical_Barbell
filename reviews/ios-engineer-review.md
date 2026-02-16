# iOS/PWA Engineer Technical Review — Tactical Barbell PWA

**Reviewer:** Senior iOS/Frontend Engineer (PWA Specialist)
**Document:** PRD.md
**Date:** 2026-02-15

---

## 1. iOS PWA Limitations & Gotchas

The PRD is targeting the single hardest platform for PWAs. iOS Safari's PWA support is functional but riddled with sharp edges. Here is what will bite us:

### Storage Eviction (Critical Risk)

The PRD says "All data persists across sessions via local storage" (Success Criteria #4). This is the single biggest risk in the entire project.

**WebKit ITP 7-day eviction:** Safari will purge all client-side storage (localStorage, IndexedDB, Cache API, service worker registrations) after 7 days of the user not visiting the origin. For a standalone PWA launched from the home screen, "visiting the origin" means launching the app. If a user takes a week off from training (deload week, vacation, injury), they come back to a completely blank app. Every 1RM, every session log, every active program -- gone.

This is not theoretical. It ships in production WebKit. The 7-day clock resets on each visit, so regular users are fine, but "regular" in a strength training context includes planned deload weeks where you explicitly do not train.

**localStorage quota:** Safari caps localStorage at ~5MB per origin. The PRD's data model is small enough that this is unlikely to be a problem in v1, but session history will grow unboundedly. 1000 completed sessions with exercise logs could approach the limit. IndexedDB has a more generous quota (~50MB in Safari, though it varies by device storage).

**No persistence guarantee:** Even within the 7-day window, Safari can evict storage under storage pressure (low device storage). There is no `navigator.storage.persist()` equivalent that works reliably on iOS.

### No Push Notifications (iOS 16.4+ Caveat)

The PRD does not mention push notifications, which is good -- they are scoped out. But worth noting: iOS 16.4+ does support Web Push for home screen PWAs, so this could be a v2 feature for rest timer alerts if the user backgrounds the app.

### No Background Sync

There is no Background Sync API on iOS Safari. This does not directly affect the PRD since there is no backend, but it means:
- If the user closes the app mid-session, we cannot save state in the background.
- The rest timer will not fire if the app is backgrounded. We must handle this with timestamp comparison on resume, not `setInterval`.

### No Badge API

`navigator.setAppBadge()` does not work on iOS. If we wanted to show "Session due today" as a badge, we cannot.

### Service Worker Lifecycle Quirks

- iOS terminates service workers aggressively (within seconds of the page going to background).
- `self.skipWaiting()` and `clients.claim()` are unreliable on iOS. The new service worker may not activate until the user fully closes and reopens the PWA.
- The `fetch` event handler in the service worker is sometimes not called on iOS when navigating within a standalone PWA, particularly for the initial navigation request.

### Standalone Mode Viewport Bugs

- **100vh includes the status bar and home indicator.** `100vh` in standalone mode means the content extends under the status bar and home indicator area. The PRD correctly mentions `env(safe-area-inset-*)`, but the layout must use `100dvh` (dynamic viewport height) or `calc(100vh - env(safe-area-inset-top) - env(safe-area-inset-bottom))` for full-height containers.
- **Orientation lock does not work.** The manifest says `"orientation": "portrait"` but iOS ignores this entirely. If the user rotates the phone, the app will rotate. We need to handle landscape gracefully or add a CSS-based "please rotate" overlay.
- **Status bar overlap.** With `black-translucent`, the status bar area is part of our viewport. Content must not place interactive elements in the top 44-59px (varies by device, Dynamic Island vs notch vs no notch).

### Keyboard Behavior

- **Fixed elements shift when the keyboard opens.** Bottom tab bars using `position: fixed` will be pushed up by the keyboard on iOS, which causes layout jank. During number input (the primary interaction in this app), the bottom nav will jump. Solution: detect keyboard open via `visualViewport.resize` event and hide or reposition the bottom bar.
- **`inputmode="decimal"`** is correct for triggering the numeric pad, but on some iOS versions it shows a decimal keyboard without a "done" button. We need `inputmode="decimal"` combined with explicit blur-on-enter handling, or use `type="number"` with `pattern="[0-9]*"` as a fallback.
- **Keyboard avoidance with scroll.** When a focused input is inside a scrollable container, iOS Safari may scroll the entire page rather than just the container. This is especially problematic in the session view where the user is tapping through sets and entering weights.

### Rubber-band Scrolling

`overscroll-behavior: none` (mentioned in the PRD) prevents pull-to-refresh in Safari 16+, but does not prevent the rubber-band bounce effect on the page body. To fully prevent bounce, the body must not be scrollable -- only inner containers should scroll. This requires a careful `overflow: hidden` on `html`/`body` with `overflow-y: auto` on the main content area.

### Link/Navigation Behavior

In standalone mode, any navigation to a different origin opens in Safari, not in the PWA. Any navigation to the same origin but outside the manifest `scope` also opens in Safari. This affects error pages, OAuth (if ever added), and external links.

### No Web App Install Prompt

There is no `beforeinstallprompt` event on iOS. We cannot programmatically prompt the user to install. We need a manual "Add to Home Screen" instruction overlay that detects if the app is running in-browser vs standalone mode.

---

## 2. Architecture & Framework

### PRD Suggestion: "Vanilla JS, or lightweight framework (Preact/Svelte preferred over React for bundle size)"

This is directionally correct but insufficiently specific. My recommendation:

### Recommendation: Preact + HTM (no build step) or Preact + Vite

**Why Preact over Vanilla JS:**
- This app has meaningful UI state: active program, mid-workout tracking, set completion, rest timers, settings forms. Vanilla JS for this becomes a hand-rolled framework within two weeks.
- Preact is 3KB gzipped. It adds virtually nothing to bundle size.
- Preact's `useState`/`useEffect` hooks map cleanly to the session tracking state machine.
- Preact has a well-tested `preact-iso` router that works correctly in standalone PWA mode (hash-based routing avoids the iOS navigation pitfalls).

**Why not Svelte:**
- Svelte 5 (runes) is the current version and the compiled output is slightly larger than Preact for small apps. Svelte wins at scale; Preact wins for apps this size.
- Svelte's build output includes a runtime that is comparable to Preact's. The "no runtime" marketing of Svelte 3/4 is no longer accurate for Svelte 5.
- Developer pool for Preact is larger (React knowledge transfers directly).

**Why not React:**
- 40KB+ gzipped minimum. Unacceptable for an offline-first PWA where the entire app should be under 100KB gzipped total.

### Recommended Stack

| Layer | Choice | Size |
|---|---|---|
| UI | Preact 10.x + hooks | ~3KB gz |
| Routing | preact-iso or hash-based custom (< 1KB) | ~0.5KB gz |
| Build | Vite with preact preset | Dev only |
| CSS | Vanilla CSS with CSS custom properties (no Tailwind, no CSS-in-JS) | 0KB runtime |
| State | Preact signals or simple useReducer | ~1KB gz |
| Storage | IndexedDB via idb-keyval (or thin wrapper) | ~0.5KB gz |
| Service Worker | Hand-written (Workbox is overkill for this scope) | ~2KB |
| **Total runtime** | | **~7KB gz** |

### Build Output Target
- Total JS: < 30KB gzipped
- Total CSS: < 10KB gzipped
- Total app shell: < 50KB gzipped (all assets for offline use)
- First paint: < 1 second on 4G, instant from cache

---

## 3. Data Persistence Strategy

### localStorage vs IndexedDB

The PRD wavers between localStorage and IndexedDB. Here is the decision:

**Use IndexedDB as the primary store. Do not use localStorage for application data.**

Reasons:
1. **Async API.** localStorage is synchronous and blocks the main thread. During a workout, writing a large session log to localStorage will cause visible jank.
2. **Capacity.** IndexedDB gives us ~50MB on iOS vs ~5MB for localStorage. Session history will grow.
3. **Structured data.** IndexedDB stores objects natively. localStorage requires JSON.stringify/parse on every read/write, which is both slow and error-prone.
4. **Transaction support.** IndexedDB has transactions. If the user completes a set and we need to update both the session state and the completion count, we can do this atomically.

**Use localStorage only for:** a single key `tb3_version` to track data schema version, and `tb3_lastActive` timestamp for eviction detection.

### Wrapper Library

Use `idb-keyval` (600 bytes gzipped) for simple key-value access, or write a thin wrapper (~50 lines) around the raw IndexedDB API. Do not use Dexie or other heavy libraries.

### Storage Schema

```
IndexedDB Database: "tb3"
  Object Store: "settings"    -> UserProfile (single record, key: "profile")
  Object Store: "programs"    -> ActiveProgram (single record, key: "active")
  Object Store: "sessions"    -> SessionLog[] (keyed by id, indexed by date)
  Object Store: "maxTests"    -> OneRepMaxTest[] (keyed by id, indexed by date + liftName)
  Object Store: "backup"      -> full snapshot for recovery
```

### Safari Storage Eviction Mitigation (Critical)

This is the most important technical decision in the project. Here is the multi-layer defense:

**Layer 1: Eviction detection on launch.**
On every app launch, read `localStorage.tb3_lastActive`. If the key is missing but IndexedDB has data, storage was partially evicted. If both are empty and the user previously had data, full eviction occurred. Show a recovery prompt.

**Layer 2: Automatic JSON backup to clipboard/file.**
Every time the user completes a session or updates 1RM data, serialize the entire database to a JSON blob and offer a "Backup" button in settings. On iOS, this can use the Web Share API (`navigator.share` with a file) to save to Files, or the Clipboard API as a fallback.

**Layer 3: URL-encoded state for critical data.**
Encode the user's current 1RM values (the most painful data to lose) into a URL hash. Bookmark this URL. If storage is evicted, navigating to the bookmark restores 1RMs. This is ~200 bytes of data (5 lifts x ~40 bytes each), well within URL limits.

**Layer 4: Manual export/import in Settings.**
A dedicated Export (download JSON) and Import (file picker) flow. The PRD lists Export/Import as out of scope. This must be moved to v1. Without it, the app is a liability -- users will lose data.

**Layer 5: Periodic "backup reminder" prompt.**
If `Date.now() - lastBackupDate > 7 days`, show a non-blocking prompt: "It has been a while since your last backup. Tap to export your data."

---

## 4. Service Worker Strategy

### Caching Strategy

The PRD says "cache-first strategy for all app assets." This is correct for the app shell but needs refinement:

**App Shell (cache-first, update in background):**
- `index.html`
- All JS bundles
- All CSS
- App icons and splash images
- Manifest

**Strategy: Stale-While-Revalidate for index.html, Cache-First for hashed assets.**

Hashed assets (e.g., `app.a1b2c3.js`) are immutable -- cache-first is correct and optimal. But `index.html` must use stale-while-revalidate so that when we deploy an update, the next launch fetches the new HTML (which references new hashed asset URLs) while still showing the cached version immediately.

### Cache Versioning

Use a version constant in the service worker:

```javascript
const CACHE_VERSION = 'tb3-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/app.[hash].js',
  '/app.[hash].css',
  // ... all assets
];
```

On activation, delete all caches that do not match `CACHE_VERSION`. This is the standard cache-busting pattern.

### Update Flow

1. User launches app. Service worker serves cached version instantly.
2. Service worker checks for updates in the background.
3. If a new service worker is found and installed, show a non-blocking toast: "Update available. Tap to refresh."
4. User taps toast -> `location.reload()`.
5. Do NOT call `skipWaiting()` automatically. On iOS this can cause a blank screen if the old cached assets are purged before the new ones are ready.

### What to NOT Cache

- Do not precache all template calculations. These are computed from user data and stored in IndexedDB.
- Do not cache any external URLs (there should be none).

### Service Worker Registration

```javascript
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js', { scope: '/' });
  });
}
```

Register on `load`, not on `DOMContentLoaded`, to avoid competing for bandwidth on first visit.

---

## 5. Performance

### Template Calculation Cost

The PRD asks about Grey Man specifically: 12 weeks x 3 sessions x 4 lifts x plate calculation each = 144 plate calculations.

**Each plate calculation is:** one greedy iteration over ~7 plate sizes = ~20 operations. Total: ~2,880 simple arithmetic operations. This is trivially fast -- sub-millisecond on any modern iPhone.

**Recommendation: Compute lazily, cache aggressively.**

- When the user activates a program, compute and cache the full schedule (all weeks, all sessions, all weights, all plate breakdowns) into IndexedDB.
- This is a one-time cost (~1ms for Grey Man, immeasurable for 6-week templates).
- If the user changes 1RM values, recompute and re-cache.
- If the user changes plate inventory, recompute and re-cache.
- Do not recompute on every render.

**Pre-computation is the right call** because:
1. The data is fully deterministic (1RM + template = exact schedule).
2. It enables showing "Week at a glance" and "Next session" on the dashboard without lazy loading.
3. The computation cost is negligible, so there is no reason to defer it.
4. It avoids bugs where different views show inconsistent data due to race conditions in lazy calculation.

### Render Performance

The session view is the hot path. During a workout, the user is tapping "complete set" repeatedly. Each tap should:
1. Update a single boolean in the session state.
2. Re-render only the affected set indicator (not the entire session view).

Preact's virtual DOM diffing handles this well, but if we notice jank, we can memoize exercise cards with `React.memo` (Preact equivalent).

**Rest timer:** Use `requestAnimationFrame` for the countdown display, not `setInterval`. `setInterval` drifts and is throttled by iOS when the app is in the background. Calculate remaining time as `targetTime - Date.now()` on each frame.

---

## 6. State Management

### Recommended Approach: Preact Signals or useReducer

For an app this size, a global state management library (Redux, Zustand, etc.) is overkill. Use one of:

**Option A (Preferred): Preact Signals**
- Preact signals (`@preact/signals`) are 1KB and provide fine-grained reactivity.
- A single `appState` signal with nested state avoids prop drilling.
- Signals automatically batch updates, which is ideal for the "complete set" tap-tap-tap pattern.

**Option B: useReducer + Context**
- A single `useReducer` at the app root with a well-typed action union.
- Pass dispatch via context.
- More familiar to React developers.

### State Shape

```typescript
interface AppState {
  // Persistent (synced to IndexedDB)
  profile: UserProfile;
  activeProgram: ActiveProgram | null;
  computedSchedule: ComputedSchedule | null;  // PRD missing this
  sessionHistory: SessionLog[];
  maxTestHistory: OneRepMaxTest[];

  // Ephemeral (in-memory only)
  activeSession: ActiveSessionState | null;
  restTimer: RestTimerState | null;
  ui: {
    currentTab: 'home' | 'program' | 'history' | 'settings';
    modal: string | null;
  };
}
```

### Mid-Workout State (Critical)

The PRD does not address what happens when the user closes the app mid-session. This is the most common interruption pattern in a gym:
- User is between sets.
- Phone locks / user checks a text / app is backgrounded.
- iOS may terminate the PWA process (especially under memory pressure).
- User reopens the app.

**Solution: Persist `activeSession` to IndexedDB on every state change.**

Every tap-to-complete, every set marked done, every weight override -- immediately write to IndexedDB. When the app launches, check for an `activeSession` in IndexedDB. If found:
- Show a "Resume session?" prompt with the session summary.
- "Resume" restores exact state (including which sets were completed).
- "Discard" deletes the in-progress session.

This write-on-every-change pattern is fine because:
- IndexedDB writes are async and non-blocking.
- The data is tiny (< 1KB per session state).
- The write frequency is low (once per set completion, ~15-30 times per workout).

### Undo/Redo

The PRD does not mention undo, but it is important for the "tap-to-complete" interaction. Accidental taps happen constantly in a gym (sweaty hands, bumped phone).

**Recommendation: Single-level undo for set completion only.**
- Track `lastAction` in ephemeral state.
- Show an "Undo" button (or toast) for 5 seconds after each set completion.
- Only undo the most recent action (no redo stack needed).
- This is cheap to implement and prevents the most common error.

---

## 7. CSS/Layout Concerns

### Safe Area Handling

The PRD mentions `env(safe-area-inset-*)` but does not specify the implementation pattern. Here is the correct approach:

```css
:root {
  --sat: env(safe-area-inset-top);
  --sar: env(safe-area-inset-right);
  --sab: env(safe-area-inset-bottom);
  --sal: env(safe-area-inset-left);
}

/* App shell layout */
body {
  padding-top: var(--sat);
  padding-left: var(--sal);
  padding-right: var(--sar);
}

/* Bottom tab bar */
.tab-bar {
  padding-bottom: var(--sab);
  /* Height = tab bar content + safe area */
  height: calc(56px + var(--sab));
}

/* Main content scroll area */
.main-content {
  height: calc(100dvh - var(--sat) - 56px - var(--sab));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
```

**Do not use `100vh`.** Use `100dvh` (dynamic viewport height, supported in Safari 15.4+). If supporting older iOS, use the `window.innerHeight` JavaScript fallback and set a CSS custom property.

### Keyboard Avoidance

```javascript
// Detect keyboard open/close
if (window.visualViewport) {
  window.visualViewport.addEventListener('resize', () => {
    const keyboardOpen = window.visualViewport.height < window.innerHeight * 0.75;
    document.documentElement.classList.toggle('keyboard-open', keyboardOpen);
  });
}
```

```css
/* Hide bottom tab bar when keyboard is open */
.keyboard-open .tab-bar {
  display: none;
}

/* Adjust main content height */
.keyboard-open .main-content {
  height: 100dvh; /* Full height when tab bar is hidden */
}
```

### Scroll Behavior

Full-page scroll must be prevented. Only inner containers scroll:

```css
html, body {
  overflow: hidden;
  position: fixed;
  width: 100%;
  height: 100%;
}
```

The `position: fixed` on body is the nuclear option but is the only reliable way to prevent iOS Safari rubber-banding on the body while allowing inner scroll containers to work correctly.

Each scrollable view (session list, history list, settings) should be an `overflow-y: auto` container with `-webkit-overflow-scrolling: touch`.

### Dark Mode

The PRD says "dark mode default" and "respect `prefers-color-scheme`." These are contradictory. Pick one:

**Recommendation: Default to dark, allow override.**

```css
:root {
  color-scheme: dark light;

  /* Dark theme (default) */
  --bg-primary: #000000;
  --bg-card: #1c1c1e;
  --text-primary: #ffffff;
  --text-secondary: #8e8e93;
  --accent: #0a84ff; /* iOS blue */
  --separator: #38383a;
}

/* Light theme override */
[data-theme="light"] {
  --bg-primary: #f2f2f7;
  --bg-card: #ffffff;
  --text-primary: #000000;
  --text-secondary: #6c6c70;
  --accent: #007aff;
  --separator: #c6c6c8;
}

/* System preference when theme is "system" */
@media (prefers-color-scheme: light) {
  [data-theme="system"] {
    /* same as light override above */
  }
}
```

Use iOS system colors as the palette baseline. This makes the app feel native. The PRD's "blue or orange" accent suggestion should be resolved: **use iOS system blue (#0a84ff dark, #007aff light) for interactive elements.** Orange is harder to maintain sufficient contrast in both themes.

### Additional CSS Concerns

**Font stack:**
```css
body {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif;
}

.plate-breakdown, .weight-display {
  font-family: 'SF Mono', ui-monospace, monospace;
  font-variant-numeric: tabular-nums;
}
```

`font-variant-numeric: tabular-nums` ensures weight numbers do not shift layout as digits change (e.g., "95" vs "100").

**Touch states:**
```css
button, .tappable {
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation; /* removes 300ms delay, prevents double-tap zoom */
  user-select: none;
  -webkit-user-select: none;
}
```

`touch-action: manipulation` is critical. Without it, iOS adds a 300ms delay on taps to detect double-tap-to-zoom. For a tap-to-complete workout tracker, that 300ms makes the app feel sluggish.

---

## 8. Missing Technical Requirements

The PRD omits several things we need to build this:

### 8.1 — Data Export/Import (Must Be v1)
The PRD lists this as "Out of Scope (v1)." This is a mistake. Given Safari's storage eviction behavior, shipping without export/import means users will lose data. This must be v1 scope. At minimum: JSON export/import via the Share API or a download link.

### 8.2 — App Update Flow
No mention of how the user gets app updates. Service worker update detection, user notification, and cache invalidation strategy are all unspecified.

### 8.3 — Data Migration Strategy
No versioning scheme for the stored data. When we ship v1.1 with a schema change, how do we migrate existing user data? Need a `schemaVersion` field and migration functions.

### 8.4 — Error States
The PRD specifies one error case (insufficient plates). It does not specify:
- What happens when localStorage/IndexedDB is full?
- What happens when the user enters invalid data (0 reps, negative weight)?
- What happens when a program references a lift the user has not entered a 1RM for?
- What happens when storage is evicted?

### 8.5 — "Add to Home Screen" Onboarding
No mention of how to guide the user to install the PWA. We need a first-launch detection (`display-mode: standalone` media query) and an instruction overlay for in-browser users.

### 8.6 — Program Lifecycle
The PRD says the user selects a template and a start date, but does not specify:
- What happens when a program ends? Auto-prompt to rerun, show summary, return to template selection?
- Can the user have multiple programs active? (Presumably no, but should be stated.)
- Can the user restart a program mid-cycle?
- Can the user skip a session or mark it as missed?
- What happens to the active program if the user changes their 1RM mid-cycle?

### 8.7 — Number Input UX Details
The primary interaction is entering numbers (weights, reps). The PRD does not specify:
- Should we use native `<input type="number">` or a custom numeric stepper?
- For weight entry, is there a +/- stepper with the rounding increment?
- For reps entry (1-15), is it a picker, a number input, or preset buttons?

### 8.8 — Rest Timer Behavior
The PRD mentions a rest timer but does not specify:
- Does it auto-start after completing a set?
- What sound/vibration (if any) plays when the timer ends?
- Does it work when the app is backgrounded? (Answer: it cannot, see Section 1.)
- What does the UI look like during the countdown?

### 8.9 — Set/Rep Flexibility
The PRD shows "3-5 x 5" for some templates. It does not specify:
- Does the user choose 3, 4, or 5 sets at the start of the session?
- Or is there a default (e.g., 5 sets shown, user completes as many as they want)?
- If sets are variable, how does this affect the completion tracking?

### 8.10 — Accessibility
No mention of accessibility requirements. At minimum:
- VoiceOver support for all interactive elements.
- Sufficient color contrast (WCAG AA at minimum).
- Proper ARIA labels on icon-only buttons (tab bar icons).
- Reduced motion support (`prefers-reduced-motion`).

### 8.11 — Splash Screen Generation
The PRD mentions Apple launch images "for common iPhone sizes." There are currently 12+ distinct launch image sizes required for full coverage (iPhone SE through iPhone 16 Pro Max). These must be generated at build time or we need a splash screen strategy that avoids the combinatorial explosion (e.g., a simple CSS-based loading screen with `apple-mobile-web-app-capable`).

### 8.12 — Weighted Pull-up Bodyweight Component
The PRD's data model has `isBodyweight: boolean` for Weighted Pull-up. But the plate calculator for pull-ups takes a total weight that goes on the belt. How does the user know their total added weight? If a program says "work at 80% of 1RM" and the 1RM is "bodyweight + 45lb," the app needs to know the user's bodyweight to calculate: `targetWeight = (1RM * 0.80) - bodyweight`. The PRD does not mention storing bodyweight anywhere. This must be addressed or the pull-up calculations will be wrong.

Actually -- reviewing the PRD more carefully, the `LiftEntry` stores `weight` and `reps`, and the Epley formula gives a 1RM based on the weight used. For weighted pull-ups, this weight should be the ADDED weight only (not bodyweight + added). The PRD seed data shows "Weighted Pull-up: 45 lb, 5 reps, 1RM = 45.6" which confirms this -- 45 lb is the added weight. So the percentages would be of the added weight 1RM. This works but is confusing. The PRD should explicitly clarify that for weighted pull-ups, all weights refer to added weight only, and the plate calculator receives the full calculated weight directly (no barbell subtraction).

---

## 9. Specific Recommendations

Numbered list of concrete changes to the PRD:

1. **Move Export/Import to v1 scope.** Safari storage eviction makes this a data-loss prevention feature, not a convenience feature. At minimum: JSON export to Files app via Share API, JSON import via file picker. Estimate: 1-2 days of work.

2. **Replace localStorage with IndexedDB as the primary data store.** All references to localStorage in the PRD should be changed to IndexedDB. Keep localStorage only for a schema version check and last-active timestamp. Update Section 3 ("Storage" row), Section 5.6, Section 6.4, and the Data Model section accordingly.

3. **Add a `schemaVersion` field to the data model.** Include a migration strategy document. Start at version 1. Every release that changes the data shape must include a migration function from the previous version.

4. **Add a `bodyweight` field to UserProfile** or explicitly document that weighted pull-up weights refer to added weight only and the plate calculator receives this value directly. The current ambiguity will cause implementation bugs.

5. **Add an `activeSession` field to the data model** that persists the in-progress workout state. Include which sets have been completed, timestamps, and any weight overrides. This is the mid-workout resume capability.

6. **Specify the set/rep variability behavior.** For templates that say "3-5 x 5," add a clear rule: e.g., "Default to the maximum set count. User can skip sets. Completed sets are tracked; remaining sets are shown as incomplete." Or: "User selects set count at session start."

7. **Remove `"orientation": "portrait"` from the manifest** or add a note that iOS ignores this. Add a CSS-based landscape handler (either a "rotate your device" overlay or responsive landscape layout).

8. **Change the rest timer specification** to clarify: (a) it auto-starts on set completion, (b) it displays remaining time as a countdown overlay or inline element, (c) it uses `Date.now()` comparison (not `setInterval`) so it survives backgrounding, (d) vibration on completion via `navigator.vibrate()` (supported on iOS Safari 16.4+).

9. **Add an "Install to Home Screen" instruction flow.** Detect standalone mode via `window.matchMedia('(display-mode: standalone)')`. If running in-browser, show a persistent banner with iOS-specific "Add to Home Screen" instructions (Share button -> "Add to Home Screen").

10. **Add a program lifecycle specification.** Document: (a) only one program can be active at a time, (b) what happens when a program completes (show summary, prompt to start new), (c) user can abandon a program (confirm dialog), (d) changing 1RM mid-program recalculates remaining sessions.

11. **Specify the CSS approach: vanilla CSS with custom properties.** No CSS-in-JS, no Tailwind. For an app this size, a single CSS file with custom properties for theming is the simplest, most performant option. Total CSS should be under 10KB.

12. **Add a `computedSchedule` object to the data model.** This is the pre-computed output of (template + 1RM values + plate inventory). It should be stored in IndexedDB and regenerated when any input changes. This is what the session view reads from.

13. **Clarify the theme behavior.** The PRD says "dark mode default" and "respect prefers-color-scheme." Recommendation: three-way toggle (Dark / Light / System). Default selection: Dark. When set to System, use `prefers-color-scheme`. Update Settings table accordingly.

14. **Add the "Undo last set completion" feature.** A 5-second toast with undo action after each tap-to-complete. This is essential for gym use with sweaty/gloved hands.

15. **Add a "last backup" date to Settings and a periodic backup reminder.** If no backup in 7+ days, show a non-blocking prompt. This is the safety net for storage eviction.

16. **Specify that the framework choice is Preact 10.x with Vite as the build tool.** This removes ambiguity for the implementer and avoids the "which framework" discussion during build.

17. **Add splash screen generation strategy.** Either: (a) use `pwa-asset-generator` at build time to generate all required Apple launch images from a single source, or (b) use a simple CSS-based splash screen and skip Apple launch images (accepts a brief white flash on launch).

18. **Add accessibility requirements.** Minimum: WCAG AA contrast, VoiceOver-compatible markup, ARIA labels for icon buttons, `prefers-reduced-motion` support.

19. **Add a `lastActiveTimestamp` to the data model** and a launch-time eviction detection check. If storage appears empty but the timestamp cookie (stored via `document.cookie` with a 1-year expiry, which survives ITP eviction) indicates prior use, show a "Your data may have been cleared by iOS. Restore from backup?" prompt.

20. **Specify the routing strategy: hash-based routing.** Use `/#/home`, `/#/program`, `/#/history`, `/#/settings`. Hash routing avoids iOS standalone mode navigation issues where path-based routing can cause the PWA to open in Safari instead of staying in the standalone window.

---

## Summary

The PRD is solid on product requirements but underspecifies the iOS-specific technical constraints that will determine whether this app succeeds or fails. The three highest-priority gaps are:

1. **Storage eviction defense** -- without export/import and eviction detection, users will lose data. This is not hypothetical.
2. **Mid-workout state persistence** -- the app will be backgrounded/terminated during every single workout. Session state must survive this.
3. **Keyboard and viewport handling** -- number input is the primary interaction. If the keyboard causes layout jank, the app feels broken.

Everything else is solvable with standard iOS PWA patterns. Address these three and the rest is execution.
