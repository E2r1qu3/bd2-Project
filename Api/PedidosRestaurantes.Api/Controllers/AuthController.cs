using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly SqlExecutor _db;
    
    public AuthController(SqlExecutor db)
    {
        _db = db;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        try
        {
            var usuario = await _db.QuerySingleOrDefaultAsync<UsuarioDto>("seguridad.sp_Login", request);
            return Ok(usuario);
        }
        catch (SqlException ex) when (ex.Number == 50010)
        {
            return Unauthorized(new { mensaje = ex.Message });
        }
        catch (SqlException ex) when (ex.Number == 50011)
        {
            return StatusCode(423, new { mensaje = ex.Message });
        }
    }

    [HttpPost("registro")]
    public async Task<IActionResult> Registro(RegistroRequest request)
    {
        try
        {
            var usuarioId = await _db.QuerySingleOrDefaultAsync<int>("seguridad.sp_RegistrarUsuario", request);
            return Ok(new { usuarioId });
        }
        catch (SqlException ex) when (ex.Number == 50001)
        {
            return Conflict(new { mensaje = ex.Message });
        }
        catch (SqlException ex) when (ex.Number is 50002 or 50003)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
    }
}