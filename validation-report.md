# Requirements Cross-Check Report

**Artifact:** `sample/tasks.md` + `sample/plan.md` (implementation plan and task list)  
**Validated against:** `sample/spec.md` · `sample/constitution.md`  
**Date:** 2025-07-14

---

## Requirements Coverage

| # | Requirement | Verdict | Notes |
|---|---|---|---|
| 1 | Users must be able to log in with valid email and password | ✅ Covered | Phase 2 tasks: validate email + password, query users table; plan Phase 2 section |
| 2 | Failed login attempts limited to **5** before temporary lock | ❌ Missing | `tasks.md` Phase 3 says **3** failed attempts — spec.md mandates **5**. Direct contradiction. |
| 3 | Passwords stored using bcrypt — never in plain text | ✅ Covered | `tasks.md`: "compare password using bcrypt"; data model has `password_hash VARCHAR (bcrypt hash)` |
| 4 | Successful login returns JWT valid for **24 hours** | ⚠️ Partial | JWT issuance is tasked; 24-hour expiry is not specified anywhere in tasks or plan |
| 5 | Users must be able to log out, invalidating their token | ✅ Covered | `tasks.md` Phase 4; plan.md Phase 4 and diagram |
| 6 | All endpoints served over HTTPS only | ❌ Missing | Not mentioned in `tasks.md` or `plan.md` — no HTTPS enforcement task or design note |
| 7 | Audit log entry for every login attempt (success and failure) | ⚠️ Partial | `audit_log` table in data model; no task in `tasks.md` to actually write audit log records |

| # | Acceptance Criterion | Verdict | Notes |
|---|---|---|---|
| 1 | POST /auth/login accepts email + password, returns JWT on success | ✅ Covered | Phase 2 tasks cover all three steps |
| 2 | POST /auth/login returns HTTP 401 with generic error on failure | ⚠️ Partial | Input validation tasked; no task for 401 response shape or generic error message |
| 3 | After **5** failed attempts, account locked for 15 minutes | ❌ Missing | `tasks.md` says **3** attempts — direct conflict with spec (5). Lock duration is correct. |
| 4 | POST /auth/logout invalidates the current JWT | ✅ Covered | Phase 4: "Remove JWT cookie on logout" |
| 5 | Passwords never stored or logged in plain text | ✅ Covered | bcrypt hash in data model; bcrypt compare in tasks |
| 6 | Every login attempt recorded in audit_log with timestamp, user ID, outcome | ⚠️ Partial | Schema defined in plan.md; no task exists to write audit records |
| 7 | All endpoints reject HTTP (non-TLS) requests | ❌ Missing | Not addressed in tasks or plan |

**Coverage: 6 fully met · 4 partial · 4 missing**

---

## Constitution Compliance

### Tech Stack
| Severity | Guardrail | Finding |
|---|---|---|
| ✅ Compliant | TypeScript (Node.js) | TypeScript stated in plan approach |
| ✅ Compliant | Express.js | Express.js stated in plan |
| ✅ Compliant | PostgreSQL | PostgreSQL stated in plan |
| ✅ Compliant | Prisma ORM | "Prisma used for all DB access" in plan.md |
| ✅ Compliant | JWT (jsonwebtoken library) | Explicitly named in tasks.md |
| ✅ Compliant | bcrypt | Explicitly named in tasks.md |
| ✅ Compliant | REST (no GraphQL) | REST endpoints only |

### Coding Standards
| Severity | Guardrail | Finding |
|---|---|---|
| ⚠️ Warning | TypeScript strict mode | Not referenced in tasks or plan — no tsconfig task or note |
| ⚠️ Warning | No `any` types | Not addressed — no note on type strictness |
| ⚠️ Warning | Generic error messages to clients | No explicit task to return generic (non-internal) error messages |
| ⚠️ Warning | Env vars via validated config module — no direct `process.env` in business logic | `tasks.md` line 14: "Store JWT secret in `process.env.JWT_SECRET`" — direct `process.env` reference, no config module mentioned |

### Testing Standards
| Severity | Guardrail | Finding |
|---|---|---|
| ⚠️ Warning | Unit test coverage ≥ 80% | Unit tests tasked but no coverage target stated |
| ❌ Error | Integration tests required for all API endpoints | Phase 5 lists only unit tests — zero integration test tasks present |
| 💡 Suggestion | Tests must not make real network calls (use mocks) | No mention of mocking strategy |

### Security & Compliance
| Severity | Guardrail | Finding |
|---|---|---|
| ✅ Compliant | No hardcoded secrets | None found |
| ✅ Compliant | Passwords never logged/stored in plain text | bcrypt enforced throughout |
| ✅ Compliant | SQL via parameterised statements (Prisma) | Prisma is the sole DB access layer |
| ⚠️ Warning | All endpoints validate and sanitise input | Input validation tasked for login; logout endpoint has no validation task |
| ❌ Error | HTTPS only — HTTP rejected at application level | No HTTPS enforcement task or design note anywhere |
| ⚠️ Warning | JWT secret from env var, not hardcoded | tasks.md line 14 uses `process.env.JWT_SECRET` directly — env var is correct, but it bypasses the required config module |

### Architecture Decisions
| Severity | Guardrail | Finding |
|---|---|---|
| ✅ Compliant | ADR-001: Prisma for all DB access | plan.md explicitly cites ADR-001 |
| ✅ Compliant | ADR-002: JWT in httpOnly cookie | plan.md explicitly cites ADR-002 |
| ✅ Compliant | ADR-003: Account lockout in database (not in-memory) | plan.md cites ADR-003; `failed_attempts` column in DB schema |

---

## Fix Priority

1. ❌ **Missing Requirement** — Change failed-attempt threshold from 3 to **5** in `tasks.md` Phase 3 (spec.md req 2, AC 3)
2. ❌ **Missing Requirement** — Add HTTPS enforcement task to `tasks.md` and a design note to `plan.md` (spec.md req 6, AC 7)
3. ❌ **Constitution Error** — Add integration test tasks to Phase 5 for all API endpoints (`/auth/login`, `/auth/logout`)
4. ❌ **Constitution Error** — Add HTTPS-only enforcement to plan.md architecture section (constitution security guardrail)
5. ⚠️ **Partial Requirement** — Add task to write audit log entries on every login attempt (spec.md req 7, AC 6)
6. ⚠️ **Partial Requirement** — Specify JWT 24-hour expiry in the Phase 2 task or plan data model (spec.md req 4)
7. ⚠️ **Partial Requirement** — Add task for HTTP 401 response with generic error message (AC 2)
8. ⚠️ **Constitution Warning** — Replace `process.env.JWT_SECRET` direct access with a config module call (constitution coding standard + security guardrail)
9. ⚠️ **Constitution Warning** — Add tsconfig strict mode and no-`any` notes to plan or a separate setup task
10. ⚠️ **Constitution Warning** — Add unit test coverage target (≥ 80%) to Phase 5 tasks
11. ⚠️ **Constitution Warning** — Add input validation/sanitisation task for POST /auth/logout
12. 💡 **Suggestion** — Add a note on mocking strategy for tests (no real network calls)

---

## Overall

| Metric | Score |
|---|---|
| Coverage Score | 43% (6/14 requirements fully met) |
| Confidence Score | 0/100 |

**Verdict:** Significant gaps — must resolve errors and missing requirements before proceeding.
