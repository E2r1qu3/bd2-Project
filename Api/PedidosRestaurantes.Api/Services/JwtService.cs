using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using PedidosRestaurantes.Api.Models;

namespace PedidosRestaurantes.Api.Services;

// Genera el token JWT que recibe el usuario al hacer login.
// La configuración (emisor, audiencia, vencimiento) está en appsettings.json, sección "Jwt".
// La clave secreta va solo en appsettings.Development.json, que no se sube a GitHub.
public class JwtService
{
    private readonly IConfiguration _config;

    public JwtService(IConfiguration config)
    {
        _config = config;
    }

    public (string Token, DateTime Expira) GenerarToken(UsuarioDto usuario)
    {
        var jwt = _config.GetSection("Jwt");

        // 1. Datos que viajan dentro del token (claims).
        //    ClaimTypes.Role es el que usa [Authorize(Roles = "...")] para revisar permisos.
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, usuario.UsuarioId.ToString()),
            new(ClaimTypes.Email, usuario.Correo),
            new(ClaimTypes.Role, usuario.Rol)
        };

        if (usuario.RestauranteId is not null)
            claims.Add(new Claim("RestauranteId", usuario.RestauranteId.Value.ToString()));
        if (usuario.SedeId is not null)
            claims.Add(new Claim("SedeId", usuario.SedeId.Value.ToString()));
        if (usuario.ClienteId is not null)
            claims.Add(new Claim("ClienteId", usuario.ClienteId.Value.ToString()));

        // 2. Firma con la clave secreta (HS256 exige una clave de al menos 32 caracteres).
        var clave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Clave"]!));
        var credenciales = new SigningCredentials(clave, SecurityAlgorithms.HmacSha256);

        // 3. Token con fecha de vencimiento.
        var expira = DateTime.UtcNow.AddMinutes(jwt.GetValue<int>("MinutosExpiracion"));

        var token = new JwtSecurityToken(
            issuer: jwt["Emisor"],
            audience: jwt["Audiencia"],
            claims: claims,
            expires: expira,
            signingCredentials: credenciales);

        return (new JwtSecurityTokenHandler().WriteToken(token), expira);
    }
}
