using System.Security.Claims;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Services;

// Revisa si el usuario del token puede operar sobre un pedido específico:
//   - Cliente:          solo sus propios pedidos.
//   - EmpleadoSede:     solo los pedidos de su sede.
//   - AdminRestaurante: solo los pedidos de las sedes de su restaurante.
//   - AdminPlataforma:  todos.
// Si el pedido no existe devuelve true: así el SP responde con su propio error (pedido no existe).
public class AccesoPedidos
{
    private readonly SqlExecutor _db;

    public AccesoPedidos(SqlExecutor db)
    {
        _db = db;
    }

    public async Task<bool> PuedeOperarAsync(int pedidoId, ClaimsPrincipal user)
    {
        if (user.IsInRole(Roles.AdminPlataforma))
            return true;

        var pedido = await _db.QuerySingleOrDefaultAsync<PedidoAccesoDto>(
            "ventas.sp_ObtenerPedidoPorId", new { PedidoId = pedidoId });

        if (pedido is null)
            return true;

        if (user.IsInRole(Roles.Cliente))
            return pedido.ClienteId == user.ClienteId();

        if (user.IsInRole(Roles.EmpleadoSede))
            return pedido.SedeId == user.SedeId();

        if (user.IsInRole(Roles.AdminRestaurante))
        {
            var sede = await _db.QuerySingleOrDefaultAsync<SedeDto>(
                "core.sp_ObtenerSedePorId", new { SedeId = pedido.SedeId });
            return sede is not null && sede.RestauranteId == user.RestauranteId();
        }

        return false;
    }
}
