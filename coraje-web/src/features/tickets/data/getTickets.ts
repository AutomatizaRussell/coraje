import { prisma } from "@/lib/prisma";
import type { TicketListItem } from "../types";

/**
 * Obtiene los tickets recientes para la vista operativa principal.
 *
 * Decisiones técnicas:
 * - Consulta directa server-side mediante Prisma.
 * - No expone el modelo Prisma completo a la UI.
 * - Traduce nombres físicos snake_case a nombres semánticos camelCase.
 * - Usa fallbacks explícitos para relaciones opcionales que pueden venir
 *   incompletas desde la migración legacy.
 */
export async function getRecentTickets(limit = 25): Promise<TicketListItem[]> {
  const tickets = await prisma.fact_ticket.findMany({
    take: limit,
    orderBy: {
      fecha_creacion: "desc",
    },
    select: {
      id_ticket: true,
      codigo_ticket: true,
      descripcion_problema: true,
      fecha_creacion: true,
      fecha_limite: true,
      fecha_resolucion: true,
      origen_sistema: true,

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

      dim_tipo_requerimiento: {
        select: {
          tipo_requerimiento: true,
          categoria_1: true,
          categoria_2: true,
        },
      },
    },
  });

  return tickets.map((ticket) => ({
    idTicket: ticket.id_ticket,
    codigoTicket: ticket.codigo_ticket,
    descripcion: ticket.descripcion_problema,

    cliente: ticket.dim_cliente_contai?.nombre_cliente ?? "Sin cliente",
    area: ticket.dim_area?.nombre_area ?? "Sin área",
    estado: ticket.dim_estado.nombre_estado,
    prioridad: ticket.dim_prioridad?.nombre_prioridad ?? "Sin prioridad",

    tipoRequerimiento:
      ticket.dim_tipo_requerimiento?.tipo_requerimiento ?? "Sin tipo",
    categoria1: ticket.dim_tipo_requerimiento?.categoria_1 ?? "Sin categoría",
    categoria2:
      ticket.dim_tipo_requerimiento?.categoria_2 ?? "Sin subcategoría",

    fechaCreacion: ticket.fecha_creacion,
    fechaLimite: ticket.fecha_limite,
    fechaResolucion: ticket.fecha_resolucion,
    origenSistema: ticket.origen_sistema,
  }));
}