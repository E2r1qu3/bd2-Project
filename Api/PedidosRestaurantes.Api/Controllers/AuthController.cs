using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;
using PedidosRestaurantes.Api.Services;

namespace PedidosRestaurantes.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly SqlExecutor _db;
    private readonly JwtService _jwt;

    public AuthController(SqlExecutor db, JwtService jwt)
    {
        _db = db;
        _jwt = jwt;
    }

    // POST api/auth/login: abierto, es donde se obtiene el token.
    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        try
        {
            var usuario = await _db.QuerySingleOrDefaultAsync<UsuarioDto>("seguridad.sp_Login", request);

            // Si las credenciales están mal, sp_Login ya lanzó el error 50010: aquí usuario nunca es null.
            var (token, expira) = _jwt.GenerarToken(usuario!);
            return Ok(new { token, expira, usuario });
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

    // POST api/auth/registro: solo administradores crean usuarios.
    //   - AdminPlataforma: cualquier usuario.
    //   - AdminRestaurante: solo administradores o empleados de su propio restaurante.
    [Authorize(Roles = Roles.AdminPlataforma + "," + Roles.AdminRestaurante)]
    [HttpPost("registro")]
    public async Task<IActionResult> Registro(RegistroRequest request)
    {
        if (User.IsInRole(Roles.AdminRestaurante))
        {
            bool rolPermitido = request.RolId is 2 or 3;
            bool mismoRestaurante = request.RestauranteId == User.RestauranteId();

            if (!rolPermitido || !mismoRestaurante)
                return StatusCode(403, new
                {
                    mensaje = "Un administrador de restaurante solo puede crear administradores o empleados de su propio restaurante."
                });
        }

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
