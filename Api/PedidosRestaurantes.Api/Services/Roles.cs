namespace PedidosRestaurantes.Api.Services;

// Nombres de los roles tal como están en seguridad.Rol.
// Se usan en [Authorize(Roles = ...)] para no escribir el texto a mano en cada controller.
public static class Roles
{
    public const string AdminPlataforma = "AdminPlataforma";
    public const string AdminRestaurante = "AdminRestaurante";
    public const string EmpleadoSede = "EmpleadoSede";
    public const string Cliente = "Cliente";
}
