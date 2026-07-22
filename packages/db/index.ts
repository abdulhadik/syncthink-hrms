import { PrismaClient } from "@prisma/client";

// Singleton pattern so dev hot-reload doesn't exhaust DB connections.
declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

export const prisma = global.__prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  global.__prisma = prisma;
}

export * from "@prisma/client";
