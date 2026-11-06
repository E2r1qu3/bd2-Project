using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Controllers;

// Comparte la ruta api/pedidos con PedidosController y PagosController: ASP.NET los junta.
[ApiController]
[Route("api/pedidos")]
public class EstadoPedidoController : ControllerBase
{
    private readonly SqlExecutor _db;

    public EstadoPedidoController(SqlExecutor db)
    {
        _db = db;
    }

    // PUT api/pedidos/{id}/estado
    [HttpPut("{id:int}/estado")]
    public async Task<IActionResult> CambiarEstado(int id, CambiarEstadoRequest request)
    {
        try
        {
            var resultado = await _db.QuerySingleOrDefaultAsync<EstadoPedidoDto>(
                "ventas.sp_CambiarEstadoPedido",
                new
                {
                    PedidoId = id,
                    request.NuevoEstadoId,
                    request.UsuarioId,
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
        catch (SqlException ex) when (ex.Number == 547)
        {
            // Llave foránea: por ejemplo, el usuarioId no existe (el SP ya deshizo todo).
            return BadRequest(new { error = ex.Number, mensaje = "Un dato relacionado no existe (por ejemplo, el usuarioId)." });
        }
    }

    // POST api/pedidos/{id}/cancelar
    [HttpPost("{id:int}/cancelar")]
    public async Task<IActionResult> Cancelar(int id, CancelarPedidoRequest request)
    {
        try
        {
            var resultado = await _db.QuerySingleOrDefaultAsync<CancelacionPedidoDto>(
                "ventas.sp_CancelarPedido",
                new
                {
                    PedidoId = id,
                    request.Motivo,
                    request.UsuarioId
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
        catch (SqlException ex) when (ex.Number == 547)
        {
            return BadRequest(new { error = ex.Number, mensaje = "Un dato relacionado no existe (por ejemplo, el usuarioId)." });
        }
    }
}