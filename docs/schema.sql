-- =========================================================
-- Enterprise HRMS — PostgreSQL Schema
-- Multi-tenant, row-level isolation via tenant_id
-- =========================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- for gen_random_uuid()

-- =====================
-- TENANTS
-- =====================
CREATE TABLE tenants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    subdomain       VARCHAR(100) UNIQUE NOT NULL,
    feature_flags   JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =====================
-- AUTH & RBAC
-- =====================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email           VARCHAR(255) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'active', -- active, disabled
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, email)
);
CREATE INDEX idx_users_tenant ON users(tenant_id);

CREATE TABLE permissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key             VARCHAR(100) UNIQUE NOT NULL,  -- e.g. 'leave:approve:team'
    description     VARCHAR(255)
);

CREATE TABLE roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(255),
    UNIQUE (tenant_id, name)
);
CREATE INDEX idx_roles_tenant ON roles(tenant_id);

CREATE TABLE role_permissions (
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id   UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- =====================
-- EMPLOYEES & ORG STRUCTURE
-- =====================
CREATE TABLE departments (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name                    VARCHAR(150) NOT NULL,
    parent_department_id    UUID REFERENCES departments(id)
);
CREATE INDEX idx_departments_tenant ON departments(tenant_id);

CREATE TABLE employees (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id             UUID REFERENCES users(id) ON DELETE SET NULL,
    employee_code       VARCHAR(50) NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    department_id       UUID REFERENCES departments(id),
    manager_id          UUID REFERENCES employees(id),
    title               VARCHAR(150),
    employment_status   VARCHAR(20) NOT NULL DEFAULT 'active', -- active, on_leave, terminated
    date_of_joining     DATE,
    date_of_birth       DATE,
    phone               VARCHAR(30),
    address             TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_code)
);
CREATE INDEX idx_employees_tenant ON employees(tenant_id);
CREATE INDEX idx_employees_manager ON employees(manager_id);
CREATE INDEX idx_employees_department ON employees(department_id);

CREATE TABLE employee_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    doc_type        VARCHAR(50) NOT NULL, -- id_proof, contract, certification, other
    file_url        TEXT NOT NULL,
    expiry_date     DATE,
    uploaded_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_documents_tenant_employee ON employee_documents(tenant_id, employee_id);
CREATE INDEX idx_documents_expiry ON employee_documents(expiry_date) WHERE expiry_date IS NOT NULL;

-- =====================
-- ATTENDANCE
-- =====================
CREATE TABLE attendance_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    clock_in        TIMESTAMPTZ NOT NULL,
    clock_out       TIMESTAMPTZ,
    source          VARCHAR(20) DEFAULT 'web', -- web, mobile, geofence
    status          VARCHAR(20) DEFAULT 'present' -- present, half_day, absent
);
CREATE INDEX idx_attendance_tenant_employee ON attendance_records(tenant_id, employee_id, clock_in);

CREATE TABLE regularization_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    reason          TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    approved_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_regularization_tenant ON regularization_requests(tenant_id, status);

-- =====================
-- LEAVE MANAGEMENT
-- =====================
CREATE TABLE leave_types (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    accrual_rate    NUMERIC(5,2) DEFAULT 0, -- days per month
    carry_forward   BOOLEAN NOT NULL DEFAULT false,
    max_balance     NUMERIC(5,2)
);
CREATE INDEX idx_leave_types_tenant ON leave_types(tenant_id);

CREATE TABLE leave_balances (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type_id   UUID NOT NULL REFERENCES leave_types(id) ON DELETE CASCADE,
    balance         NUMERIC(5,2) NOT NULL DEFAULT 0,
    year            INT NOT NULL,
    UNIQUE (tenant_id, employee_id, leave_type_id, year)
);
CREATE INDEX idx_leave_balances_tenant_employee ON leave_balances(tenant_id, employee_id);

CREATE TABLE leave_requests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id         UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type_id       UUID NOT NULL REFERENCES leave_types(id),
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    reason              TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, cancelled
    current_approver_id UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_leave_requests_tenant_employee ON leave_requests(tenant_id, employee_id);
CREATE INDEX idx_leave_requests_status ON leave_requests(tenant_id, status);

CREATE TABLE leave_approval_steps (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leave_request_id    UUID NOT NULL REFERENCES leave_requests(id) ON DELETE CASCADE,
    approver_id         UUID NOT NULL REFERENCES users(id),
    step_order          INT NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    acted_at            TIMESTAMPTZ
);
CREATE INDEX idx_approval_steps_request ON leave_approval_steps(leave_request_id);

-- =====================
-- PAYROLL
-- =====================
CREATE TABLE salary_structures (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id     UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    basic           NUMERIC(12,2) NOT NULL,
    allowances      JSONB NOT NULL DEFAULT '{}', -- e.g. {"hra": 2000, "transport": 500}
    deductions      JSONB NOT NULL DEFAULT '{}', -- e.g. {"tax": 800, "insurance": 200}
    effective_from  DATE NOT NULL
);
CREATE INDEX idx_salary_tenant_employee ON salary_structures(tenant_id, employee_id);

CREATE TABLE payroll_runs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    period_month    INT NOT NULL,
    period_year     INT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'processing', -- processing, completed, failed
    run_by          UUID REFERENCES users(id),
    run_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, period_month, period_year)
);
CREATE INDEX idx_payroll_runs_tenant ON payroll_runs(tenant_id);

CREATE TABLE payslips (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    payroll_run_id      UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
    employee_id         UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    gross               NUMERIC(12,2) NOT NULL,
    deductions          NUMERIC(12,2) NOT NULL,
    net                 NUMERIC(12,2) NOT NULL,
    pdf_url             TEXT
);
CREATE INDEX idx_payslips_tenant_employee ON payslips(tenant_id, employee_id);

-- =====================
-- AUDIT LOG (insert-only, never updated/deleted)
-- =====================
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    actor_id        UUID REFERENCES users(id),
    action          VARCHAR(50) NOT NULL,       -- CREATE, UPDATE, DELETE, APPROVE, REJECT
    entity_type     VARCHAR(50) NOT NULL,       -- e.g. 'salary_structure', 'leave_request'
    entity_id       UUID NOT NULL,
    before           JSONB,
    after            JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_tenant_entity ON audit_logs(tenant_id, entity_type, entity_id);
CREATE INDEX idx_audit_tenant_created ON audit_logs(tenant_id, created_at DESC);

-- =====================
-- NOTIFICATIONS
-- =====================
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(50) NOT NULL, -- leave_status, approval_pending, document_expiring, payslip_ready
    payload         JSONB NOT NULL DEFAULT '{}',
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_tenant_user ON notifications(tenant_id, user_id, read_at);

-- =========================================================
-- SEED: baseline permissions (global, not tenant-scoped)
-- =========================================================
INSERT INTO permissions (key, description) VALUES
    ('employee:create', 'Create employee records'),
    ('employee:edit:all', 'Edit any employee record'),
    ('employee:edit:self', 'Edit own profile fields'),
    ('employee:view:team', 'View direct reports'' records'),
    ('leave:apply', 'Apply for leave'),
    ('leave:approve:team', 'Approve leave for direct reports'),
    ('leave:approve:all', 'Approve leave for any employee'),
    ('attendance:clock', 'Clock in/out'),
    ('attendance:regularize:approve', 'Approve regularization requests'),
    ('payroll:run', 'Run payroll for tenant'),
    ('payroll:view:self', 'View own payslips'),
    ('payroll:view:all', 'View all payslips'),
    ('document:upload', 'Upload employee documents'),
    ('audit:view', 'View audit log'),
    ('role:manage', 'Create/edit roles and permission assignments');
