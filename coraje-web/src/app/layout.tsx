import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";

import "./globals.css";

/**
 * Fuente principal del sistema.
 *
 * Se declara como variable CSS para permitir que Tailwind/CSS global la reutilice
 * sin acoplar los componentes a la API de next/font.
 */
const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

/**
 * Fuente monoespaciada para contenido técnico, IDs, consecutivos, logs
 * o bloques donde la legibilidad de caracteres sea importante.
 */
const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

/**
 * Metadata global de la aplicación.
 *
 * Esto debe dejar de ser plantilla de Next. CORAJE necesita identidad propia
 * desde el primer layout porque será portal operativo, no demo.
 */
export const metadata: Metadata = {
  title: "CORAJE",
  description: "Portal operativo para gestión de requerimientos y tickets.",
};

/**
 * Layout raíz de la aplicación.
 *
 * En Next.js App Router, este componente debe envolver toda la aplicación
 * con las etiquetas html/body. No ponerlas rompe la estructura esperada
 * del documento y puede producir errores de hidratación o renderizado.
 */
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es">
      <body className={`${geistSans.variable} ${geistMono.variable}`}>
        {children}
      </body>
    </html>
  );
}