import { cookies } from "next/headers";
import { prisma } from "@/lib/prisma";

const CLIENT_COOKIE_NAME = "coraje_cliente_id";

/**
 * Lee el cliente seleccionado desde cookie.
 *
 * Esto es login falso. Sirve para prototipo funcional, no para seguridad.
 * Más adelante debe reemplazarse por autenticación real.
 */
export async function getSelectedClient() {
  const cookieStore = await cookies();
  const clientId = cookieStore.get(CLIENT_COOKIE_NAME)?.value;

  if (!clientId) {
    return null;
  }

  return prisma.dim_cliente_contai.findUnique({
    where: {
      id_cliente_contai: clientId,
    },
    select: {
      id_cliente_contai: true,
      nombre_cliente: true,
      identificacion_fiscal: true,
      tipo_cliente: true,
      grupo_economico: true,
      estado_cliente: true,
    },
  });
}

export { CLIENT_COOKIE_NAME };