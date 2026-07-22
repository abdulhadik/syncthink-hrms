# SyncThink HRMS — API (Express)

Backend app. Workspace placeholder with dependencies wired up; source code
not yet written.

## Planned structure (see project plan doc)
```
src/
  index.ts, app.ts
  config/
  prisma/
  middleware/        # tenant, auth, permission, validate, audit-log, error-handler
  modules/            # auth, tenants, roles, employees, departments,
                       # attendance, leave, payroll, documents, audit, notifications
  jobs/
  lib/
  types/
```

## Next step
Ask Claude to scaffold `src/index.ts`, `src/app.ts`, and the `auth` +
`employees` modules to get a runnable API (Phase 2-3 of the roadmap).
