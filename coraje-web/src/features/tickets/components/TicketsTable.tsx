import type { TicketListItem } from "../types";

type TicketsTableProps = {
  tickets: TicketListItem[];
};

/**
 * Tabla operativa de tickets.
 *
 * Este componente es intencionalmente presentacional:
 * - no consulta base de datos;
 * - no conoce Prisma;
 * - no decide límites ni filtros;
 * - solo renderiza el contrato recibido.
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
              <th className="px-4 py-3">SP</th>
              <th className="px-4 py-3">Título</th>
              <th className="px-4 py-3">Cliente</th>
              <th className="px-4 py-3">Área</th>
              <th className="px-4 py-3">Estado</th>
              <th className="px-4 py-3">Prioridad</th>
              <th className="px-4 py-3">Creación</th>
            </tr>
          </thead>

          <tbody className="divide-y divide-zinc-100">
            {tickets.map((ticket) => (
              <tr
                key={ticket.idTicket}
                className="text-zinc-700 hover:bg-zinc-50"
              >
                <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-zinc-500">
                  {ticket.consecutivoSp}
                </td>

                <td className="max-w-md px-4 py-3 font-medium text-zinc-900">
                  {ticket.titulo}
                </td>

                <td className="px-4 py-3">{ticket.cliente}</td>
                <td className="px-4 py-3">{ticket.area}</td>

                <td className="px-4 py-3">
                  <span className="rounded-full bg-zinc-100 px-2.5 py-1 text-xs font-medium text-zinc-700">
                    {ticket.estado}
                  </span>
                </td>

                <td className="px-4 py-3">{ticket.prioridad}</td>

                <td className="whitespace-nowrap px-4 py-3 text-zinc-500">
                  {ticket.fechaCreacion.toLocaleDateString("es-CO")}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
