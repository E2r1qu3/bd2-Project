// CancelacionPedidoDto.cs
namespace PedidosRestaurantes.Api.Models;

public class CancelacionPedidoDto
{
    public int PedidoId { get; set; }
    public byte EstadoId { get; set; }
    public string Estado { get; set; } = string.Empty;
    public int PagosReembolsados { get; set; }
}