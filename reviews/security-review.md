# Security & Privacy Review — Tactical Barbell PWA

> **Reviewer role:** Application Security Engineer
> **Document reviewed:** PRD v2 (`/PRD_v2.md`)
> **Date:** 2026-02-15

---

## Executive Summary

The Tactical Barbell PWA has a favorable security profile by design: no backend, no authentication, no network communication after initial load, and no sensitive financial or medical data. The primary risks are **data integrity** (malicious import corrupting the app), **data leakage on shared devices**, and **service worker compromise during updates**. Most risks are Low or Medium severity. There are zero Critical findings.

This review identifies 18 concrete recommendations, prioritized by risk level.

---

## 1. Threat Model

### 1.1 Assets at Risk

| Asset | Sensitivity | Notes |
|---|---|---|
| 1RM values & training history | Low | Fitness performance data. Not PII under GDPR unless combined with identity. No financial, medical diagnosis, or authentication data. |
| Session notes (free text) | Low-Medium | User may write anything here, including health observations ("knee pain," "shoulder injury"). Could be considered health-adjacent data. |
| Plate/equipment configuration | Negligible | Gym equipment preferences. |
| Computed program schedule | Negligible | Derived from 1RM + template selection. Fully reconstructable. |

### 1.2 Adversaries

| Adversary | Motivation | Realistic? |
|---|---|---|
| **Shared device user** (family member, gym buddy) | Curiosity, accidental data viewing/overwriting | **Yes** — the most realistic threat for v1 |
| **Physical device thief** | Data access after device theft | **Low** — device lock screen is the primary defense; this app adds nothing worth targeting specifically |
| **Malicious file sharer** | Social engineering via crafted JSON import file | **Low-Medium** — someone could share a "training program" JSON that exploits the import parser |
| **MITM attacker** (on update path) | Inject malicious code via service worker update | **Low** — requires active network position and HTTPS compromise |
| **Rogue PWA clone** | Phishing — host a lookalike to harvest data | **Very Low** — no credentials to steal, no accounts to compromise |
| **Supply chain attacker** | Compromise npm dependency | **Low** — small dependency tree limits exposure |

### 1.3 Attack Surfaces

1. **JSON import parser** — accepts external file input, deserializes, writes to IndexedDB
2. **URL hash router** — reads `window.location.hash` to determine navigation
3. **URL-encoded 1RM recovery** (Section 6.6 Layer 4) — reads data from URL hash
4. **Service worker update channel** — fetches `index.html` via stale-while-revalidate
5. **Free-text input fields** — session notes stored and rendered
6. **Numeric input fields** — weight, reps, barbell weight, plate quantities
7. **IndexedDB storage** — accessible to any JS on same origin

---

## 2. Export/Import Security

### 2.1 Malicious JSON Import

**Risk: Medium.** This is the highest-risk input path because it accepts arbitrary external data.

**Prototype pollution:** If the import parser uses naive object spread or `Object.assign` without filtering, a crafted JSON file could inject `__proto__`, `constructor`, or `prototype` properties. Example payload:

```json
{
  "__proto__": { "isAdmin": true },
  "schemaVersion": 1,
  "profile": { "constructor": { "prototype": { "polluted": true } } }
}
```

**Mitigation requirements:**
- Parse with `JSON.parse()` only (no `eval`, no `Function` constructor) — this is standard but must be explicit.
- After parsing, validate against an allowlist of expected top-level keys. Reject any object containing `__proto__`, `constructor`, or `prototype` as keys at any nesting depth.
- Alternatively, use a schema validation library (e.g., Zod, which is ~2KB gzipped) to validate the parsed object against the TypeScript interfaces before writing to IndexedDB.
- Enforce maximum file size (recommend 1MB — a year of daily training is well under 100KB).

**Stored XSS via imported data:** If the `notes` field (or any string field) in imported JSON contains HTML/script tags, and the app renders notes using `innerHTML` or `dangerouslySetInnerHTML`, this is exploitable. Preact's JSX escapes by default (`{value}` in JSX is safe), but this must be a hard rule: **never render user-supplied strings via innerHTML**.

**Oversized payloads:** A multi-gigabyte JSON file could freeze the browser tab during parsing.

**Mitigation:** Check `file.size` before reading. Reject files over 1MB with a user-facing message.

### 2.2 Should Exports Be Encrypted?

**No, not for v1.** The data is low-sensitivity fitness metrics. Encryption adds complexity (key management, password UX) that is disproportionate to the risk. If someone obtains your export file, they learn your squat max — not your bank account.

**Recommendation:** Document in the export flow that the file is unencrypted plaintext. "Your export file contains your training data in plain text. Store it somewhere private if that matters to you."

### 2.3 Import Validation Requirements

Before overwriting existing data, the import flow MUST:

1. Parse JSON and catch `SyntaxError` — display "Invalid file format" on failure
2. Validate `schemaVersion` is a recognized version number
3. Validate structure against expected schema (required keys, correct types)
4. Reject unexpected keys (especially prototype-polluting keys)
5. Validate numeric ranges (e.g., weight 1-1500, reps 1-15, as defined in Section 5.1)
6. Sanitize all string fields (strip HTML tags, enforce max length — 500 chars for notes)
7. Show a preview/confirmation: "This will replace your current data. Import contains: 4 lifts, 23 sessions, last updated [date]. Continue?"
8. If `schemaVersion` is older than current, run the same migration path used for normal upgrades

### 2.4 Export File Contents

The export contains everything in IndexedDB: 1RM values, session history, notes, settings. No secrets, no credentials, no device identifiers. The main concern is session notes — a user might write something personal. This is acceptable for a local export workflow but worth noting in the export UI.

---

## 3. URL-Encoded 1RM Recovery (Section 6.6 Layer 4)

### 3.1 Data Leakage

**Risk: Low, but real.** URL hash fragments (`#`) are NOT sent in HTTP `Referer` headers (per RFC 7231), which eliminates the most common URL data leakage vector. However:

- **Browser history:** The URL with encoded 1RM data will appear in browser history. On a shared device, another user could see it.
- **Bookmarks:** If bookmarked and synced (iCloud, Chrome sync), the data travels to other devices.
- **Link sharing:** User might accidentally share the URL (paste in chat, copy from address bar).

**Assessment:** The data in question is squat/bench/deadlift maxes — fitness performance numbers. This is not sensitive by most standards. The leakage risk is proportionate: a privacy-conscious user can simply not use this feature.

**Recommendation:** Acceptable for v1 as-is. Add a brief note in the UI: "This URL contains your lift maxes. Treat it like a bookmark, not a password."

### 3.2 Crafted URL Injection

**Risk: Low-Medium.** If the app reads 1RM data from the URL hash and writes it to IndexedDB without validation, a crafted URL could inject bad data.

Attack scenario: Someone sends a link like `https://app.example.com/#/recover?data=<malicious_payload>`. If the user clicks it, the app could write corrupted data to storage.

**Mitigation requirements:**
- Apply the same numeric validation to URL-decoded 1RM values as to manual entry (weight 1-1500, reps 1-15, lift name must be one of the 5 known lifts).
- Never render URL-decoded strings as HTML.
- Show a confirmation prompt before writing URL-decoded data: "Restore these maxes? Squat: 405, Bench: 275..." — let the user verify the values look correct.
- Consider using a simple checksum or HMAC in the URL to detect tampering (optional — overkill for the data sensitivity, but cheap to implement).

### 3.3 Encoding Format

The PRD says "~200 bytes." For 5 lifts with 1RM values, a simple format works: `#recover=SQ:405,BP:275,DL:495,MP:155,WP:90`. This is human-readable and self-documenting, which is actually a security benefit — the user can inspect what data is in the URL before using it.

---

## 4. Service Worker Security

### 4.1 Compromised Service Worker

**Risk: Low (requires HTTPS compromise).** A service worker can intercept all fetch requests and modify responses. If an attacker could install a malicious service worker, they could:

- Serve a modified version of the app that exfiltrates data
- Prevent updates from reaching the user
- Modify displayed weights (dangerous in a strength training context — wrong weight could cause injury)

However, service worker registration requires HTTPS (enforced by browsers) and same-origin. The attack requires either:
- Compromising the hosting server
- Compromising the HTTPS certificate
- A bug in the service worker update logic

This is not unique to this app — it is the standard PWA threat model.

### 4.2 Stale-While-Revalidate for index.html

**Risk: Low.** The strategy serves the cached `index.html` immediately and checks for updates in the background. The update check is an HTTPS fetch to the same origin. A MITM attacker who could break HTTPS could serve a malicious `index.html`, but HTTPS compromise is outside the app's threat model.

**One concern:** If the hosting server is compromised, the stale-while-revalidate strategy means users will eventually get the compromised version. The PRD's update flow (toast notification, user-initiated reload) is the correct pattern — do NOT auto-apply updates via `skipWaiting()`.

### 4.3 Subresource Integrity (SRI)

**Not necessary for v1.** SRI protects against CDN compromise — it verifies that fetched resources match expected hashes. Since this PWA:
- Serves all assets from the same origin (no CDN)
- Uses content-hashed filenames (`app.[hash].js`) from the Vite build
- Caches assets with a cache-first strategy

...the attack that SRI defends against (CDN serves tampered file) does not apply. The content hash in the filename already provides integrity verification for cache-busting purposes.

**Recommendation:** Skip SRI for v1. If the app later uses a CDN, revisit.

### 4.4 Phishing Clone

**Risk: Very Low.** An attacker could host a copy of the PWA at a different domain. But there are no credentials to steal, no accounts to compromise, and no backend to impersonate. The worst case is someone entering their 1RM data into a fake app — not a meaningful attack. No action needed.

---

## 5. IndexedDB Security

### 5.1 Same-Origin Access

IndexedDB is scoped to the origin (scheme + host + port). Any JavaScript running on the same origin can read/write the database. In a PWA context, this means:

- **Browser extensions** with appropriate permissions can access IndexedDB. This is a browser-level concern, not an app-level concern.
- **XSS** — if an attacker can execute JavaScript on the origin, they can read all IndexedDB data. This is why input sanitization (Section 6) matters.
- **Other PWAs on the same origin** — not applicable unless the user hosts multiple apps on the same domain, which would be a deployment error.

### 5.2 Encryption at Rest

**Not recommended for v1.** Encrypting IndexedDB data at rest would protect against:
- Physical device access (attacker opens DevTools)
- Forensic analysis of device storage

But the threat model does not support this investment:
- The data is fitness performance numbers, not PII or financial data
- iOS device encryption already protects data at rest when the device is locked
- Client-side encryption without a server-held key means the encryption key must be stored on the same device — an attacker with physical access can find it
- Adding encryption would complicate the export/import flow and debugging

**Recommendation:** Do not encrypt IndexedDB. Rely on device-level encryption.

### 5.3 Cross-Origin Isolation

Cross-origin isolation (`COOP`/`COEP` headers) is relevant for SharedArrayBuffer access and Spectre mitigations. This app does not use SharedArrayBuffer and does not process cross-origin data. Cross-origin isolation headers are not needed.

---

## 6. Input Validation & Injection

### 6.1 Numeric Inputs (Weight, Reps)

**Risk: Negligible.** Numeric inputs rendered with `inputmode="numeric"` or `inputmode="decimal"` constrain the soft keyboard but do not prevent programmatic input. However, these values are only used in arithmetic (Epley formula, plate calculation) and displayed as text, never interpreted as code.

**Required validation:**
- Weight: positive number, 1-1500, round to 0.25 granularity
- Reps: positive integer, 1-15
- Barbell weight: positive number, 15-100
- Plate quantities: non-negative integer, 0-20
- Rest timer: non-negative integer, 0-600

**Implementation:** Validate on input change (for immediate feedback) AND before writing to IndexedDB (as a safety net). Use `Number()` or `parseFloat()`, check `isNaN()`, clamp to range. Never use `eval()` or `new Function()` to process numeric input.

### 6.2 Free-Text Inputs (Session Notes)

**Risk: Low if Preact JSX is used correctly.**

Session notes are stored in IndexedDB and rendered in the History view. If rendered via Preact JSX (`{note}` in a template), Preact automatically escapes HTML entities. This is safe.

**What would be unsafe:**
- `element.innerHTML = note` — allows script injection
- `dangerouslySetInnerHTML={{ __html: note }}` — bypasses Preact's escaping
- Using notes in a URL without encoding — `window.location = '/search?q=' + note`

**Required sanitization:**
- Max length: 500 characters (prevent storage bloat from import)
- Render via Preact JSX only — never innerHTML
- If notes are ever included in exported HTML or shared context, HTML-encode them

### 6.3 JSON Import

Covered in Section 2. The key points:
- `JSON.parse()` only
- Schema validation with allowlisted keys
- Prototype pollution defense (reject `__proto__`, `constructor`, `prototype` keys)
- File size limit (1MB)
- Numeric range validation on all imported numbers
- String length limits on all imported strings

### 6.4 Template Selection (Dropdown)

**Risk: None.** Template IDs are an enum selected from a hardcoded list. The value is compared against known IDs. No injection vector.

---

## 7. Privacy Considerations

### 7.1 Service Worker Cache Visibility

The service worker cache stores `index.html` and hashed JS/CSS assets. It does NOT store user data — IndexedDB handles all data persistence. The cache contents reveal that the user has this PWA installed and which version they are running, but not their training data.

**Risk: Negligible.** Someone with DevTools access can see the app is installed, but they could also just look at the home screen.

### 7.2 Reconstructing Training History from Cache

**Not possible.** The service worker caches static assets (HTML, JS, CSS), not user data. Training history lives in IndexedDB, which is a separate storage mechanism. Clearing the cache does not affect data; clearing data does not affect the cache.

### 7.3 GDPR / Privacy Implications

This app stores data exclusively on the user's device with no server communication. Under GDPR:

- **No data controller/processor relationship** — the app developer never receives, processes, or stores user data. There is no server.
- **Local storage exemption** — data stored locally on a user's own device by the user is not "processing" in the GDPR sense. The app is a tool, like a calculator.
- **Health data consideration** — 1RM values and session notes could be considered "data concerning health" under GDPR Article 9 if they reveal information about physical condition. However, since the data never leaves the device and there is no data controller, GDPR obligations are minimal.

**Recommendation:** Include a brief privacy statement in the app (Settings > About):
- "All data is stored locally on your device. No data is sent to any server. We do not collect, process, or have access to your training data."
- This is both accurate and builds user trust.

### 7.4 "Clear All Data" Action

**Recommended for v1.** Users should be able to delete all their data. This is:
- A basic user expectation
- A GDPR right (right to erasure, even though it is locally stored)
- Useful for shared device scenarios

**Implementation:** Settings > "Delete All Data" button with two-step confirmation:
1. Tap "Delete All Data"
2. Confirmation dialog: "This will permanently delete all your training data, history, and settings. This cannot be undone. Are you sure?"
3. On confirm: clear IndexedDB, clear localStorage, unregister service worker, navigate to onboarding

---

## 8. Shared Device Security

### 8.1 Can One User See Another's Data?

**Yes.** IndexedDB is scoped to the origin, not to the user. If two people use the same browser on the same device, they share the same IndexedDB data. This is the standard web storage model — it is not a bug in this app.

### 8.2 Should There Be a PIN Lock?

**Not for v1.** A PIN lock would protect against casual snooping but adds significant complexity:
- Where do you store the PIN? (Cannot be in IndexedDB — that is what we are protecting)
- PIN hashing and verification logic
- What happens if the user forgets the PIN?
- False sense of security — a technical user can bypass it via DevTools

The data sensitivity does not justify this investment. Squat maxes are not secrets.

**Recommendation:** Defer PIN/biometric to v1.1 only if users request it. For v1, the shared device scenario is adequately addressed by:
- The "Clear All Data" feature (user can wipe before handing device to someone)
- iOS device-level passcode (the primary access control)

### 8.3 Realistic Concern Assessment

For v1, shared device access is the most realistic "threat" but the impact is low (someone sees your training numbers). The cost of mitigation (PIN system) is disproportionate to the risk. Document the limitation; move on.

---

## 9. Supply Chain & Build Security

### 9.1 Dependency Analysis

The PRD specifies:
- **Preact 10.x** (~4KB gzipped) — well-maintained, small attack surface
- **Vite** (build tool only, not shipped to client) — dev dependency, not a runtime risk
- **idb-keyval** (~600 bytes gzipped) — tiny IndexedDB wrapper by Jake Archibald (Google Chrome team). Minimal code, well-audited.
- **Preact Signals** (~1KB gzipped) — state management, same team as Preact

This is an exceptionally small dependency tree. The total shipped runtime is roughly 3 packages. Contrast this with a typical React app that ships 50+ transitive dependencies.

**Risk: Low.** The small dependency count significantly limits supply chain exposure.

### 9.2 Dependency Pinning

**Recommended:** Use exact versions in `package.json` (not ranges like `^10.0.0`) and commit `package-lock.json` or equivalent lockfile. This ensures reproducible builds and prevents auto-upgrading to a compromised version.

**Optional but worthwhile:** Run `npm audit` in CI. The small dependency tree makes this fast and noise-free.

### 9.3 Build Artifact Integrity

Vite produces content-hashed output files (`app.a1b2c3.js`). The hash in the filename is derived from the file content. This provides:
- Cache-busting (changed content = new filename)
- Implicit integrity verification (if the file content does not match the hash, the browser requests the correct file)

**Recommendation:** Standard Vite build pipeline is sufficient. No additional integrity measures needed for v1.

---

## 10. Specific Recommendations

Numbered and prioritized by risk level. These are concrete requirements to add to the PRD or implementation checklist.

### High Priority

**H1. JSON Import: Schema validation with prototype pollution defense.**
Validate all imported JSON against an allowlist schema. Recursively reject objects containing `__proto__`, `constructor`, or `prototype` keys. Use `JSON.parse()` only. Enforce 1MB file size limit.
*Rationale: Import is the highest-risk input vector. A crafted file could corrupt app state or, in the worst case, achieve XSS if combined with unsafe rendering.*

**H2. JSON Import: Numeric range validation on all imported values.**
Apply the same min/max constraints to imported data as to manual input (weight 1-1500, reps 1-15, etc.). Reject the entire import if any value fails validation, with a specific error message.
*Rationale: Prevents data corruption from malformed imports. Also guards against unreasonable values that could break the plate calculator or produce misleading weights.*

**H3. Never use innerHTML or dangerouslySetInnerHTML for user-supplied strings.**
All user-supplied content (session notes, imported text fields) must be rendered via Preact JSX templating only, which escapes HTML by default. Add this as a code review rule.
*Rationale: This is the only realistic XSS vector in the application. Preact is safe by default, but one careless `innerHTML` call breaks the guarantee.*

**H4. JSON Import: Confirmation prompt before overwriting data.**
Show the user what the import contains (number of lifts, sessions, date range) and require explicit confirmation before replacing existing data. Offer "Export current data first?" as a safety net.
*Rationale: Prevents accidental data loss from importing the wrong file.*

**H5. URL-encoded 1RM recovery: Validate decoded values before writing.**
Apply numeric range validation (weight 1-1500, lift name must be one of the 5 known lifts) to any values decoded from the URL hash. Show a confirmation prompt with the decoded values before writing to IndexedDB.
*Rationale: Prevents a crafted URL from injecting invalid data into the app.*

### Medium Priority

**M1. Add "Delete All Data" to Settings.**
Two-step confirmation. Clears IndexedDB, localStorage, and optionally unregisters the service worker. Required for privacy and shared device scenarios.
*Rationale: Users should be able to wipe their data. Basic privacy expectation.*

**M2. Pin dependency versions.**
Use exact versions in `package.json` and commit the lockfile. Run `npm audit` in CI.
*Rationale: Small dependency tree means low risk, but pinning is cheap insurance against supply chain attacks.*

**M3. Service worker: Do not auto-apply updates via skipWaiting().**
The PRD already specifies this correctly (Section 6.5). Reinforcing here: the user must explicitly trigger the update. This prevents a compromised update from silently replacing the app.
*Rationale: Already in the PRD. Flagging for implementation emphasis.*

**M4. Add a privacy statement to the About section.**
"All data is stored locally on your device. No data is sent to any server." Brief, accurate, builds trust.
*Rationale: Users of health-adjacent apps increasingly expect privacy transparency.*

**M5. Session notes: Enforce 500-character max length.**
Both in the UI (character counter + truncation) and in the import validator.
*Rationale: Prevents storage bloat from import and limits the surface area of any text-rendering bugs.*

**M6. Content Security Policy (CSP) header.**
Deploy with a strict CSP: `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'`. No `eval`, no inline scripts, no external resources. This is the single most effective XSS mitigation.
*Rationale: Defense-in-depth. Even if an XSS vector exists in the code, CSP prevents exploitation in most cases.*

### Low Priority

**L1. Service worker cache: Version-prefix and purge stale caches.**
The PRD mentions `CACHE_VERSION` (Section 6.5). Ensure the activation handler deletes all caches not matching the current version. This is standard practice.
*Rationale: Prevents stale cache accumulation. Minor hygiene, not a security risk.*

**L2. Export: Note in UI that the file is unencrypted.**
Brief text near the Export button: "Your data is exported as unencrypted JSON."
*Rationale: User awareness. Not a significant risk given data sensitivity.*

**L3. URL 1RM recovery: Note in UI that the URL contains your lift data.**
"This URL contains your lift maxes. Anyone with the URL can see these values."
*Rationale: Informed consent for the URL bookmark feature.*

**L4. Do not store anything in cookies beyond the eviction detection flag.**
The PRD uses a `tb3_active=1` cookie for storage eviction detection (Section 6.6). This is fine. Ensure no user data is ever written to cookies, which are sent with HTTP requests.
*Rationale: Cookies travel over the network. IndexedDB does not.*

**L5. HTTPS-only deployment.**
Service workers already require HTTPS (except localhost). Ensure the production deployment uses HTTPS with HSTS. This is table-stakes for any web application.
*Rationale: Prevents MITM on the initial load and service worker registration.*

**L6. Sanitize hash-based route values.**
The router reads `window.location.hash` for navigation (`/#/home`, `/#/program/week/3`). Validate that route segments match expected patterns (alphanumeric, known paths). Do not use hash values in DOM operations without validation.
*Rationale: Low risk in practice (Preact's JSX escaping handles rendering), but defense-in-depth for the routing layer.*

**L7. Import: Reject unexpected top-level keys in JSON.**
Only accept known keys from the `AppData` interface. Strip or reject anything else. This supplements the prototype pollution defense (H1) with a general allowlist approach.
*Rationale: Reduces attack surface of the import parser.*

---

## Summary Risk Matrix

| Area | Risk Level | Key Mitigation |
|---|---|---|
| JSON Import (crafted file) | **Medium** | Schema validation, prototype pollution defense, size limit, confirmation prompt |
| XSS via session notes | **Low** (if Preact JSX used correctly) | Never use innerHTML; CSP header |
| URL 1RM recovery | **Low** | Validate decoded values, confirmation prompt |
| Service worker compromise | **Low** | HTTPS, no skipWaiting(), cache versioning |
| IndexedDB access | **Low** | Same-origin policy (browser-enforced); no encryption needed |
| Shared device data exposure | **Low** | "Delete All Data" feature; document limitation |
| Supply chain | **Low** | Small dependency tree, version pinning, npm audit |
| Phishing clone | **Very Low** | No action needed — no credentials to steal |

---

## Appendix: What This App Gets Right by Design

It is worth noting the security decisions already embedded in the PRD that significantly reduce the attack surface:

1. **No backend, no auth, no network communication** — eliminates entire classes of vulnerabilities (CSRF, session hijacking, API abuse, server-side injection, credential stuffing)
2. **No external CDN or third-party scripts** — eliminates CDN compromise and third-party tracking
3. **Minimal dependency tree** (Preact + idb-keyval + Signals) — limits supply chain risk
4. **Hash-based routing** — avoids server configuration issues with client-side routing
5. **Content-hashed asset filenames** — provides cache integrity
6. **No user accounts** — eliminates account takeover, password storage, session management
7. **Explicit user-triggered updates** (no skipWaiting) — prevents silent code replacement

The application's "no network after load" architecture is its strongest security property. Most web application vulnerabilities require a server or external data source. This app has neither.
