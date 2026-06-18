# Feature Specification — User Authentication

## User Story
As a registered user, I want to log in securely using my email and password so that I can
access my personal dashboard and data.

## Requirements
1. Users must be able to log in with a valid email and password
2. Failed login attempts must be limited to 5 before the account is temporarily locked
3. Passwords must be stored using bcrypt hashing — never in plain text
4. A successful login must return a JWT token valid for 24 hours
5. Users must be able to log out, which invalidates their token
6. All authentication endpoints must be served over HTTPS only
7. An audit log entry must be created for every login attempt (success and failure)

## Acceptance Criteria
- [ ] POST /auth/login accepts email + password and returns a JWT on success
- [ ] POST /auth/login returns HTTP 401 with a generic error message on failure
- [ ] After 5 failed attempts, the account is locked for 15 minutes
- [ ] POST /auth/logout invalidates the current JWT
- [ ] Passwords are never stored or logged in plain text
- [ ] Every login attempt is recorded in the audit_log table with timestamp, user ID, and outcome
- [ ] All endpoints reject HTTP (non-TLS) requests

## Testing Scenarios
- Scenario 1: Valid credentials → 200 + JWT returned
- Scenario 2: Wrong password → 401, attempt counter incremented
- Scenario 3: 5th failed attempt → account locked, 423 returned
- Scenario 4: Locked account attempt → 423 with unlock time in response
- Scenario 5: Valid logout → token invalidated, subsequent requests with same token return 401
- Scenario 6: Audit log entries verified after each scenario

## Open Questions
- Should locked accounts receive an email notification? (not yet decided)
- What is the token refresh strategy — silent refresh or re-login?
