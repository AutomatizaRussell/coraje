import Image from "next/image";
import type { ReactNode } from "react";

type AppShellProps = {
  children: ReactNode;
};

/**
 * Layout visual principal de CORAJE.
 *
 * Centraliza la identidad visual común de la aplicación:
 * - encabezado corporativo;
 * - línea superior degradada;
 * - contenedor principal;
 * - fondo claro institucional.
 *
 * Este componente no contiene lógica de negocio, autenticación ni consultas.
 * Su responsabilidad es exclusivamente estructural y visual.
 */
export function AppShell({ children }: AppShellProps) {
  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top_left,#ffffff,#f4f7fa_100%)]">
      <header className="sticky top-0 z-50 border-b border-[#e2e8f0] bg-white/95 shadow-[0_4px_20px_rgba(0,0,0,0.03)] backdrop-blur">
        <div className="h-1 bg-gradient-to-r from-[#001871] via-[#00a9ce] to-[#ed8b00]" />

        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-4">
            <Image
              src="/rb-logo.png"
              alt="Logotipo Russell Bedford"
              width={150}
              height={50}
              priority
              className="h-12 w-auto object-contain"
            />

            <div className="hidden h-10 w-px bg-zinc-200 md:block" />

            <div className="hidden md:block">
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-[#718096]">
                Plataforma operativa
              </p>
              <p className="text-sm font-semibold text-[#001871]">
                CORAJE / Helpdesk
              </p>
            </div>
          </div>

          <div className="text-right">
            <h1 className="text-xl font-extrabold tracking-tight text-[#001871]">
              Panel de Control CORAJE
            </h1>
            <p className="mt-1 text-xs font-bold uppercase tracking-wide text-[#718096]">
              Requerimientos y trazabilidad
            </p>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-6 py-8">{children}</main>
    </div>
  );
}