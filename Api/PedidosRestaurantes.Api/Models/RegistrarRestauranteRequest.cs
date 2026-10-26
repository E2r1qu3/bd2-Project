namespace PedidosRestaurantes.Api.Models;

public record RegistrarRestauranteRequest(
    string Nombre,
    string CedulaJuridica,
    string Correo,
    string? Telefono,
    int PlanId,
    string CorreoAdmin,
    string ContrasenaAdmin);