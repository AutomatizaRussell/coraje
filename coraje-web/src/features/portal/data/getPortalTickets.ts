import { prisma } from "@/lib/prisma";

/**
 * Obtiene los tickets visibles para el cliente seleccionado en el portal.
 *
 * Reglas actuales:
 * - Filtra por id_cliente_contai del cliente seleccionado en la cookie temporal.
 * - Filtra por origen_sistema = PORTAL_CLIENTE.
 * - No muestra tickets legacy mientras el acceso siga siendo falso/temporal,
 *   porque cualquier usuario podría seleccionar cualquier cliente.
 *
 * Campos importantes:
 * - id_ticket: necesario para acciones como eliminar tickets no redirigidos.
 * - id_area_destino: permite saber si el ticket ya fue redirigido.
 * - id_tipo_req: permite saber si el ticket ya fue clasificado.
 * - dim_estado.nombre_estado: permite traducir estado técnico a estado visible.
 */
export async function getPortalTickets(clientId: string) {
  const tickets = await prisma.fact_ticket.findMany({
    where: {
      id_cliente_contai: clientId,
      origen_sistema: "PORTAL_CLIENTE",
    },
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
      respuesta_final: true,
      id_area_destino: true,
      id_tipo_req: true,
      dim_estado: {
        select: {
          nombre_estado: true,
        },
      },
    },
  });



  return tickets;
}
