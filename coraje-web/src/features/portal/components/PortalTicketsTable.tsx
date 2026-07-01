type PortalTicket = {
  id_ticket: string;
  codigo_ticket: string;
  descripcion_problema: string;
  fecha_creacion: Date;
  fecha_limite: Date | null;
  fecha_resolucion: Date | null;
  respuesta_final: string | null;
  id_area_destino: string | null;
  id_tipo_req: string | null;
  dim_estado: {
    nombre_estado: string;
  };
};

type PortalTicketsTableProps = {
  tickets: PortalTicket[];
  deleteAction: (formData: FormData) => Promise<void>;
};

/**
 * Formatea fechas para la vista de cliente.
 */
function formatDate(date: Date | null): string {
  if (!date) {
    return "Sin fecha";
  }

  return date.toLocaleDateString("es-CO", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
}

/**
 * Traduce el estado técnico a una etiqueta entendible para cliente.
 *
 * Si el ticket está abierto pero aún no tiene área destino, se muestra como
 * "Recibido", porque desde la perspectiva del cliente el requerimiento fue
 * recibido por el portal pero todavía no entró al flujo legacy.
 */
function getClientVisibleStatus(ticket: PortalTicket): string {
  const estado = ticket.dim_estado.nombre_estado.toUpperCase();

  if (estado === "CERRADO") {
    return "Cerrado";
  }

  if (!ticket.id_area_destino) {
    return "Recibido";
  }

  return "Abierto";
}

/**
 * Determina si el cliente puede eliminar el ticket desde el portal.
 *
 * Regla visual:
 * - solo tickets abiertos;
 * - sin área destino;
 * - sin tipo de requerimiento.
 *
 * La validación destructiva real vive en la server action. Esta función solo
 * decide si se muestra el botón en la tabla.
 */
function canDeleteFromPortal(ticket: PortalTicket): boolean {
  const estado = ticket.dim_estado.nombre_estado.toUpperCase();

  return (
    estado === "ABIERTO" &&
    ticket.id_area_destino === null &&
    ticket.id_tipo_req === null
  );
}

/**
 * Tabla de tickets visible para el cliente seleccionado.
 *
 * Esta vista muestra únicamente tickets creados desde el portal, según el
 * filtro aplicado en getPortalTickets. No debe mostrar histórico legacy
 * mientras el acceso siga siendo temporal/falso.
 */
export function PortalTicketsTable({
  tickets,
  deleteAction,
}: PortalTicketsTableProps) {
  if (tickets.length === 0) {
    return (
      <div className="rounded-[20px] border border-dashed border-[#e2e8f0] bg-white p-10 text-center text-sm font-semibold text-[#718096] shadow-[var(--card-shadow)]">
        Este cliente todavía no tiene tickets creados.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-[20px] border border-[#e2e8f0] bg-white shadow-[var(--card-shadow)]">
      <div className="max-h-[650px] overflow-auto">
        <table className="min-w-full border-collapse text-sm">
          <thead className="sticky top-0 z-10 bg-[#00a9ce] text-left text-xs font-bold uppercase tracking-wide text-white">
            <tr>
              <th className="whitespace-nowrap px-5 py-4">Código</th>
              <th className="whitespace-nowrap px-5 py-4">Requerimiento</th>
              <th className="whitespace-nowrap px-5 py-4">Creación</th>
              <th className="whitespace-nowrap px-5 py-4">Fecha límite</th>
              <th className="whitespace-nowrap px-5 py-4">Estado</th>
              <th className="whitespace-nowrap px-5 py-4">Resolución</th>
              <th className="whitespace-nowrap px-5 py-4">Respuesta</th>
              <th className="whitespace-nowrap px-5 py-4">Acciones</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-[#e2e8f0]">
            {tickets.map((ticket) => (
              <tr
                key={ticket.id_ticket}
                className="border-l-4 border-transparent text-zinc-700 transition hover:scale-[1.002] hover:border-[#00a9ce] hover:bg-[#f0f9ff]"
              >
                <td className="whitespace-nowrap px-5 py-4 font-mono text-xs font-bold text-[#001871]">
                  {ticket.codigo_ticket}
                </td>

                <td className="max-w-xl px-5 py-4 font-semibold text-zinc-900">
                  <span className="line-clamp-2">
                    {ticket.descripcion_problema}
                  </span>
                </td>

                <td className="whitespace-nowrap px-5 py-4 font-medium text-[#718096]">
                  {formatDate(ticket.fecha_creacion)}
                </td>

                <td className="whitespace-nowrap px-5 py-4 font-medium text-[#718096]">
                  {formatDate(ticket.fecha_limite)}
                </td>

                <td className="px-5 py-4">
                  <span className="inline-flex rounded-full border border-[#e2e8f0] bg-[#edf2f7] px-3 py-1 text-xs font-bold text-[#4a5568]">
                    {getClientVisibleStatus(ticket)}
                  </span>
                </td>

                <td className="whitespace-nowrap px-5 py-4 font-medium text-[#718096]">
                  {formatDate(ticket.fecha_resolucion)}
                </td>

                <td className="max-w-md px-5 py-4 text-sm font-medium text-[#718096]">
                  {ticket.respuesta_final ?? "Sin respuesta todavía"}
                </td>

                <td className="whitespace-nowrap px-5 py-4">
                  {canDeleteFromPortal(ticket) ? (
                    <form action={deleteAction}>
                      <button
                        type="submit"
                        name="ticketId"
                        value={ticket.id_ticket}
                        className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs font-bold text-red-700 transition hover:bg-red-100"
                      >
                        Eliminar
                      </button>
                    </form>
                  ) : (
                    <span className="text-xs font-semibold text-zinc-400">
                      No disponible
                    </span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}