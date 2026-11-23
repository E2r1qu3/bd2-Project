namespace PedidosRestaurantes.Api.Models;

// Solo las columnas de sp_ObtenerPedidoPorId que se necesitan para revisar permisos.
public class PedidoAccesoDto
{
    public int PedidoId { get; set; }
    public int ClienteId { get; set; }
    public int SedeId { get; set; }
}
