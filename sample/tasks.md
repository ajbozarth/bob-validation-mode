# Tasks — User Authentication

## Phase 1: Project Setup
- [x] Initialise TypeScript + Express project
- [x] Configure Prisma with PostgreSQL connection
- [x] Define users and audit_log schema in schema.prisma
- [x] Set up Jest for unit testing

## Phase 2: Login Endpoint
- [ ] Create POST /auth/login route
- [ ] Validate email + password input
- [ ] Query users table and compare password using bcrypt
- [ ] Issue JWT token on success using the `jsonwebtoken` library
- [ ] Store JWT secret in process.env.JWT_SECRET

## Phase 3: Account Lockout
- [ ] Track failed_attempts in users table
- [ ] Lock account for 15 minutes after 3 failed attempts
- [ ] Return HTTP 423 with unlock time when account is locked

## Phase 4: Logout
- [ ] Create POST /auth/logout route
- [ ] Remove JWT cookie on logout

## Phase 5: Testing
- [ ] Write unit tests for login logic
- [ ] Write unit tests for lockout logic
