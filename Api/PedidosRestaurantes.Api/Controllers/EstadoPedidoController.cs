using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;
using PedidosRestaurantes.Api.Services;

namespace PedidosRestaurantes.Api.Controllers;

// Comparte la ruta api/pedidos con PedidosController y PagosController: ASP.NET los junta.
// El UsuarioId que queda en el historial sale del token, no del body.
[ApiController]
[Route("api/pedidos")]
public class EstadoPedidoController : ControllerBase
{
    private readonly SqlExecutor _db;
    private readonly AccesoPedidos _acceso;

    public EstadoPedidoController(SqlExecutor db, AccesoPedidos acceso)
    {
        _db = db;
        _acceso = acceso;
    }

    // PUT api/pedidos/{id}/estado: el personal de la sede o el admin de su restaurante.
    [Authorize(Roles = Roles.EmpleadoSede + "," + Roles.AdminRestaurante)]
    [HttpPut("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, CambiarEstadoRequest request)
    {
        if (!await _acceso.PuedeOperarAsync(id, User))
            return StatusCode(403, new { mensaje = "No tiene permiso sobre este pedido." });

        try
        {
            var resultado = await _db.QuerySingleOrDefaultAsync<EstadoPedidoDto>(
                "ventas.sp_CambiarEstadoPedido",
                new
                {
                    PedidoId = id,
                    request.NuevoEstadoId,
                    UsuarioId = User.UsuarioId(),
                    request.Comentario
                });

            return Ok(resultado);
        }
        catch (SqlException ex) when (ex.Number >= 52001 && ex.Number <= 52099)
        {
            var cuerpo = new { error = ex.Number, mensaje = ex.Message };
            return ex.Number switch
            {
                52001 => NotFound(cuerpo),   // el pedido no existe
                52003 => Conflict(cuerpo),   // el pedido ya está en un estado final
                _ => BadRequest(cuerpo)      // 52002, 52004, 52005
            };
        }
    }

    // POST api/pedidos/{id}/cancelar: el cliente dueño del pedido, o el personal de la sede/restaurante.
    [Authorize(Roles = Roles.Cliente + "," + Roles.EmpleadoSede + "," + Roles.AdminRestaurante)]
    [HttpPost("{id:int}/cancelar")]
    public async Task<IActionResult> Cancelar(int id, CancelarPedidoRequest request)
    {
        if (!await _acceso.PuedeOperarAsync(id, User))
            return StatusCode(403, new { mensaje = "No tiene permiso sobre este pedido." });

        try
        {
            var resultado = await _db.QuerySingleOrDefaultAsync<CancelacionPedidoDto>(
                "ventas.sp_CancelarPedido",
                new
                {
                    PedidoId = id,
                    request.Motivo,
                    UsuarioId = User.UsuarioId()
                });

            return Ok(resultado);
        }
        catch (SqlException ex) when (ex.Number >= 52001 && ex.Number <= 52099)
        {
            var cuerpo = new { error = ex.Number, mensaje = ex.Message };
            return ex.Number switch
            {
                52011 => NotFound(cuerpo),   // el pedido no existe
                52012 => Conflict(cuerpo),   // ya está entregado o cancelado
                _ => BadRequest(cuerpo)
            };
        }
    }
}
