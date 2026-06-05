import Link from "next/link";

import { AppShell } from "@/components/app/AppShell";

/**
 * Entrada raíz de CORAJE.
 *
 * Muestra dos accesos separados:
 * - Portal de clientes.
 * - Acceso interno para redirección de tickets.
 *
 * Esto evita mezclar cliente y empleado en un mismo login falso.
 */
export default function HomePage() {
  return (
    <AppShell>
      <section className="mx-auto max-w-5xl space-y-8">
        <header className="space-y-3 text-center">
          <p className="text-sm font-bold uppercase tracking-[0.18em] text-[#718096]">
            CORAJE / Helpdesk
          </p>

          <h1 className="text-4xl font-black tracking-tight text-[#001871]">
            Selecciona el tipo de acceso
          </h1>

          <p className="mx-auto max-w-2xl text-sm font-medium leading-6 text-[#718096]">
            Usa el portal de clientes para crear o consultar requerimientos. Usa
            el acceso interno únicamente si eres la persona encargada de
            redireccionar solicitudes.
          </p>
        </header>

        <div className="grid gap-6 md:grid-cols-2">
          <Link
            href="/portal"
            className="group rounded-[20px] border border-[#e2e8f0] bg-white p-8 shadow-[var(--card-shadow)] transition hover:-translate-y-1 hover:shadow-[var(--card-shadow-hover)]"
          >
            <div className="mb-6 h-1.5 w-20 rounded-full bg-[#00a9ce]" />

            <p className="text-sm font-bold uppercase tracking-wide text-[#718096]">
              Acceso cliente
            </p>

            <h2 className="mt-3 text-2xl font-black text-[#001871]">
              Portal de clientes
            </h2>

            <p className="mt-3 text-sm font-medium leading-6 text-[#718096]">
              Crear nuevos requerimientos, consultar tickets existentes y revisar
              respuestas finales.
            </p>

            <span className="mt-6 inline-flex rounded-xl bg-gradient-to-r from-[#ed8b00] to-[#d17a00] px-5 py-3 text-sm font-bold text-white shadow-md transition group-hover:-translate-y-0.5 group-hover:shadow-lg">
              Ingresar al portal
            </span>
          </Link>

          <Link
            href="/redireccion/login"
            className="group rounded-[20px] border border-[#e2e8f0] bg-white p-8 shadow-[var(--card-shadow)] transition hover:-translate-y-1 hover:shadow-[var(--card-shadow-hover)]"
          >
            <div className="mb-6 h-1.5 w-20 rounded-full bg-[#001871]" />

            <p className="text-sm font-bold uppercase tracking-wide text-[#718096]">
              Acceso interno
            </p>

            <h2 className="mt-3 text-2xl font-black text-[#001871]">
              Redirección de tickets
            </h2>

            <p className="mt-3 text-sm font-medium leading-6 text-[#718096]">
              Clasificar tickets creados por clientes, asignar área, tipo de
              requerimiento y preparar sincronización hacia SharePoint.
            </p>

            <span className="mt-6 inline-flex rounded-xl border border-[#e2e8f0] bg-white px-5 py-3 text-sm font-bold text-[#001871] shadow-[var(--card-shadow)] transition group-hover:bg-[#f8fafc]">
              Ingresar como empleado
            </span>
          </Link>
        </div>
      </section>
    </AppShell>
  );
}