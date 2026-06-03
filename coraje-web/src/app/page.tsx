import { redirect } from "next/navigation";

/**
 * Entrada raíz de CORAJE.
 *
 * Mientras no exista dashboard ejecutivo, la raíz debe llevar al usuario
 * directamente a la vista operativa principal. Evitamos mantener una landing
 * falsa o una pantalla decorativa sin valor funcional.
 */
export default function HomePage() {
  redirect("/tickets");
}