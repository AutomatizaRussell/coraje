import type { TicketListItem } from "../types";

type TicketsTableProps = {
  tickets: TicketListItem[];
};

/**
 * Formatea fechas para visualización operativa.
 *
 * La función recibe null porque varias fechas del modelo son opcionales:
 * - fecha_limite puede faltar si no se calculó SLA.
 * - fecha_resolucion puede faltar si el ticket sigue abierto.
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
 * Tabla de tickets.
 *
 * Este componente es puramente presentacional:
 * - no conoce Prisma;
 * - no ejecuta consultas;
 * - no decide reglas de negocio;
 * - solo renderiza el DTO recibido desde la capa data.
 */
export function TicketsTable({ tickets }: TicketsTableProps) {
  if (tickets.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-zinc-300 bg-white p-8 text-center text-sm text-zinc-600">
        No hay tickets disponibles para mostrar.
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-sm">
      <div className="overflow-x-auto">
        <table className="min-w-full border-collapse text-sm">
          <thead className="bg-zinc-50 text-left text-xs font-semibold uppercase tracking-wide text-zinc-500">
            <tr>
              <th className="px-4 py-3">Código</th>
              <th className="px-4 py-3">Descripción</th>
              <th className="px-4 py-3">Cliente</th>
              <th className="px-4 py-3">Área</th>
              <th className="px-4 py-3">Tipo</th>
              <th className="px-4 py-3">Estado</th>
              <th className="px-4 py-3">Prioridad</th>
              <th className="px-4 py-3">Creación</th>
              <th className="px-4 py-3">Límite</th>
              <th className="px-4 py-3">Origen</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-zinc-100">
            {tickets.map((ticket) => (
              <tr
                key={ticket.idTicket}
                className="text-zinc-700 hover:bg-zinc-50"
              >
                <td className="whitespace-nowrap px-4 py-3 font-mono text-xs font-medium text-zinc-700">
                  {ticket.codigoTicket}
                </td>

                <td className="max-w-xl px-4 py-3 font-medium text-zinc-900">
                  <span className="line-clamp-2">{ticket.descripcion}</span>
                </td>

                <td className="px-4 py-3">{ticket.cliente}</td>
                <td className="px-4 py-3">{ticket.area}</td>

                <td className="px-4 py-3">
                  <div className="max-w-xs">
                    <p className="font-medium text-zinc-800">
                      {ticket.tipoRequerimiento}
                    </p>
                    <p className="text-xs text-zinc-500">
                      {ticket.categoria1} / {ticket.categoria2}
                    </p>
                  </div>
                </td>

                <td className="px-4 py-3">
                  <span className="rounded-full bg-zinc-100 px-2.5 py-1 text-xs font-medium text-zinc-700">
                    {ticket.estado}
                  </span>
                </td>

                <td className="px-4 py-3">{ticket.prioridad}</td>

                <td className="whitespace-nowrap px-4 py-3 text-zinc-500">
                  {formatDate(ticket.fechaCreacion)}
                </td>

                <td className="whitespace-nowrap px-4 py-3 text-zinc-500">
                  {formatDate(ticket.fechaLimite)}
                </td>

                <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-zinc-500">
                  {ticket.origenSistema}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}