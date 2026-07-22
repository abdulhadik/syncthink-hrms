// Shared types/interfaces between apps/web and apps/api.
// Keep these in sync with packages/db/prisma/schema.prisma once it's written.

export interface AuthenticatedUser {
  id: string;
  tenantId: string;
  email: string;
  permissions: string[];
}

export type EmploymentStatus = "active" | "on_leave" | "terminated";

export interface EmployeeSummary {
  id: string;
  employeeCode: string;
  firstName: string;
  lastName: string;
  title: string | null;
  departmentId: string | null;
  managerId: string | null;
  employmentStatus: EmploymentStatus;
}

export type LeaveRequestStatus =
  | "pending"
  | "approved"
  | "rejected"
  | "cancelled";

export interface LeaveRequestSummary {
  id: string;
  employeeId: string;
  leaveTypeId: string;
  startDate: string; // ISO date
  endDate: string; // ISO date
  status: LeaveRequestStatus;
}

// Extend this file as each module is built — one interface per API
// resource shape, kept in lockstep with the Zod schemas in apps/api.
