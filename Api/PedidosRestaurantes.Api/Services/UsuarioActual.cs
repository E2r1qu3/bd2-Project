using System.Security.Claims;

namespace PedidosRestaurantes.Api.Services;

// Lee los datos del usuario que vienen dentro del token (los claims que puso JwtService).
// En un controller se usa así: User.UsuarioId(), User.ClienteId(), etc.
public static class UsuarioActual
{
    public static int UsuarioId(this ClaimsPrincipal user) =>
        int.Parse(user.FindFirst(ClaimTypes.NameIdentifier)!.Value);

    public static int? ClienteId(this ClaimsPrincipal user) => LeerEntero(user, "ClienteId");

    public static int? SedeId(this ClaimsPrincipal user) => LeerEntero(user, "SedeId");

    public static int? RestauranteId(this ClaimsPrincipal user) => LeerEntero(user, "RestauranteId");

    private static int? LeerEntero(ClaimsPrincipal user, string claim) =>
        int.TryParse(user.FindFirst(claim)?.Value, out var valor) ? valor : null;
}
