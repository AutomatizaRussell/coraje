"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { prisma } from "@/lib/prisma";
import { CLIENT_COOKIE_NAME } from "@/features/portal/data/getSelectedClient";

/**
 * Valida de forma mínima un UUID recibido desde formulario.
 *
 * No restringimos versión UUID aquí porque PostgreSQL ya valida el tipo UUID
 * al hacer los casts `::uuid` en las consultas. Esta función solo evita valores
 * claramente inválidos antes de llegar a la base de datos.
 */
function assertUuid(value: string, fieldName: string) {
  const normalizedValue = value.trim();

  const isValid =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      normalizedValue,
    );

  if (!isValid) {
    throw new Error(`${fieldName} inválido: ${normalizedValue}`);
  }
}

/**
 * Elimina un ticket de prueba creado desde el portal cliente.
 *
 * Reglas estrictas:
 * - El ticket debe pertenecer al cliente seleccionado en la cookie temporal.
 * - El ticket debe haber nacido en el portal: origen_sistema = PORTAL_CLIENTE.
 * - El ticket no debe estar redirigido: id_area_destino IS NULL.
 * - El ticket no debe estar clasificado: id_tipo_req IS NULL.
 * - El ticket no debe tener sp_id en SharePoint.
 * - El ticket no debe tener sincronización PROCESSING o SENT.
 *
 * Esta acción existe para limpiar pruebas antes de que un ticket entre al flujo
 * PostgreSQL → SharePoint → PowerApps. No debe usarse para tickets ya
 * redirigidos o sincronizados.
 */
export async function deletePortalTicketAction(formData: FormData) {

  const ticketId = String(formData.get("ticketId") ?? "");

  assertUuid(ticketId, "ticketId");

  const cookieStore = await cookies();
  const clientId = cookieStore.get(CLIENT_COOKIE_NAME)?.value;

  if (!clientId) {
    redirect("/portal");
  }

  assertUuid(clientId, "clientId");

  await prisma.$transaction(async (tx) => {
    /**
     * Limpia primero intentos de outbox que aún no hayan sido enviados.
     *
     * En teoría, un ticket sin redirección no debería tener outbox, pero esta
     * eliminación defensiva evita residuos si durante pruebas se generó algún
     * registro PENDING/FAILED.
     */
    await tx.$executeRaw`
      DELETE FROM helpdesk.ticket_sync_outbox o
      USING helpdesk.fact_ticket f
      WHERE o.id_ticket = f.id_ticket
        AND f.id_ticket = ${ticketId}::uuid
        AND f.id_cliente_contai = ${clientId}::uuid
        AND f.origen_sistema = 'PORTAL_CLIENTE'
        AND f.id_area_destino IS NULL
        AND f.id_tipo_req IS NULL
        AND o.status IN ('PENDING', 'FAILED')
        AND NOT EXISTS (
            SELECT 1
            FROM helpdesk.ticket_legacy_sharepoint_ref r
            WHERE r.id_ticket = f.id_ticket
              AND r.sp_id IS NOT NULL
        )
        AND NOT EXISTS (
            SELECT 1
            FROM helpdesk.ticket_sync_outbox o2
            WHERE o2.id_ticket = f.id_ticket
              AND o2.status IN ('PROCESSING', 'SENT')
        );
    `;

    /**
     * Borrado físico seguro del ticket.
     *
     * Si el DELETE no afecta filas, no hacemos nada destructivo adicional.
     * Eso significa que el ticket no cumplía las condiciones de seguridad.
     */
    await tx.$executeRaw`
      DELETE FROM helpdesk.fact_ticket f
      WHERE f.id_ticket = ${ticketId}::uuid
        AND f.id_cliente_contai = ${clientId}::uuid
        AND f.origen_sistema = 'PORTAL_CLIENTE'
        AND f.id_area_destino IS NULL
        AND f.id_tipo_req IS NULL
        AND NOT EXISTS (
            SELECT 1
            FROM helpdesk.ticket_legacy_sharepoint_ref r
            WHERE r.id_ticket = f.id_ticket
              AND r.sp_id IS NOT NULL
        )
        AND NOT EXISTS (
            SELECT 1
            FROM helpdesk.ticket_sync_outbox o
            WHERE o.id_ticket = f.id_ticket
              AND o.status IN ('PROCESSING', 'SENT')
        );
    `;
  });

  redirect("/portal/tickets");
}