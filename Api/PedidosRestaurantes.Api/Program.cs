// Punto de arranque del API: configura los servicios, la autenticación con JWT y arranca el servidor.

using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PedidosRestaurantes.Api.Data;
using PedidosRestaurantes.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Controladores: cada clase en Controllers/ se convierte en un grupo de endpoints.
builder.Services.AddControllers();

// 2. Swagger (http://localhost:5080/swagger), con el botón "Authorize" para pegar el token.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Pegue solo el token, sin la palabra Bearer."
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

// 3. Servicios propios.
//    SqlExecutor ejecuta los stored procedures (conexión en appsettings.Development.json).
//    JwtService genera el token del login.
//    AccesoPedidos revisa si el usuario del token puede operar sobre un pedido.
builder.Services.AddSingleton<SqlExecutor>();
builder.Services.AddSingleton<JwtService>();
builder.Services.AddSingleton<AccesoPedidos>();

// 4. Autenticación con JWT: cómo se valida el token que llega en cada petición.
var jwt = builder.Configuration.GetSection("Jwt");
var clave = jwt["Clave"]
    ?? throw new InvalidOperationException("Falta Jwt:Clave en appsettings.Development.json (ver appsettings.Development.example.json).");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt["Emisor"],
            ValidateAudience = true,
            ValidAudience = jwt["Audiencia"],
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(clave)),
            ClockSkew = TimeSpan.Zero // el token vence a la hora exacta, sin tolerancia
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// 5. El orden importa: primero se identifica al usuario, después se revisan sus permisos.
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
