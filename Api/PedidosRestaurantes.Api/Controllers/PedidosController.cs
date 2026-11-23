using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;
using PedidosRestaurantes.Api.Services;

namespace PedidosRestaurantes.Api.Controllers;

[ApiController]
[Route("api/pedidos")]
public class PedidosController : ControllerBase
{
    private readonly SqlExecutor _db;

    // Convierte los nombres a camelCase: ProductoId -> productoId
    private static readonly JsonSerializerOptions JsonOpciones = new(JsonSerializerDefaults.Web);

    public PedidosController(SqlExecutor db)
    {
        _db = db;
    }

    // POST api/pedidos: solo un cliente, y solo a su propio nombre.
    [Authorize(Roles = Roles.Cliente)]
    [HttpPost]
    public async Task<IActionResult> Crear(CrearPedidoRequest request)
    {
        if (request.ClienteId != User.ClienteId())
            return StatusCode(403, new { mensaje = "Solo puede crear pedidos a su propio nombre." });

        try
        {
            string lineasJson = JsonSerializer.Serialize(request.Lineas, JsonOpciones);

            var pedido = await _db.QuerySingleOrDefaultAsync<PedidoCreadoDto>(
                "ventas.sp_CrearPedido",
                new
                {
                    request.ClienteId,
                    request.SedeId,
                    request.ModalidadId,
                    request.DireccionId,
                    Lineas = lineasJson,
                    request.Notas
                });

            return Ok(pedido);
        }
        catch (SqlException ex) when (ex.Number >= 51001 && ex.Number <= 51007)
        {
            return BadRequest(new { error = ex.Number, mensaje = ex.Message });
        }
    }
}
