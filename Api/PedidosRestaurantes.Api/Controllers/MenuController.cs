using Microsoft.AspNetCore.Mvc;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Controllers;

// Comparte la ruta api/sedes con SedesController; aquí solo va el menú.
[ApiController]
[Route("api/sedes")]
public class MenuController : ControllerBase
{
    private readonly SqlExecutor _db;

    public MenuController(SqlExecutor db)
    {
        _db = db;
    }

    // GET api/sedes/{id}/menu
    [HttpGet("{id:int}/menu")]
    public async Task<IActionResult> ObtenerMenu(int id)
    {
        var menu = await _db.QueryAsync<MenuItemDto>(
            "menu.sp_ObtenerMenuPorSede",
            new { SedeId = id });

        return Ok(menu);
    }
}