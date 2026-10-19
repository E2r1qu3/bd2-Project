// Punto de arranque del API.
// Este archivo ya está completo: solo configura los servicios y arranca el servidor.
// El código que tienes que escribir está en Data/, Models/ y Controllers/ (ver Api/GUIA_API.md).

using PedidosRestaurantes.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// 1. Controladores: cada clase en Controllers/ se convierte en un grupo de endpoints.
builder.Services.AddControllers();

// 2. Swagger: genera la página http://localhost:5080/swagger para probar el API.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 3. SqlExecutor: la clase que ejecuta los stored procedures.
//    Se registra una sola vez y los controladores la reciben en su constructor.
//    La cadena de conexión sale de appsettings.Development.json (ConnectionStrings:PedidosDb).
builder.Services.AddSingleton<SqlExecutor>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();

app.Run();
