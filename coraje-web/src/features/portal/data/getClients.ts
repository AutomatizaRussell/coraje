import { prisma } from "@/lib/prisma";

/**
 * Obtiene una primera página de clientes activos para inicializar el selector.
 *
 * La búsqueda completa e incremental se hace después mediante:
 * /api/portal/clientes
 */
export async function getClients(search?: string) {
  const normalizedSearch = search?.trim();

  return prisma.dim_cliente_contai.findMany({
    where: {
      estado_cliente: true,
      ...(normalizedSearch
        ? {
            OR: [
              {
                nombre_cliente: {
                  contains: normalizedSearch,
                  mode: "insensitive",
                },
              },
              {
                identificacion_fiscal: {
                  contains: normalizedSearch,
                  mode: "insensitive",
                },
              },
              {
                grupo_economico: {
                  contains: normalizedSearch,
                  mode: "insensitive",
                },
              },
            ],
          }
        : {}),
    },
    orderBy: [
      {
        nombre_cliente: "asc",
      },
      {
        id_cliente_contai: "asc",
      },
    ],
    take: 25,
    select: {
      id_cliente_contai: true,
      nombre_cliente: true,
      identificacion_fiscal: true,
      tipo_cliente: true,
      grupo_economico: true,
    },
  });
}