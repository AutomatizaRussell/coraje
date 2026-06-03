import { prisma } from "@/lib/prisma";
import type { TicketListItem } from "../types";

/**
 * Obtiene los tickets más recientes para la vista operativa inicial.
 *
 * Decisión técnica:
 * - La consulta vive fuera del componente para separar acceso a datos de UI.
 * - Se transforma el resultado Prisma a un DTO propio de front-end.
 * - Se mantienen fallbacks explícitos para campos opcionales heredados
 *   desde SharePoint o incompletos durante la migración.
 */
export async function getRecentTickets(limit = 25): Promise<TicketListItem[]> {
  const tickets = await prisma.fact_ticket.findMany({
    take: limit,
    orderBy: {
      fecha_creacion: "desc",
    },
    select: {
      id_ticket: true,
      consecutivo_sp: true,
      titulo_ticket: true,
      fecha_creacion: true,
      dim_estado: {
        select: {
          nombre_estado: true,
        },
      },
      dim_prioridad: {
        select: {
          nombre_prioridad: true,
        },
      },
      dim_area: {
        select: {
          nombre_area: true,
        },
      },
      dim_cliente_contai: {
        select: {
          nombre_cliente: true,
        },
      },
    },
  });

  return tickets.map((ticket) => ({
    idTicket: ticket.id_ticket,
    consecutivoSp: ticket.consecutivo_sp,
    titulo: ticket.titulo_ticket,
    cliente: ticket.dim_cliente_contai?.nombre_cliente ?? "Sin cliente",
    area: ticket.dim_area?.nombre_area ?? "Sin área",
    estado: ticket.dim_estado.nombre_estado,
    prioridad: ticket.dim_prioridad?.nombre_prioridad ?? "Sin prioridad",
    fechaCreacion: ticket.fecha_creacion,
  }));
}