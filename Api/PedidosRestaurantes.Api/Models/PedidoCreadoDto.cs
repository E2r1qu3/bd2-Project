namespace PedidosRestaurantes.Api.Models;

public class PedidoCreadoDto
{
    public int PedidoId {get; set;}
    public decimal Subtotal { get; set; }
    public decimal Impuesto { get; set; }
    public decimal CostoEnvio { get; set; }
    public decimal Total { get; set; }
}