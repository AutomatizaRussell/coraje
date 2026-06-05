import { prisma } from "@/lib/prisma";

/**
 * Obtiene tickets creados desde el portal de clientes que aún no han sido
 * redirigidos a un área.
 *
 * Regla de negocio:
 * - origen_sistema = PORTAL_CLIENTE
 * - estado = ABIERTO
 * - id_area_destino IS NULL
 *
 * Estos tickets todavía no deben enviarse a SharePoint/PowerApps hasta que
 * el empleado redireccionador seleccione área, tipo y categoría.
 */
export async function getPendingRedirectTickets() {
  return prisma.fact_ticket.findMany({
    where: {
      origen_sistema: "PORTAL_CLIENTE",
      id_area_destino: null,
      dim_estado: {
        nombre_estado: "ABIERTO",
      },
    },
    orderBy: {
      fecha_creacion: "asc",
    },
    select: {
      id_ticket: true,
      codigo_ticket: true,
      descripcion_problema: true,
      fecha_creacion: true,
      fecha_limite: true,
      dim_cliente_contai: {
        select: {
          nombre_cliente: true,
          identificacion_fiscal: true,
        },
      },
      dim_estado: {
        select: {
          nombre_estado: true,
        },
      },
    },
  });
}