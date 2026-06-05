import Link from "next/link";

type PendingRedirectTicket = {
  id_ticket: string;
  codigo_ticket: string;
  descripcion_problema: string;
  fecha_creacion: Date;
  fecha_limite: Date | null;
  dim_cliente_contai: {
    nombre_cliente: string;
    identificacion_fiscal: string | null;
  } | null;
  dim_estado: {
    nombre_estado: string;
  };
};

type PendingRedirectTicketsTableProps = {
  tickets: PendingRedirectTicket[];
};

/**
 * Formatea fechas para la vista interna de redirección.
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
 * Tabla interna de tickets pendientes de redirección.
 *
 * Esta vista no resuelve el ticket. Solo permite al empleado entrar al detalle
 * para clasificarlo y redirigirlo hacia un área.
 */
export function PendingRedirectTicketsTable({
  tickets,
}: PendingRedirectTicketsTableProps) {
  if (tickets.length === 0) {
    return (
      <div className="rounded-[20px] border border-dashed border-[#e2e8f0] bg-white p-10 text-center text-sm font-semibold text-[#718096] shadow-[var(--card-shadow)]">
        No hay tickets pendientes de redirección.
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
              <th className="whitespace-nowrap px-5 py-4">Cliente</th>
              <th className="whitespace-nowrap px-5 py-4">Requerimiento</th>
              <th className="whitespace-nowrap px-5 py-4">Creación</th>
              <th className="whitespace-nowrap px-5 py-4">Límite</th>
              <th className="whitespace-nowrap px-5 py-4">Estado</th>
              <th className="whitespace-nowrap px-5 py-4">Acción</th>
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

                <td className="px-5 py-4">
                  <p className="font-bold text-[#001871]">
                    {ticket.dim_cliente_contai?.nombre_cliente ??
                      "Sin cliente"}
                  </p>

                  <p className="mt-1 text-xs font-semibold text-[#718096]">
                    NIT / ID:{" "}
                    {ticket.dim_cliente_contai?.identificacion_fiscal ??
                      "Sin dato"}
                  </p>
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
                    Sin redireccionar
                  </span>
                </td>

                <td className="whitespace-nowrap px-5 py-4">
                  <Link
                    href={`/redireccion/${ticket.id_ticket}`}
                    className="inline-flex rounded-xl bg-gradient-to-r from-[#ed8b00] to-[#d17a00] px-4 py-2 text-xs font-bold text-white shadow-md transition hover:-translate-y-0.5 hover:shadow-lg"
                  >
                    Redirigir
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}