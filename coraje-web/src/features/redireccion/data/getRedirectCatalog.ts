import { prisma } from "@/lib/prisma";

/**
 * Obtiene el catálogo necesario para redirigir tickets.
 *
 * La dependencia funcional es:
 * área → tipo requerimiento → categoría 1 → categoría 2 opcional.
 *
 * La tabla dim_tipo_requerimiento ya contiene la combinación completa.
 * Por eso devolvemos las filas planas y el componente cliente filtra en cascada.
 */
export async function getRedirectCatalog() {
  const [areas, tiposRequerimiento] = await Promise.all([
    prisma.dim_area.findMany({
      orderBy: {
        nombre_area: "asc",
      },
      select: {
        id_area: true,
        nombre_area: true,
      },
    }),

    prisma.dim_tipo_requerimiento.findMany({
      orderBy: [
        {
          tipo_requerimiento: "asc",
        },
        {
          categoria_1: "asc",
        },
        {
          categoria_2: "asc",
        },
      ],
      select: {
        id_tipo_req: true,
        id_area: true,
        tipo_requerimiento: true,
        categoria_1: true,
        categoria_2: true,
      },
    }),
  ]);

  return {
    areas,
    tiposRequerimiento,
  };
}