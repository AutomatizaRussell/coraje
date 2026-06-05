import type { TicketListItem } from "../types";

type TicketKpiCardsProps = {
  tickets: TicketListItem[];
};

/**
 * KPIs iniciales de la vista de tickets.
 *
 * Advertencia:
 * Estos indicadores se calculan sobre los tickets visibles en pantalla.
 * Más adelante deben reemplazarse por consultas agregadas reales contra
 * PostgreSQL para representar toda la base y no solo la muestra actual.
 */
export function TicketKpiCards({ tickets }: TicketKpiCardsProps) {
  const total = tickets.length;

  const cerrados = tickets.filter(
    (ticket) =>
      ticket.estado.toUpperCase().includes("CERRADO") ||
      ticket.fechaResolucion !== null,
  ).length;

  const abiertos = total - cerrados;
  const cumplimiento = total > 0 ? (cerrados / total) * 100 : 0;

  return (
    <section className="grid gap-6 md:grid-cols-3">
      <article className="rounded-[20px] border-l-[6px] border-[#00a9ce] bg-white p-7 shadow-[var(--card-shadow)] transition hover:-translate-y-1 hover:shadow-[var(--card-shadow-hover)]">
        <p className="text-sm font-bold uppercase tracking-wider text-[#718096]">
          % de Cierre
        </p>
        <p className="mt-3 bg-gradient-to-r from-[#001871] to-[#00a9ce] bg-clip-text text-5xl font-black text-transparent">
          {cumplimiento.toFixed(1)}%
        </p>
        <p className="mt-2 text-sm font-semibold text-zinc-400">
          Sobre tickets visibles
        </p>
      </article>

      <article className="rounded-[20px] border-l-[6px] border-[#ed8b00] bg-white p-7 shadow-[var(--card-shadow)] transition hover:-translate-y-1 hover:shadow-[var(--card-shadow-hover)]">
        <p className="text-sm font-bold uppercase tracking-wider text-[#718096]">
          Tickets Abiertos
        </p>
        <p className="mt-3 bg-gradient-to-r from-[#cc7700] to-[#ed8b00] bg-clip-text text-5xl font-black text-transparent">
          {abiertos}
        </p>
        <p className="mt-2 text-sm font-semibold text-zinc-400">
          Pendientes o sin resolución
        </p>
      </article>

      <article className="rounded-[20px] border-l-[6px] border-[#001871] bg-white p-7 shadow-[var(--card-shadow)] transition hover:-translate-y-1 hover:shadow-[var(--card-shadow-hover)]">
        <p className="text-sm font-bold uppercase tracking-wider text-[#718096]">
          Total Visible
        </p>
        <p className="mt-3 bg-gradient-to-r from-[#001871] to-[#00a9ce] bg-clip-text text-5xl font-black text-transparent">
          {total}
        </p>
        <p className="mt-2 text-sm font-semibold text-zinc-400">
          Últimos registros cargados
        </p>
      </article>
    </section>
  );
}