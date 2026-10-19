namespace PedidosRestaurantes.Api.Models;

public record RegistroRequest (
    string Correo,
    string Contrasena,
    byte RolId,
    int? RestauranteId,
    int? SedeId,
    int? ClienteId
);