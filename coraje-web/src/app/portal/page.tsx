import { AppShell } from "@/components/app/AppShell";
import { ClientSelector } from "@/features/portal/components/ClientSelector";
import { getClients } from "@/features/portal/data/getClients";

export const dynamic = "force-dynamic";

type PortalPageProps = {
  searchParams?: Promise<{
    search?: string;
  }>;
};

/**
 * Entrada temporal del portal de clientes.
 *
 * Implementa selector temporal de cliente:
 * - no solicita contraseña;
 * - permite buscar clientes activos;
 * - guarda el cliente seleccionado en cookie.
 */
export default async function PortalPage({ searchParams }: PortalPageProps) {
  const resolvedSearchParams = await searchParams;
  const search = resolvedSearchParams?.search;

  const clients = await getClients(search);

  return (
    <AppShell>
      <ClientSelector initialClients={clients} initialSearch={search ?? ""} />
    </AppShell>
  );
}