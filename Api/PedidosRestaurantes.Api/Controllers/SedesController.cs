
using Microsoft.AspNetCore.Mvc;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Controllers;

[ApiController]
[Route("api/sedes")]
public class SedesController : ControllerBase
{
    private readonly SqlExecutor _db;

    public SedesController(SqlExecutor db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> ObtenerSedes()
    {
        var sedes = await _db.QueryAsync<SedeDto>(
            "core.sp_ObtenerSedes");

        return Ok(sedes);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> ObtenerSedePorId(int id)
    {
        var sede = await _db.QuerySingleOrDefaultAsync<SedeDto>(
            "core.sp_ObtenerSedePorId",
            new { SedeId = id });

        if (sede is null)
            return NotFound();

        return Ok(sede);
    }
}
