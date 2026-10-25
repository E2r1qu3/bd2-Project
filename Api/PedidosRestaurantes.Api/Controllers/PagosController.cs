
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Controllers;

[ApiController]
[Route("api/pedidos/{id}/pago")]
public class PagosController : ControllerBase
{
    private readonly SqlExecutor _db;

    public PagosController(SqlExecutor db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> RegistrarPago(
        int id,
        [FromBody] RegistrarPagoRequest request)
    {
        try
        {
            var resultado = await _db.QuerySingleOrDefaultAsync<PagoResultado>(
                "ventas.sp_RegistrarPago",
                new
                {
                    PedidoId = id,
                    request.MetodoPagoId,
                    request.Monto,
                    request.ReferenciaExterna,
                    request.UsuarioId
                });

            if (resultado is null)
            {
                return StatusCode(500, new
                {
                    mensaje = "No se recibió el identificador del pago."
                });
            }

            return Ok(new
            {
                mensaje = "Pago registrado correctamente.",
                pagoId = resultado.PagoId
            });
        }
        catch (SqlException ex)
        {
            return ex.Number switch
            {
                53001 => NotFound(new
                {
                    mensaje = ex.Message
                }),

                53002 or 53004 => Conflict(new
                {
                    mensaje = ex.Message
                }),

                53003 or 53005 => BadRequest(new
                {
                    mensaje = ex.Message
                }),

                _ => StatusCode(500, new
                {
                    mensaje = "Ocurrió un error al registrar el pago."
                })
            };
        }
        catch (Exception)
        {
            return StatusCode(500, new
            {
                mensaje = "Ocurrió un error interno al registrar el pago."
            });
        }
    }
}

public class PagoResultado
{
    public int PagoId { get; set; }
}
