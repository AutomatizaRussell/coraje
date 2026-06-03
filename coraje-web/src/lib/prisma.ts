import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@/generated/prisma/client";

/**
 * Validación explícita de configuración crítica.
 *
 * No usamos `process.env.DATABASE_URL!` porque el non-null assertion solo
 * silencia TypeScript; no valida nada en runtime. Si la variable falta,
 * preferimos fallar al iniciar el módulo con un error claro.
 */
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error(
    "DATABASE_URL no está definida. Revisa el archivo .env o las variables del entorno de despliegue.",
  );
}

/**
 * Adapter oficial de Prisma para PostgreSQL.
 *
 * En Prisma 7 el cliente puede trabajar mediante driver adapters. Aquí
 * centralizamos la conexión para que toda la aplicación use una sola
 * configuración de acceso a datos.
 */
const adapter = new PrismaPg({
  connectionString: databaseUrl,
});

/**
 * Cache global del cliente Prisma en desarrollo.
 *
 * Next.js recompila módulos durante el hot reload. Sin este patrón, cada
 * recarga puede crear nuevas conexiones y saturar PostgreSQL en local.
 */
const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient;
};

/**
 * Cliente Prisma compartido.
 *
 * En desarrollo mantenemos logs de query para depuración. En producción
 * eliminamos `query` para evitar ruido, costos de logging y exposición
 * innecesaria de detalles internos.
 */
export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    adapter,
    log:
      process.env.NODE_ENV === "production"
        ? ["error", "warn"]
        : ["query", "error", "warn"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}