// CancelarPedidoRequest.cs
using System.ComponentModel.DataAnnotations;

namespace PedidosRestaurantes.Api.Models;

public class CancelarPedidoRequest
{
    [Required]
    public string Motivo { get; set; } = string.Empty;
    public int? UsuarioId { get; set; }
}