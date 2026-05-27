import { prisma } from "@/lib/prisma";

export default async function TicketsPage() {
    const tickets = await prisma.fact_ticket.findMany({
        take: 10,
        orderBy: {
            fecha_creacion: "desc",
        },
        select: {
            id_ticket: true,
            consecutivo_sp: true,
            titulo_ticket: true,
            fecha_creacion: true,
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
        },
    });

    return (
        <main className="min-h-screen bg-slate-950 px-8 py-10 text-slate-100">
            <section className="mx-auto max-w-6xl">
                <div className="mb-8">
                    <p className="text-sm font-semibold uppercase tracking-[0.2em] text-cyan-400">
                        CORAJE / Helpdesk
                    </p>
                    <h1 className="mt-2 text-3xl font-bold tracking-tight">
                        Tickets reales desde PostgreSQL
                    </h1>
                    <p className="mt-2 text-sm text-slate-400">
                        Primera lectura server-side usando Prisma Client.
                    </p>
                </div>

                <div className="overflow-hidden rounded-2xl border border-slate-800 bg-slate-900 shadow-xl">
                    <table className="w-full border-collapse text-left text-sm">
                        <thead className="bg-slate-800 text-xs uppercase tracking-wide text-slate-300">
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

                        <tbody>
                            {tickets.map((ticket) => (
                                <tr
                                    key={ticket.id_ticket}
                                    className="border-t border-slate-800 hover:bg-slate-800/60"
                                >
                                    <td className="px-4 py-3 font-mono text-slate-300">
                                        {ticket.consecutivo_sp}
                                    </td>
                                    <td className="px-4 py-3 font-medium">
                                        {ticket.titulo_ticket}
                                    </td>
                                    <td className="px-4 py-3 text-slate-300">
                                        {ticket.dim_cliente_contai?.nombre_cliente ?? "Sin cliente"}
                                    </td>
                                    <td className="px-4 py-3 text-slate-300">
                                        {ticket.dim_area?.nombre_area ?? "Sin área"}
                                    </td>
                                    <td className="px-4 py-3">
                                        <span className="rounded-full bg-cyan-500/10 px-3 py-1 text-xs font-semibold text-cyan-300">
                                            {ticket.dim_estado.nombre_estado}
                                        </span>
                                    </td>
                                    <td className="px-4 py-3 text-slate-300">
                                        {ticket.dim_prioridad?.nombre_prioridad ?? "Sin prioridad"}
                                    </td>
                                    <td className="px-4 py-3 text-slate-400">
                                        {ticket.fecha_creacion.toLocaleDateString("es-CO")}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </section>
        </main>
    );
}