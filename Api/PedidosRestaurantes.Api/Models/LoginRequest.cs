// Ejemplo de modelo: lo que el cliente manda en el cuerpo (JSON) de POST /api/auth/login.
//
//   { "correo": "admin@artesanos.cr", "contrasena": "Prueba123!" }
//
// Los nombres de las propiedades coinciden con los parámetros de seguridad.sp_Login
// (@Correo y @Contrasena), así Dapper los pasa directo al SP.
// Usa este archivo como guía para crear los demás modelos (Paso 3 de la guía).

namespace PedidosRestaurantes.Api.Models;

public record LoginRequest(string Correo, string Contrasena);
