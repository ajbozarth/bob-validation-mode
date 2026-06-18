**User:** validate against requirements in the folder sample

---

**Bob:** Calling tools

---

---

---

---

---

---

**Bob:** Now I have all four documents. Let me activate the relevant validation skills and run the full cross-check.

---

---

---

---

**Bob:** All three skills loaded. Now executing the full validation pass against [`tasks.md`](sample/tasks.md), [`plan.md`](sample/plan.md), [`spec.md`](sample/spec.md), and [`constitution.md`](sample/constitution.md).

---

## Requirements Coverage Check

**Artifact:** `tasks.md` + `plan.md` (implementation artifacts)
**Source:** `spec.md`

### Requirements

| # | Requirement | Verdict | Evidence / Notes |
|---|---|---|---|
| 1 | Users must be able to log in with valid email and password | ✅ Covered | Phase 2 tasks: validate email + password, query users table; plan Phase 2 section |
| 2 | Failed login attempts limited to **5** before temporary lock | ❌ Missing | `tasks.md` Phase 3 says **3** failed attempts — spec.md says **5**. Direct contradiction. |
| 3 | Passwords stored using bcrypt — never in plain text | ✅ Covered | `tasks.md`: "compare password using bcrypt"; `plan.md` data model: `password_hash VARCHAR (bcrypt hash)` |
| 4 | Successful login returns a JWT valid for **24 hours** | ⚠️ Partial | `tasks.md`: "Issue JWT token on success" — no token expiry (24h) specified anywhere |
| 5 | Users must be able to log out, invalidating their token | ✅ Covered | `tasks.md` Phase 4; `plan.md` Phase 4 and diagram |
| 6 | All endpoints must be served over HTTPS only | ❌ Missing | Not mentioned in `tasks.md` or `plan.md` — no HTTPS enforcement task or design note exists |
| 7 | Audit log entry for every login attempt (success and failure) | ⚠️ Partial | `plan.md` data model includes `audit_log` table; `tasks.md` has no task to write audit log entries |

### Acceptance Criteria

| # | Criterion | Verdict | Evidence / Notes |
|---|---|---|---|
| 1 | POST /auth/login accepts email + password, returns JWT on success | ✅ Covered | Phase 2 tasks cover all three steps |
| 2 | POST /auth/login returns HTTP 401 with generic error on failure | ⚠️ Partial | Input validation task exists; no task for 401 response shape or generic error message requirement |
| 3 | After **5** failed attempts, account locked for 15 minutes | ❌ Missing | `tasks.md` says **3** attempts — conflicts with spec. 15-minute lock duration is correct in Phase 3. |
| 4 | POST /auth/logout invalidates the current JWT | ✅ Covered | Phase 4: "Remove JWT cookie on logout" — cookie removal is the invalidation mechanism |
| 5 | Passwords never stored or logged in plain text | ✅ Covered | bcrypt hash stored; password_hash column in data model |
| 6 | Every login attempt recorded in audit_log with timestamp, user ID, outcome | ⚠️ Partial | `audit_log` schema exists in `plan.md`; no task in `tasks.md` to actually write audit log records |
| 7 | All endpoints reject HTTP (non-TLS) requests | ❌ Missing | Not addressed in tasks or plan |

**Coverage Summary:**
- Total requirements: 7 + 7 AC = 14
- Fully covered: 6
- Partial: 4
- Missing: 4
- Coverage score: **43% (6/14)**

---

## Constitution Compliance Check

**Artifact:** `tasks.md` + `plan.md`
**Source:** `constitution.md`

### Tech Stack
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ✅ Compliant | TypeScript (Node.js) | TypeScript used | plan.md line 4 |
| ✅ Compliant | Express.js | Express.js stated in plan approach | plan.md line 4 |
| ✅ Compliant | PostgreSQL | PostgreSQL stated | plan.md line 5 |
| ✅ Compliant | Prisma ORM | "Prisma used for all DB access" cited | plan.md line 11 |
| ✅ Compliant | JWT (jsonwebtoken library) | Explicitly named in tasks | tasks.md line 13 |
| ✅ Compliant | bcrypt | Explicitly named in tasks | tasks.md line 12 |
| ✅ Compliant | REST (no GraphQL) | REST endpoints only defined | plan.md lines 4–5 |

### Coding Standards
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ⚠️ Warning | TypeScript strict mode | Not referenced in tasks or plan — no tsconfig task or note | tasks.md (absent) |
| ⚠️ Warning | No `any` types | Not addressed in plan or tasks — no note on type strictness | plan.md (absent) |
| ⚠️ Warning | Generic error messages to clients | Phase 2 validation task exists but no explicit task for generic error responses | tasks.md Phase 2 |
| ⚠️ Warning | All env vars via validated config module — no `process.env` in business logic | `tasks.md` line 14: "Store JWT secret in **process.env.JWT_SECRET**" — direct `process.env` reference, no config module mentioned | tasks.md line 14 |

### Testing Standards
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ⚠️ Warning | Unit test coverage ≥ 80% | tasks.md Phase 5 includes unit tests but states no coverage target | tasks.md Phase 5 |
| ❌ Error | Integration tests required for all API endpoints | tasks.md Phase 5 lists only unit tests — no integration test tasks | tasks.md Phase 5 |
| 💡 Suggestion | Tests must not make real network calls (mocks) | No mention of test strategy or mocking approach | tasks.md Phase 5 |

### Security & Compliance
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ✅ Compliant | No hardcoded secrets | No hardcoded secrets present | All sections |
| ✅ Compliant | Passwords never logged/stored in plain text | bcrypt enforced throughout | tasks.md, plan.md |
| ✅ Compliant | SQL via parameterised statements (Prisma) | Prisma cited as sole DB access layer | plan.md line 11 |
| ⚠️ Warning | All endpoints validate and sanitise input | Input validation listed for login; logout has no validation task | tasks.md Phase 2 vs Phase 4 |
| ❌ Error | HTTPS only — HTTP must be rejected at application level | No HTTPS enforcement anywhere in tasks or plan | tasks.md, plan.md (absent) |
| ⚠️ Warning | JWT secret loaded from env var, not hardcoded | `tasks.md` line 14 says "Store JWT secret in `process.env.JWT_SECRET`" — correctly using env var but via direct `process.env`, not a config module (violates coding standards too) | tasks.md line 14 |

### Architecture Decisions
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ✅ Compliant | ADR-001: Prisma for all DB access | plan.md explicitly cites ADR-001 | plan.md line 11 |
| ✅ Compliant | ADR-002: JWT in httpOnly cookie | plan.md explicitly cites ADR-002 | plan.md line 9 |
| ✅ Compliant | ADR-003: Account lockout in database (not in-memory) | plan.md explicitly cites ADR-003; `failed_attempts` in DB schema | plan.md line 10, data model |

**Compliance Summary:**
- Total guardrails checked: 17
- Compliant: 9
- Errors: 2
- Warnings: 6
- Suggestions: 1

---

## Score Calculation

| Deduction Source | Count | Points |
|---|---|---|
| ❌ Missing requirements (×15) | 4 | −60 |
| ❌ Constitution errors (×10) | 2 | −20 |
| ⚠️ Partial requirements (×5) | 4 | −20 |
| ⚠️ Constitution warnings (×3) | 6 | −18 |
| 💡 Suggestions (×1) | 1 | −1 |
| **Starting score** | — | 100 |
| **Total deductions** | — | −119 |
| **Confidence Score (floor 0)** | — | **0** |

Coverage Score: **43% (6/14)**

---

Now writing the report to disk.

---

---

**Bob:** Report written to [`validation-report.md`](validation-report.md).

---

# Requirements Cross-Check Report

**Artifact:** `sample/tasks.md` + `sample/plan.md`
**Validated against:** `sample/spec.md` · `sample/constitution.md`
**Date:** 2025-07-14

---

## Requirements Coverage

| # | Requirement | Verdict | Notes |
|---|---|---|---|
| 1 | Log in with valid email and password | ✅ Covered | Phase 2 tasks fully address this |
| 2 | Failed attempts limited to **5** before lock | ❌ Missing | [`tasks.md` line 18](sample/tasks.md) says **3** — spec says **5**. Direct contradiction. |
| 3 | Passwords stored using bcrypt, never plain text | ✅ Covered | bcrypt in tasks + `password_hash` in data model |
| 4 | JWT valid for **24 hours** | ⚠️ Partial | JWT issuance is tasked; expiry duration not specified anywhere |
| 5 | Logout invalidates token | ✅ Covered | Phase 4 tasks + plan diagram |
| 6 | All endpoints over HTTPS only | ❌ Missing | No task or design note anywhere |
| 7 | Audit log for every login attempt | ⚠️ Partial | Schema exists in plan; no task to write records |

| # | Acceptance Criterion | Verdict | Notes |
|---|---|---|---|
| 1 | POST /auth/login returns JWT on success | ✅ Covered | Phase 2 |
| 2 | POST /auth/login returns 401 with generic error | ⚠️ Partial | Validation tasked; 401 response shape not specified |
| 3 | After **5** failures → 15-min lock | ❌ Missing | [`tasks.md` line 18](sample/tasks.md): threshold is **3**, not 5 |
| 4 | POST /auth/logout invalidates JWT | ✅ Covered | Phase 4 |
| 5 | Passwords never stored/logged in plain text | ✅ Covered | bcrypt throughout |
| 6 | Audit log with timestamp, user ID, outcome | ⚠️ Partial | No write task |
| 7 | All endpoints reject HTTP | ❌ Missing | Not addressed |

**Coverage: 6 fully met · 4 partial · 4 missing**

---

## Constitution Compliance — Key Findings

| Severity | Area | Finding |
|---|---|---|
| ✅ Compliant | Tech Stack | All 7 stack guardrails met (TS, Express, PostgreSQL, Prisma, JWT, bcrypt, REST) |
| ✅ Compliant | ADRs | All 3 ADRs explicitly cited in `plan.md` |
| ❌ Error | Testing | No integration test tasks — constitution requires integration tests for all API endpoints |
| ❌ Error | Security | No HTTPS enforcement task or design note — constitution requires HTTP rejection at app level |
| ⚠️ Warning | Coding Standards | [`tasks.md` line 14](sample/tasks.md): `process.env.JWT_SECRET` used directly — constitution requires a validated config module |
| ⚠️ Warning | Coding Standards | TypeScript strict mode, no-`any` policy not referenced in tasks or plan |
| ⚠️ Warning | Testing | No coverage target stated — constitution mandates ≥ 80% |
| ⚠️ Warning | Security | No input validation/sanitisation task for POST /auth/logout |
| 💡 Suggestion | Testing | No mocking strategy mentioned |

---

## Fix Priority

1. ❌ **Req 2 / AC 3** — Change failed-attempt threshold from **3 → 5** in [`tasks.md` Phase 3](sample/tasks.md)
2. ❌ **Req 6 / AC 7** — Add HTTPS enforcement task (`tasks.md`) and design note (`plan.md`)
3. ❌ **Constitution Error** — Add integration test tasks to Phase 5 for `/auth/login` and `/auth/logout`
4. ⚠️ **Req 7 / AC 6** — Add task to write audit log entries on every login attempt
5. ⚠️ **Req 4** — Specify JWT 24-hour expiry in Phase 2 task or plan data model
6. ⚠️ **AC 2** — Add task: return HTTP 401 with generic error message on failed login
7. ⚠️ **Constitution** — Replace `process.env.JWT_SECRET` with config module call in [`tasks.md` line 14](sample/tasks.md)
8. ⚠️ **Constitution** — Add tsconfig strict mode note and coverage target (≥ 80%) to Phase 5
9. 💡 Add mocking strategy note to testing phase

---

## Overall

| Metric | Score |
|---|---|
| Coverage Score | **43% (6/14)** |
| Confidence Score | **0 / 100** |

**Verdict:** Significant gaps — must resolve errors and missing requirements before proceeding.

---

**Top 3 next actions:**
1. Fix the lockout threshold — [`tasks.md` line 18](sample/tasks.md) must say **5** attempts, not 3.
2. Add HTTPS enforcement — add a task and a plan note; this is both a missing requirement and a constitution security error.
3. Add integration test tasks to Phase 5 — required by constitution for all API endpoints.

---

**User:** now can you help me save the chat history

---

**Bob:** What format would you like to save the chat history in?

---

---
