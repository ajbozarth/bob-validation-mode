# Project Constitution — Auth Service

## Tech Stack
- Language: TypeScript (Node.js)
- Framework: Express.js
- Database: PostgreSQL
- ORM: Prisma
- Testing framework: Jest
- API style: REST (no GraphQL)
- Authentication: JWT (jsonwebtoken library)
- Password hashing: bcrypt

## Coding Standards
- All files must use TypeScript strict mode (`"strict": true` in tsconfig)
- Functions must be named (no anonymous arrow functions at module level)
- No `any` types — use proper interfaces or unknown
- Error messages returned to clients must be generic (never expose stack traces or internals)
- All environment variables must be accessed via a validated config module — no direct `process.env` calls in business logic

## Testing Standards
- Unit test coverage minimum: 80%
- Integration tests required: yes — for all API endpoints
- E2E tests required: no (out of scope for this service)
- Tests must not make real network calls — use mocks for external dependencies

## Security & Compliance Guardrails
- No hardcoded secrets, API keys, or credentials anywhere in the codebase
- Passwords must never be logged, stored in plain text, or included in API responses
- All endpoints must validate and sanitise input before processing
- JWT secret must be loaded from environment variable, not hardcoded
- HTTPS only — HTTP requests must be rejected at the application level
- SQL queries must use parameterised statements (Prisma handles this — no raw query strings)

## Architecture Decisions (ADRs)
- ADR-001: Use Prisma over raw SQL for all database access — enforces type safety and prevents injection
- ADR-002: JWT stored in httpOnly cookie, not localStorage — reduces XSS attack surface
- ADR-003: Account lockout is enforced server-side in the database — not in-memory — to survive restarts
