// EstadoPedidoDto.cs
namespace PedidosRestaurantes.Api.Models;

public class EstadoPedidoDto
{
    public int PedidoId { get; set; }
    public byte EstadoId { get; set; }
    public string Estado { get; set; } = string.Empty;
}