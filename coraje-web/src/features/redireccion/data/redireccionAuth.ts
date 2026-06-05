import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export const REDIRECCION_COOKIE_NAME = "coraje_redireccion_auth";

/**
 * Verifica si existe la cookie temporal de acceso al módulo de redirección.
 *
 * Esto NO es autenticación final. Es una barrera temporal para evitar que
 * cualquier persona con la URL entre a la cola de redirección.
 */
export async function isRedireccionAuthenticated(): Promise<boolean> {
  const cookieStore = await cookies();

  return cookieStore.get(REDIRECCION_COOKIE_NAME)?.value === "true";
}

/**
 * Protege rutas internas de redirección.
 *
 * Si no existe cookie válida, redirige al login temporal.
 */
export async function requireRedireccionAuth() {
  const isAuthenticated = await isRedireccionAuthenticated();

  if (!isAuthenticated) {
    redirect("/redireccion/login");
  }
}