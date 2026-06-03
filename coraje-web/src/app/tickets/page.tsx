import { TicketsTable } from "@/features/tickets/components/TicketsTable";
import { getRecentTickets } from "@/features/tickets/data/getTickets";

/**
 * Página principal de tickets.
 *
 * Server Component:
 * - consulta datos directamente desde el servidor;
 * - evita API routes innecesarias;
 * - mantiene la carga inicial simple, rápida y tipada.
 */
export default async function TicketsPage() {
  const tickets = await getRecentTickets(25);

  return (
    <main className="min-h-screen bg-zinc-100 px-6 py-8">
      <section className="mx-auto max-w-7xl space-y-6">
        <header className="space-y-2">
          <p className="text-sm font-medium uppercase tracking-wide text-zinc-500">
            CORAJE / Helpdesk
          </p>

          <div className="flex flex-col justify-between gap-3 md:flex-row md:items-end">
            <div>
              <h1 className="text-3xl font-semibold tracking-tight text-zinc-950">
                Tickets
              </h1>

              <p className="mt-2 max-w-2xl text-sm text-zinc-600">
                Vista operativa inicial de requerimientos migrados desde
                SharePoint hacia PostgreSQL.
              </p>
            </div>

            <div className="rounded-lg border border-zinc-200 bg-white px-4 py-3 text-sm text-zinc-600 shadow-sm">
              Mostrando{" "}
              <span className="font-semibold text-zinc-900">
                {tickets.length}
              </span>{" "}
              tickets recientes
            </div>
          </div>
        </header>

        <TicketsTable tickets={tickets} />
      </section>
    </main>
  );
}