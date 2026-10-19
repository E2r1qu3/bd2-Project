namespace PedidosRestaurantes.Api.Models;

public class UsuarioDto
{
    public int UsuarioId { get; set; }
    public string Correo { get; set; } = "";
    public byte RolId { get; set; }
    public string Rol { get; set; } = "";
    public int? RestauranteId { get; set; }
    public int? SedeId { get; set; }
    public int? ClienteId { get; set; }
    public DateTime? UltimoAcceso { get; set; }
}