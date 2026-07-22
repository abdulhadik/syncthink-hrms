# SyncThink HRMS

Multi-tenant Human Resource Management System — monorepo.

## Structure
```
apps/
  web/        Next.js frontend
  api/        Express backend
packages/
  db/         Shared Prisma schema + client
  types/      Shared TypeScript types/DTOs
docs/
  HRMS-Enterprise-Project-Plan.md   PRD, wireframes, architecture, roadmap
  schema.sql                        Reference SQL schema
```

## Status
🚧 Scaffolding stage — workspace structure is in place, no application code
yet. See `docs/HRMS-Enterprise-Project-Plan.md` for the full roadmap.

## Getting started (once you have Node 20+ and pnpm installed)
```bash
pnpm install
cp apps/api/.env.example apps/api/.env   # fill in real values
pnpm db:generate                          # once schema.prisma is written
pnpm dev:api                              # once apps/api has source code
pnpm dev:web                              # once apps/web has source code
```

## Next steps
See `docs/HRMS-Enterprise-Project-Plan.md` → Section 5 (Roadmap) and the
Phase 0-7 execution plan for what to build first: database schema →
backend auth/employees module → frontend shell → remaining modules.
