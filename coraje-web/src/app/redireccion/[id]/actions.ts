"use server";

import { redirect } from "next/navigation";

import { prisma } from "@/lib/prisma";
import { requireRedireccionAuth } from "@/features/redireccion/data/redireccionAuth";

/**
 * Valida de forma mínima un UUID recibido desde formulario.
 *
 * No restringimos versión UUID aquí porque PostgreSQL ya valida el tipo UUID
 * cuando hacemos casts `::uuid` en las consultas. Esta función solo bloquea
 * valores claramente inválidos antes de llegar a la base de datos.
 */
function assertUuid(value: string, fieldName: string): string {
  const normalizedValue = value.trim();

  const isValid =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      normalizedValue,
    );

  if (!isValid) {
    throw new Error(`${fieldName} inválido: ${normalizedValue}`);
  }

  return normalizedValue;
}

/**
 * Redirige un ticket creado desde el portal hacia un área legacy válida.
 *
 * Reglas actuales:
 * - Solo empleado autenticado temporalmente puede ejecutar.
 * - El ticket debe venir de PORTAL_CLIENTE.
 * - El ticket debe estar ABIERTO.
 * - El ticket no debe tener área destino previa.
 * - El id_tipo_req seleccionado debe pertenecer al área seleccionada.
 * - El área que se guarda en fact_ticket sigue siendo la compatible con
 *   PowerApps/SharePoint.
 * - El encargado interno se resuelve así:
 *     1. Si existe helpdesk.routing_rule activa para id_tipo_req, usa esa regla.
 *     2. Si no existe regla, usa core.dim_area.encargado_recepcion.
 * - Se crea un registro PENDING en ticket_sync_outbox con operación CREATE_TICKET.
 *
 * Importante:
 * Esta acción NO escribe en SharePoint todavía.
 * Solo deja PostgreSQL listo para que el futuro flujo n8n PG -> SharePoint
 * procese la sincronización.
 */
export async function redirectTicketAction(formData: FormData) {
  await requireRedireccionAuth();
  const ticketId = assertUuid(String(formData.get("ticketId") ?? ""), "ticketId");
  const areaId = assertUuid(String(formData.get("areaId") ?? ""), "areaId");
  const tipoReqId = assertUuid(
    String(formData.get("tipoReqId") ?? ""),
    "tipoReqId",
  );

  await prisma.$transaction(async (tx) => {
    /**
     * 1. Validar que el tipo de requerimiento pertenece al área seleccionada.
     *
     * Esto impide combinaciones inválidas como:
     * - área ADMINISTRACIÓN
     * - tipo_req perteneciente a LEGAL
     */
    const tipoReq = await tx.dim_tipo_requerimiento.findFirst({
      where: {
        id_tipo_req: tipoReqId,
        id_area: areaId,
      },
      select: {
        id_tipo_req: true,
        id_area: true,
      },
    });

    if (!tipoReq) {
      throw new Error(
        "El tipo de requerimiento seleccionado no pertenece al área elegida.",
      );
    }

    /**
     * 2. Validar que el ticket aún está disponible para redirección.
     *
     * Si ya tiene área destino, no se debe redirigir otra vez desde esta vista.
     */
    const ticket = await tx.fact_ticket.findFirst({
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
      },
    });

    if (!ticket) {
      throw new Error(
        "El ticket no existe, ya fue redirigido o no está disponible para redirección.",
      );
    }

    /**
     * 3. Resolver encargado interno.
     *
     * La regla explícita de helpdesk.routing_rule tiene prioridad.
     * Si no existe regla activa para ese id_tipo_req, se usa el encargado
     * general del área legacy seleccionada.
     *
     * Se usa SQL directo para evitar depender de nombres de relaciones Prisma
     * recién introspectadas.
     */
    const encargadoRows = await tx.$queryRaw<{ encargado_interno: string | null }[]>`
      SELECT
          COALESCE(rr.encargado_interno, a.encargado_recepcion) AS encargado_interno
      FROM helpdesk.dim_tipo_requerimiento tr
      JOIN core.dim_area a
          ON a.id_area = tr.id_area
      LEFT JOIN helpdesk.routing_rule rr
          ON rr.id_tipo_req = tr.id_tipo_req
         AND rr.activo = TRUE
      WHERE tr.id_tipo_req = ${tipoReqId}::uuid
        AND tr.id_area = ${areaId}::uuid
      LIMIT 1;
    `;

    const encargadoInterno = encargadoRows[0]?.encargado_interno ?? null;

    /**
     * 4. Actualizar el ticket.
     *
     * Se usa SQL directo porque la columna encargado_interno puede no existir
     * todavía en el cliente Prisma generado si no se ha ejecutado db pull.
     */
    await tx.$executeRaw`
      UPDATE helpdesk.fact_ticket
      SET
          id_area_destino = ${areaId}::uuid,
          id_tipo_req = ${tipoReqId}::uuid,
          encargado_interno = ${encargadoInterno ?? ""}::text,
          ultima_actualizacion = NOW()
      WHERE id_ticket = ${ticketId}::uuid
        AND origen_sistema = 'PORTAL_CLIENTE'
        AND id_area_destino IS NULL;
    `;

    /**
     * 5. Insertar intención de sincronización.
     *
     * La sincronización real hacia SharePoint todavía no existe.
     * Este registro deja la tarea lista para n8n.
     *
     * El ON CONFLICT usa el índice parcial:
     * uq_ticket_sync_outbox_pending_operation
     *
     * Evita duplicar CREATE_TICKET si por alguna razón se reintenta la acción.
     */
    await tx.$executeRaw`
      INSERT INTO helpdesk.ticket_sync_outbox (
          id_ticket,
          operation,
          status,
          target_system,
          payload
      )
      VALUES (
          ${ticketId}::uuid,
          'CREATE_TICKET',
          'PENDING',
          'SHAREPOINT',
          jsonb_build_object(
              'source', 'CORAJE_PORTAL',
              'id_ticket', ${ticketId}::text,
              'id_area_destino', ${areaId}::text,
              'id_tipo_req', ${tipoReqId}::text,
              'encargado_interno', ${encargadoInterno}::text
          )
      )
      ON CONFLICT (id_ticket, operation)
      WHERE status IN ('PENDING', 'PROCESSING')
      DO NOTHING;
    `;
  });

  redirect("/redireccion");
}