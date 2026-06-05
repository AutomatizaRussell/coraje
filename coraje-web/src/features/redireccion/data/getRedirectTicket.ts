import { prisma } from "@/lib/prisma";

/**
 * Obtiene un ticket específico para redirección.
 *
 * Regla de negocio:
 * - Solo se permite redirigir tickets creados desde el portal.
 * - Solo se permite redirigir tickets sin área destino.
 * - Solo se permite redirigir tickets en estado ABIERTO.
 *
 * Si el ticket no cumple esas condiciones, devuelve null.
 */
export async function getRedirectTicket(ticketId: string) {
  return prisma.fact_ticket.findFirst({
    where: {
      id_ticket: ticketId,
      origen_sistema: "PORTAL_CLIENTE",
      id_area_destino: null,
      dim_estado: {
        nombre_estado: "ABIERTO",
      },
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
          tipo_cliente: true,
          grupo_economico: true,
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
