# Enterprise HRMS — Project Plan
**Product:** Multi-Tenant Human Resource Management System
**Version:** 1.0
**Prepared for:** Solo full-stack portfolio build (4-week sprint)

---

# 1. Product Requirements Document (PRD)

## 1.1 Vision
Build a multi-tenant HRMS that lets a company manage its full employee lifecycle — onboarding, attendance, leave, payroll, and performance — through a permission-based, auditable platform. The product should feel like something a real mid-size company (50–500 employees) could adopt, not a toy CRUD app.

## 1.2 Problem Statement
Small-to-mid companies juggle spreadsheets, email threads, and disconnected tools for HR operations. This causes: no audit trail on sensitive changes (salary, leave approvals), no self-service for employees, and no visibility for managers/admins into org-wide trends.

## 1.3 Target Users / Personas

| Persona | Role | Needs |
|---|---|---|
| **Super Admin** | Platform owner (you, in demo) | Manage tenants, feature flags |
| **HR Admin** | Company's HR team | Manage employees, payroll, policies, full audit visibility |
| **Manager** | Team lead | Approve leave/attendance for direct reports, view team analytics |
| **Employee** | Individual contributor | Self-service: clock in/out, apply leave, view payslips, update profile |

## 1.4 Scope

### In Scope (v1)
- Multi-tenant company accounts with data isolation
- Permission-based RBAC (not just fixed roles)
- Employee directory & profile management
- Attendance (clock in/out, regularization)
- Leave management with multi-level approval
- Payroll (salary structure, payslip generation)
- Document management (upload, expiry tracking)
- Audit log for sensitive actions
- Admin analytics dashboard
- Notifications (in-app + email)

### Out of Scope (v1 — call out explicitly, revisit in v2)
- Real payroll tax computation / statutory compliance per country
- Native mobile app (responsive web only)
- Full performance review cycles (stub only if time allows)
- Actual SSO/SCIM provisioning (build the integration point, mock the provider)
- Real payment processing for payroll disbursement

## 1.5 Functional Requirements

### FR1 — Tenancy & Auth
- FR1.1 A user signs up and creates a new company (tenant) or joins an existing one via invite
- FR1.2 All data queries are scoped by `tenant_id`; no cross-tenant data leakage under any request path
- FR1.3 Users authenticate via email/password or OAuth; sessions are JWT-based with refresh tokens
- FR1.4 Permissions are assigned via roles, but roles are just named bundles of granular permissions (e.g. `leave:approve:team`, `payroll:view:self`)

### FR2 — Employee Management
- FR2.1 HR Admin can create, edit, deactivate employee records
- FR2.2 Each employee has: personal info, job info (title, department, manager), documents, employment status
- FR2.3 Org chart view showing manager → report relationships
- FR2.4 Employee self-service profile edit (limited fields; sensitive fields are HR-only)

### FR3 — Attendance
- FR3.1 Employee clocks in/out; system records timestamp + (optional) IP/geolocation
- FR3.2 Daily/weekly/monthly attendance view per employee
- FR3.3 Employee can submit a regularization request (e.g. "forgot to clock out") for manager approval
- FR3.4 Manager sees pending regularizations for their team

### FR4 — Leave Management
- FR4.1 HR Admin configures leave types and policies (accrual rate, carry-forward rules) per tenant
- FR4.2 Employee applies for leave; system checks balance before allowing submission
- FR4.3 Leave request routes through an approval chain (configurable: manager only, or manager + HR)
- FR4.4 Approved/rejected leave updates balance and triggers notification
- FR4.5 Team leave calendar visible to managers

### FR5 — Payroll
- FR5.1 HR Admin defines salary structure per employee (basic, allowances, deductions)
- FR5.2 HR Admin runs monthly payroll; system generates payslips (PDF) for all active employees
- FR5.3 Every payroll run and edit is written to the audit log with before/after values
- FR5.4 Employee views/downloads their own payslip history only

### FR6 — Documents
- FR6.1 Upload documents against an employee record (ID proof, contract, certifications)
- FR6.2 Documents with expiry dates (e.g. visa) trigger a reminder notification 30 days before expiry

### FR7 — Audit Log
- FR7.1 Every create/update/delete on sensitive entities (salary, leave approval, role change, document) is logged with actor, timestamp, entity, before/after diff
- FR7.2 HR Admin can search/filter the audit log

### FR8 — Notifications
- FR8.1 In-app notification center (bell icon, unread count)
- FR8.2 Email notifications for: leave status change, approval request pending, document expiring, payslip generated

### FR9 — Admin Analytics
- FR9.1 Dashboard: headcount, department distribution, attendance rate trend, leave utilization
- FR9.2 Exportable reports (CSV)

## 1.6 Non-Functional Requirements
- **Security:** every API route enforces both authentication AND permission checks; no client-side-only checks
- **Performance:** dashboard queries return in <500ms for a tenant with 500 employees (use indexes, avoid N+1)
- **Data isolation:** automated test suite includes cross-tenant leakage tests
- **Auditability:** audit log entries are immutable (insert-only)
- **Accessibility:** forms are keyboard-navigable, proper labels (basic WCAG AA effort)

## 1.7 Success Metrics (for your portfolio narrative, not real users)
- All core flows work end-to-end with seeded demo data across 2+ tenants
- Test coverage on business logic (leave balance calc, approval chains, payroll calc) ≥ 70%
- Zero cross-tenant data leakage in test suite
- Deployed, publicly accessible, with demo logins for all 4 roles

---

# 2. Wireframes (Low-Fidelity)

These are structural wireframes — enough to drive layout decisions, not visual design.

## 2.1 Login / Tenant Selection
```
┌─────────────────────────────────────┐
│              [ HRMS Logo ]           │
│                                       │
│   Email        [______________]      │
│   Password     [______________]      │
│                                       │
│            [   Log In   ]            │
│                                       │
│   New company? [Create workspace]    │
│   Have an invite? [Join workspace]   │
└─────────────────────────────────────┘
```

## 2.2 Dashboard (role-aware — Manager/Admin view shown)
```
┌───────────┬───────────────────────────────────────────┐
│  LOGO     │  Dashboard                     🔔  [Avatar]│
│           ├───────────────────────────────────────────┤
│ Dashboard │  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│ Employees │  │Headcount │ │On Leave  │ │Pending   │    │
│ Attendance│  │   184    │ │  Today 6 │ │Approvals4│    │
│ Leave     │  └──────────┘ └──────────┘ └──────────┘    │
│ Payroll   │                                             │
│ Documents │  Attendance Trend        Dept Distribution │
│ Reports   │  [ line chart ]          [ pie chart ]     │
│ Audit Log │                                             │
│ Settings  │  Recent Activity                            │
│           │  - J. Smith requested leave (2h ago)        │
└───────────┴───────────────────────────────────────────┘
```

## 2.3 Employee Directory
```
┌───────────────────────────────────────────────────────┐
│  Employees                          [+ Add Employee]   │
│  [Search...........] [Dept ▾] [Status ▾]                │
├───────────────────────────────────────────────────────┤
│ Name        Dept          Title          Status  ...   │
│ J. Smith    Engineering   Sr Engineer    Active   >     │
│ A. Khan     Sales         Manager        Active   >     │
│ R. Patel    HR            HR Admin       Active   >     │
└───────────────────────────────────────────────────────┘
```

## 2.4 Employee Profile
```
┌───────────────────────────────────────────────────────┐
│  ← Back      J. Smith — Sr Engineer, Engineering        │
│  [Profile] [Attendance] [Leave] [Payroll] [Documents]   │
├───────────────────────────────────────────────────────┤
│  Personal Info          Job Info                        │
│  Name, DOB, Contact      Manager, Dept, Join Date        │
│  [Edit]                  [Edit] (HR only)                │
│                                                           │
│  Documents                                               │
│  [ID.pdf] [Contract.pdf] [+ Upload]                      │
└───────────────────────────────────────────────────────┘
```

## 2.5 Leave Application (Employee view)
```
┌───────────────────────────────────────────────────────┐
│  Apply for Leave                                        │
├───────────────────────────────────────────────────────┤
│  Leave Type   [ Sick Leave ▾ ]   Balance: 8 days         │
│  From         [ 2026-08-01 ]                             │
│  To           [ 2026-08-02 ]                             │
│  Reason       [__________________________]               │
│                                                           │
│                              [Cancel]  [Submit Request]  │
├───────────────────────────────────────────────────────┤
│  My Requests                                             │
│  Aug 1-2   Sick Leave   Pending  (Manager)                │
│  Jul 10    Casual Leave Approved                          │
└───────────────────────────────────────────────────────┘
```

## 2.6 Approval Queue (Manager view)
```
┌───────────────────────────────────────────────────────┐
│  Pending Approvals (4)                                  │
├───────────────────────────────────────────────────────┤
│  J. Smith  — Sick Leave  Aug 1-2   [Approve] [Reject]   │
│  A. Khan   — Regularization Jul 18 [Approve] [Reject]   │
└───────────────────────────────────────────────────────┘
```

## 2.7 Payroll Run (HR Admin view)
```
┌───────────────────────────────────────────────────────┐
│  Payroll — July 2026                     [Run Payroll]  │
├───────────────────────────────────────────────────────┤
│  Employee     Gross      Deductions   Net       Status  │
│  J. Smith     $8,000     $1,200       $6,800    Paid    │
│  A. Khan      $6,500     $900         $5,600    Paid    │
│                                            [Download All]│
└───────────────────────────────────────────────────────┘
```

## 2.8 Audit Log
```
┌───────────────────────────────────────────────────────┐
│  Audit Log        [Entity ▾] [User ▾] [Date range]      │
├───────────────────────────────────────────────────────┤
│  2026-07-19 14:02  R.Patel  UPDATE salary  J.Smith       │
│    before: 7500  after: 8000                             │
│  2026-07-19 11:30  A.Khan   APPROVE leave  J.Smith       │
└───────────────────────────────────────────────────────┘
```

---

# 3. Technical Architecture & Database Schema

## 3.1 High-Level Architecture
```
                         ┌───────────────────┐
                         │   Next.js Web App  │
                         │ (React, TS, Tailwind)│
                         └─────────┬──────────┘
                                   │ HTTPS/REST
                         ┌─────────▼──────────┐
                         │   Express API        │
                         │  ─────────────────  │
                         │  auth/                │
                         │  tenants/             │
                         │  employees/           │
                         │  attendance/          │
                         │  leave/               │
                         │  payroll/             │
                         │  documents/           │
                         │  audit/ (middleware, cross-cutting) │
                         │  notifications/       │
                         │                        │
                         │  Middleware chain:     │
                         │  tenant → auth → permission → validate → controller → audit │
                         └───┬─────────┬────────┘
                             │         │
                ┌────────────▼──┐   ┌──▼─────────────┐
                │ PostgreSQL     │   │ Redis + BullMQ  │
                │ (Prisma ORM)   │   │ (jobs: payroll  │
                │ tenant_id on   │   │ runs, reminders,│
                │ every table    │   │ emails)         │
                └────────────────┘   └─────────────────┘
                             │
                    ┌────────▼────────┐
                    │ S3 / R2 (files)  │
                    └──────────────────┘

Cross-cutting: Middleware chain (tenant → JWT auth → permission check → validate) → Controller → Service → Prisma
Every sensitive write path passes through an audit middleware that logs actor/entity/diff.
```

## 3.2 Tenancy Strategy
**Approach:** shared database, shared schema, row-level isolation via `tenant_id`.
- Every tenant-scoped table has a `tenant_id` column, indexed.
- A Prisma `$use` middleware (or a `tenant.middleware.ts` Express middleware that attaches `req.tenantId` and a scoped Prisma client) auto-injects `tenant_id` into every query based on the authenticated user's session — no query can be written that skips it.
- Document in README why this was chosen over schema-per-tenant (simpler ops, good enough isolation for portfolio scale, easy to demo; schema-per-tenant is the harder-but-more-isolated alternative worth mentioning as a "v2 consideration").

## 3.3 RBAC Model
- `permissions` table: atomic strings like `employee:create`, `leave:approve:team`, `payroll:view:self`
- `roles` table (per tenant, so tenants can customize): bundles of permissions
- `user_roles`: many-to-many, user ↔ role
- A `requirePermission('leave:approve:team')` Express middleware, applied per-route, checks the required permission key against the authenticated user's resolved permission set (via `req.user`), including scope (`:team` vs `:self` vs `:all`)

## 3.4 Tech Stack
| Layer | Choice | Why |
|---|---|---|
| Frontend | Next.js (App Router) + TypeScript + Tailwind + shadcn/ui | Fast to build, strong hiring signal |
| Backend | Express + TypeScript | Lightweight, fast to build, full control over middleware chain (auth, tenant scoping, permissions, audit logging) |
| DB | PostgreSQL + Prisma | Relational data fits HR domain; Prisma = strong DX + migrations |
| Auth | JWT (access + refresh), NextAuth or custom | Session control, SSO-ready design |
| Queue | Redis + BullMQ | Payroll runs, reminder emails run async |
| Storage | Cloudflare R2 / S3 | Documents, payslip PDFs |
| Email | Resend | Notifications |
| Testing | Vitest (unit/integration) + Playwright (E2E) | |
| Deploy | Vercel (web) + Railway (API + Redis) + Neon (Postgres) | |
| Monitoring | Sentry | Error tracking |

## 3.5 Database Schema (Core Tables)

```sql
-- Tenants
tenants (id, name, subdomain, created_at, feature_flags jsonb)

-- Users & Auth
users (id, tenant_id, email, password_hash, status, created_at)
roles (id, tenant_id, name, description)
permissions (id, key, description)          -- global, not tenant-scoped
role_permissions (role_id, permission_id)
user_roles (user_id, role_id)

-- Employees
departments (id, tenant_id, name, parent_department_id)
employees (id, tenant_id, user_id, employee_code, first_name, last_name,
           department_id, manager_id, title, employment_status,
           date_of_joining, date_of_birth, phone, address)
employee_documents (id, tenant_id, employee_id, doc_type, file_url,
                     expiry_date, uploaded_by, created_at)

-- Attendance
attendance_records (id, tenant_id, employee_id, clock_in, clock_out,
                     source, status)
regularization_requests (id, tenant_id, employee_id, date, reason,
                          status, approved_by, created_at)

-- Leave
leave_types (id, tenant_id, name, accrual_rate, carry_forward, max_balance)
leave_balances (id, tenant_id, employee_id, leave_type_id, balance, year)
leave_requests (id, tenant_id, employee_id, leave_type_id, start_date,
                 end_date, reason, status, current_approver_id, created_at)
leave_approval_steps (id, leave_request_id, approver_id, step_order,
                       status, acted_at)

-- Payroll
salary_structures (id, tenant_id, employee_id, basic, allowances jsonb,
                    deductions jsonb, effective_from)
payroll_runs (id, tenant_id, period_month, period_year, status,
              run_by, run_at)
payslips (id, tenant_id, payroll_run_id, employee_id, gross, deductions,
          net, pdf_url)

-- Audit
audit_logs (id, tenant_id, actor_id, action, entity_type, entity_id,
            before jsonb, after jsonb, created_at)   -- insert-only

-- Notifications
notifications (id, tenant_id, user_id, type, payload jsonb, read_at,
               created_at)
```

**Key relationships:**
- `employees.manager_id` → self-referencing FK (org hierarchy)
- `leave_requests` → `leave_approval_steps` (1-to-many, supports multi-level approval)
- `payroll_runs` → `payslips` (1-to-many)
- Every table above (except `permissions`) carries `tenant_id`, indexed as `(tenant_id, id)` composite where it's the primary lookup pattern

A ready-to-run `schema.sql` (Prisma-equivalent DDL) is provided alongside this document.

---

# 4. Coding Standards & Definition of Done

## 4.1 Repository Structure
```
apps/
  web/            # Next.js frontend
  api/            # Express backend (src/modules/<domain>/routes,controller,service,schema)
packages/
  db/             # Prisma schema + generated client
  types/          # Shared TS types/DTOs
  ui/             # Shared React components (if extracted)
```

Each Express module folder (`src/modules/employees/`, `src/modules/leave/`, etc.) follows a consistent 4-file pattern: `*.routes.ts` (wires middleware + controller), `*.controller.ts` (thin, calls service), `*.service.ts` (business logic, unit-tested), `*.schema.ts` (Zod validation schemas). This mirrors NestJS's module boundaries without the framework overhead — keep it consistent across every domain module.

## 4.2 Coding Standards
- **TypeScript strict mode** everywhere; no `any` without a `// TODO` justification comment
- **Naming:** `camelCase` for variables/functions, `PascalCase` for components/classes, `kebab-case` for file names, DB tables/columns in `snake_case`
- **API design:** RESTful resource naming (`/employees/:id/leave-requests`), consistent error shape `{ statusCode, message, error }`
- **Validation:** all incoming request bodies validated via Zod schemas (`*.schema.ts` per module), enforced through a shared `validate(schema)` Express middleware — same library used on the Next.js frontend for form validation, so schemas can be shared via `packages/types` where practical
- **No business logic in controllers** — controllers call services; services contain logic and are unit-testable in isolation, independent of Express's `req`/`res`
- **Every sensitive write** (salary, role, approval) passes through the `auditLog()` middleware — applied explicitly per-route since Express has no global interceptor mechanism; missing it on a route is a code-review blocker, not a style nit
- **Route registration discipline:** every route must explicitly declare its middleware chain in this order: `tenantMiddleware → authMiddleware → requirePermission(...) → validate(schema) → controller → auditLog(...)` where applicable — inconsistent ordering across modules is a common Express footgun, so this order is non-negotiable and should be spot-checked in PR review
- **Git workflow:** trunk-based with short-lived feature branches, Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`), PR required even solo (self-review habit, keeps history clean)
- **Environment config:** all secrets via `.env`, never committed; `.env.example` kept up to date

## 4.3 Testing Requirements
| Type | Target coverage | Focus |
|---|---|---|
| Unit | Business logic (leave balance calc, payroll calc, permission resolution) | ≥ 80% |
| Integration | API routes (auth, CRUD, approval flows) | Key happy + error paths |
| E2E (Playwright) | Critical user journeys | Login → apply leave → approve → balance updates; Payroll run → payslip download |
| Security | Cross-tenant isolation | Explicit test: user from Tenant A cannot read/write Tenant B data via any endpoint |

## 4.4 Definition of Done (per feature)
A feature is "done" only when:
1. Code merged via PR with passing CI (lint + typecheck + tests)
2. Unit tests cover core logic; integration test covers the API route
3. Permission checks verified (both "allowed" and "denied" cases tested)
4. Audit log entry confirmed for any sensitive write
5. UI has loading, empty, and error states — not just the happy path
6. Responsive check (mobile + desktop) done manually
7. No console errors/warnings in browser or server logs
8. README/docs updated if the change affects setup or architecture

## 4.5 Definition of Done (per sprint/week)
1. All planned features meet feature-level DoD above
2. Demo data reseeded and verified end-to-end
3. Deployed to staging URL, smoke-tested manually
4. Retro note written: what worked, what to adjust next week

---

# 5. Project Roadmap & Timeline (4 Weeks)

## Week 1 — Foundation & Tenancy
| Day | Focus |
|---|---|
| 1 | Repo scaffold (Next.js + Express + Prisma), CI pipeline, env setup |
| 2 | Tenant model, signup/create-workspace flow, JWT auth |
| 3 | Permission/role engine (permissions, roles, user_roles tables + `requirePermission` middleware) |
| 4 | Audit log middleware (`auditLog()`, applied per sensitive route, insert-only writes) |
| 5 | Employee CRUD + department/org hierarchy |
| 6-7 | Employee directory UI + profile page, buffer/catch-up |

**Week 1 milestone:** can sign up as a company, invite users, assign roles, and manage employee records — with every write audited.

## Week 2 — Attendance & Leave
| Day | Focus |
|---|---|
| 8 | Attendance clock-in/out API + UI |
| 9 | Regularization request + manager approval |
| 10 | Leave types & policy config (per tenant) |
| 11 | Leave request + balance check logic (unit tests here) |
| 12 | Multi-level approval chain (leave_approval_steps) |
| 13 | Notifications (in-app + email) wired to leave/attendance events |
| 14 | Team calendar view, buffer |

**Week 2 milestone:** full leave lifecycle works end-to-end with approvals and balance updates, notifications fire correctly.

## Week 3 — Payroll & Documents
| Day | Focus |
|---|---|
| 15 | Salary structure model + admin UI |
| 16 | Payroll run logic (background job via BullMQ) |
| 17 | Payslip PDF generation |
| 18 | Employee payslip view/download |
| 19 | Document upload (S3/R2) + expiry tracking |
| 20 | Expiry reminder job (scheduled) |
| 21 | Buffer, security pass on payroll routes (permission tests) |

**Week 3 milestone:** payroll can be run for a tenant, payslips generated and downloadable, documents tracked with expiry alerts.

## Week 4 — Analytics, Testing, Polish, Deploy
| Day | Focus |
|---|---|
| 22 | Admin analytics dashboard (headcount, attendance trend, leave utilization) |
| 23 | Cross-tenant isolation test suite (explicit security tests) |
| 24 | Playwright E2E for critical journeys |
| 25 | Responsive/UX polish pass, loading/empty/error states audit |
| 26 | Deploy: Vercel + Railway + Neon, environment separation, Sentry wired |
| 27 | Seed 2-3 demo tenants with different feature flags/data, write demo login list |
| 28 | README + architecture diagram + demo video, final QA pass |

**Week 4 milestone:** publicly deployed, documented, demo-ready HRMS with working RBAC, multi-tenancy, audit trail, and 3+ demo accounts across roles.

## Risk Buffer Guidance
If you're behind by Week 3, cut in this order first: performance module (already out of scope), document expiry reminders, admin feature flags UI — keep RBAC, multi-tenancy, audit log, and the leave/payroll core flows intact, since those are what differentiate this project in interviews.
