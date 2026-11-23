using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;
using PedidosRestaurantes.Api.Services;

namespace PedidosRestaurantes.Api.Controllers;

[ApiController]
[Route("api/restaurantes")]
public class RestaurantesController : ControllerBase
{
    private readonly SqlExecutor _db;

    public RestaurantesController(SqlExecutor db)
    {
        _db = db;
    }

    // POST api/restaurantes: solo el administrador de la plataforma registra restaurantes nuevos.
    [Authorize(Roles = Roles.AdminPlataforma)]
    [HttpPost]
    public async Task<IActionResult> Registrar(RegistrarRestauranteRequest request)
    {
        try
        {
            var resultado = await _db.QuerySingleOrDefaultAsync<RestauranteCreadoDto>(
                "core.sp_RegistrarRestaurante", request);

            return Ok(resultado);
        }
        catch (SqlException ex) when (ex.Number == 51011 || ex.Number == 50001)
        {
            return Conflict(new { error = ex.Number, mensaje = ex.Message });
        }
        catch (SqlException ex) when (ex.Number == 51012 || ex.Number == 50002)
        {
            return BadRequest(new { error = ex.Number, mensaje = ex.Message });
        }
    }
}