"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { CLIENT_COOKIE_NAME } from "@/features/portal/data/getSelectedClient";

/**
 * Valida de forma mínima que el valor tenga forma de UUID.
 *
 * Esto no reemplaza autenticación real. Solo evita guardar basura evidente
 * en la cookie temporal del login falso.
 */
function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value,
  );
}

/**
 * Selecciona cliente para el portal.
 *
 * Login falso:
 * - no hay contraseña;
 * - no hay autenticación real;
 * - solo se guarda el cliente seleccionado en cookie.
 */
export async function selectClientAction(formData: FormData) {
  const clientId = String(formData.get("clientId") ?? "");

  if (!isUuid(clientId)) {
    throw new Error("Cliente inválido.");
  }

  const cookieStore = await cookies();

  cookieStore.set(CLIENT_COOKIE_NAME, clientId, {
    path: "/portal",
    httpOnly: true,
    sameSite: "lax",
  });

  redirect("/portal/tickets");
}

/**
 * Limpia el cliente seleccionado.
 *
 * Se usa desde /portal/tickets para volver al selector falso de cliente.
 */
export async function clearSelectedClientAction() {
  const cookieStore = await cookies();

  cookieStore.delete(CLIENT_COOKIE_NAME);

  redirect("/portal");
}