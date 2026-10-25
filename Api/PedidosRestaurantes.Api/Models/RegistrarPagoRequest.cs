
namespace PedidosRestaurantes.Api.Models;

public class RegistrarPagoRequest
{
    public byte MetodoPagoId { get; set; }
    public decimal Monto { get; set; }
    public string? ReferenciaExterna { get; set; }
    public int? UsuarioId { get; set; }
}
