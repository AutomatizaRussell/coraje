/**
 * Tipo de fila que necesita la tabla de tickets.
 *
 * No exponemos directamente el modelo Prisma completo porque eso acopla
 * la UI a la estructura física de base de datos. Esta capa actúa como
 * contrato estable entre datos y presentación.
 */
export type TicketListItem = {
  idTicket: string;
  consecutivoSp: number;
  titulo: string;
  cliente: string;
  area: string;
  estado: string;
  prioridad: string;
  fechaCreacion: Date;
};
