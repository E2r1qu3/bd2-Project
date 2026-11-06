// CambiarEstadoRequest.cs
namespace PedidosRestaurantes.Api.Models;

public class CambiarEstadoRequest
{
    public byte NuevoEstadoId { get; set; }
    public int? UsuarioId { get; set; }
    public string? Comentario { get; set; }
}