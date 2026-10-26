namespace PedidosRestaurantes.Api.Models;

public record LineaPedidoRequest(int ProductoId, short Cantidad, string? Nota);

public record CrearPedidoRequest(
    int ClienteId,
    int SedeId,
    byte ModalidadId,
    int? DireccionId,
    List<LineaPedidoRequest> Lineas,
    string? Notas);