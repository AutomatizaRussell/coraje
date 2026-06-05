"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { REDIRECCION_COOKIE_NAME } from "@/features/redireccion/data/redireccionAuth";

/**
 * Valida la clave temporal del empleado redireccionador.
 *
 * La clave vive en REDIRECCION_PASSWORD dentro del .env.
 * Esto es una solución temporal. Más adelante debe reemplazarse por
 * autenticación real, idealmente Microsoft/Entra ID o el mecanismo corporativo.
 */
export async function loginRedireccionAction(formData: FormData) {
  const password = String(formData.get("password") ?? "");

  const expectedPassword = process.env.REDIRECCION_PASSWORD;

  if (!expectedPassword) {
    throw new Error(
      "REDIRECCION_PASSWORD no está definida en las variables de entorno.",
    );
  }

  if (password !== expectedPassword) {
    redirect("/redireccion/login?error=1");
  }

  const cookieStore = await cookies();

  cookieStore.set(REDIRECCION_COOKIE_NAME, "true", {
    path: "/redireccion",
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
  });

  redirect("/redireccion");
}

/**
 * Cierra la sesión temporal del redireccionador.
 */
export async function logoutRedireccionAction() {
  const cookieStore = await cookies();

  cookieStore.delete(REDIRECCION_COOKIE_NAME);

  redirect("/");
}