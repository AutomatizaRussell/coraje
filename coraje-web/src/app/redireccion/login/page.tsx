import { redirect } from "next/navigation";

import { AppShell } from "@/components/app/AppShell";
import { isRedireccionAuthenticated } from "@/features/redireccion/data/redireccionAuth";

import { loginRedireccionAction } from "./actions";

type RedireccionLoginPageProps = {
  searchParams?: Promise<{
    error?: string;
  }>;
};

/**
 * Login temporal para el empleado redireccionador.
 *
 * Este acceso está separado del portal cliente para evitar mezclar flujos.
 * De momento se usa una clave temporal en .env.
 */
export default async function RedireccionLoginPage({
  searchParams,
}: RedireccionLoginPageProps) {
  const isAuthenticated = await isRedireccionAuthenticated();

  if (isAuthenticated) {
    redirect("/redireccion");
  }

  const resolvedSearchParams = await searchParams;
  const hasError = resolvedSearchParams?.error === "1";

  return (
    <AppShell>
      <section className="mx-auto max-w-md space-y-6">
        <header className="space-y-2 text-center">
          <p className="text-sm font-bold uppercase tracking-[0.18em] text-[#718096]">
            Acceso interno
          </p>

          <h1 className="text-3xl font-black tracking-tight text-[#001871]">
            Redirección de tickets
          </h1>

          <p className="text-sm font-medium leading-6 text-[#718096]">
            Ingresa la clave temporal para acceder a la cola de tickets creados
            desde el portal de clientes.
          </p>
        </header>

        <div className="rounded-[20px] border border-[#e2e8f0] bg-white p-6 shadow-[var(--card-shadow)]">
          <form action={loginRedireccionAction} className="space-y-6">
            <div>
              <label
                htmlFor="password"
                className="text-xs font-bold uppercase tracking-wide text-[#001871]"
              >
                Clave temporal
              </label>

              <input
                id="password"
                name="password"
                type="password"
                required
                placeholder="Ingresa la clave de redirección"
                className="mt-2 h-12 w-full rounded-xl border-2 border-[#e2e8f0] bg-[#f8fafc] px-4 text-sm font-semibold outline-none transition focus:border-[#00a9ce] focus:bg-white focus:ring-4 focus:ring-cyan-100"
              />
            </div>

            {hasError && (
              <div className="rounded-xl border border-red-200 bg-red-50 p-3 text-sm font-bold text-red-700">
                Clave incorrecta. Intenta nuevamente.
              </div>
            )}

            <button
              type="submit"
              className="w-full rounded-xl bg-gradient-to-r from-[#ed8b00] to-[#d17a00] px-5 py-3 text-sm font-bold text-white shadow-md transition hover:-translate-y-0.5 hover:shadow-lg"
            >
              Ingresar
            </button>
          </form>
        </div>
      </section>
    </AppShell>
  );
}