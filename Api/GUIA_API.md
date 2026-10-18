# Guía para construir el API

El proyecto ya tiene la estructura y la configuración. Lo que falta lo escriben ustedes siguiendo estos pasos.

```
Api/PedidosRestaurantes.Api/
  PedidosRestaurantes.Api.csproj        ✅ listo (paquetes: SqlClient, Dapper, Swagger)
  Program.cs                            ✅ listo (arranque y configuración)
  Properties/launchSettings.json        ✅ listo (puerto 5080, abre /swagger)
  appsettings.json                      ✅ listo
  appsettings.Development.example.json  ✅ plantilla de la conexión
  Data/SqlExecutor.cs                   ✏️  Paso 2
  Models/LoginRequest.cs                ✅ ejemplo
  Models/...                            ✏️  Paso 3
  Controllers/AuthController.cs         ✏️  Paso 4
  Controllers/SedesController.cs        ✏️  Paso 5
```

## Cómo funciona

```
Swagger / App  ──HTTP + JSON──▶  Controller  ──▶  SqlExecutor  ──EXEC SP──▶  SQL Server
```

- El **Controller** recibe la petición y decide qué SP ejecutar.
- El **SqlExecutor** abre la conexión, ejecuta el SP y devuelve el resultado como objetos de C#.
- El API se conecta con **`login_api_pedidos`**, que solo puede ejecutar SP. Nunca hace `SELECT` directo a las tablas.

---

## Paso 1. Configurar la conexión

1. Verifiquen que tienen .NET instalado: `dotnet --version` (sirve 8, 9 o 10).
2. En `Api/PedidosRestaurantes.Api/`, copien `appsettings.Development.example.json` y renombren la copia a **`appsettings.Development.json`**.
3. Ajusten la cadena de conexión si hace falta:

| Compu | `Server=` |
|---|---|
| Mac con Docker | `localhost,1433` |
| Windows con SQL Server Developer | `localhost` |
| Windows con SQL Express | `localhost\SQLEXPRESS` |

La contraseña es la de `login_api_pedidos` que está en `Bd/PedidosRest.sql`.

`appsettings.Development.json` **no se sube a GitHub** (está en `.gitignore`), así cada uno tiene su propia conexión.

> **Windows:** SQL Server viene configurado solo con "Autenticación de Windows". Para que funcione `login_api_pedidos` hay que activar el modo mixto: en SSMS, clic derecho al servidor → **Properties → Security → SQL Server and Windows Authentication mode**, y reiniciar el servicio de SQL Server.

4. Prueben que arranca. En la terminal:

```bash
cd Api/PedidosRestaurantes.Api
dotnet run
```

Abran http://localhost:5080/swagger. Todavía no aparece ningún endpoint; eso es normal.

---

## Paso 2. `Data/SqlExecutor.cs`

Es la única clase que habla con SQL Server. Tiene tres partes con `TODO`.

**Constructor:** leer la cadena de conexión.
- `configuration.GetConnectionString("PedidosDb")` devuelve el texto de `appsettings.Development.json`.

**`QueryAsync<T>`:** ejecuta un SP que devuelve varias filas.
- Cambien la firma a `public async Task<IEnumerable<T>> QueryAsync<T>(...)`.
- Abran la conexión con `await using var connection = new SqlConnection(_connectionString);`
  El `using` cierra la conexión sola al terminar, aunque haya un error.
- Dapper agrega el método `QueryAsync<T>` a la conexión. Lo importante es indicar que es un SP:
  `commandType: CommandType.StoredProcedure`.

**`QuerySingleOrDefaultAsync<T>`:** igual, pero devuelve una sola fila o `null`.

**Cómo pasa Dapper los parámetros:** toma cada propiedad del objeto `parametros` y la manda como `@NombreDePropiedad`. Por eso los nombres tienen que ser iguales a los del SP:

```csharp
new { SedeId = 5 }                        // -> @SedeId = 5
new LoginRequest("a@b.cr", "Clave123!")   // -> @Correo = 'a@b.cr', @Contrasena = 'Clave123!'
```

---

## Paso 3. Modelos (`Models/`)

Un modelo es una clase con las mismas columnas que devuelve el SP (para respuestas) o los mismos parámetros que recibe (para peticiones). Usen `LoginRequest.cs` como ejemplo.

**Equivalencia de tipos SQL → C#**

| SQL Server | C# |
|---|---|
| `INT` | `int` |
| `BIGINT` | `long` |
| `TINYINT` | `byte` |
| `BIT` | `bool` |
| `DECIMAL(12,2)` | `decimal` |
| `NVARCHAR` / `VARCHAR` | `string` |
| `DATE`, `DATETIME2` | `DateTime` |
| `TIME` | `TimeSpan` |

Si la columna acepta `NULL`, agreguen `?` al tipo: `int?`, `string?`, `DateTime?`.

**Modelos que necesitan**

| Archivo | Para qué | Columnas o parámetros (miren el SP) |
|---|---|---|
| `UsuarioDto.cs` | Respuesta del login | Lo que devuelve el `SELECT` final de `seguridad.sp_Login` |
| `RegistroRequest.cs` | Cuerpo de `POST /api/auth/registro` | Parámetros de `seguridad.sp_RegistrarUsuario` |
| `SedeDto.cs` | Respuesta de sedes | Columnas de `core.sp_ObtenerSedes` |

---

## Paso 4. `Controllers/AuthController.cs`

### `POST /api/auth/login`

1. Recibe un `LoginRequest`.
2. Ejecuta `seguridad.sp_Login` con `_db.QuerySingleOrDefaultAsync<UsuarioDto>(...)`.
3. Devuelve `Ok(usuario)`.

**Errores:** cuando la contraseña está mal, el SP hace `THROW 50010`. En C# eso llega como una `SqlException` cuya propiedad `Number` es 50010. Se atrapa así:

```csharp
catch (SqlException ex) when (ex.Number == 50010)
{
    return Unauthorized(new { mensaje = ex.Message });
}
```

(Necesitan `using Microsoft.Data.SqlClient;` arriba del archivo.)

**Tabla de errores → respuesta HTTP**

| Número | Significa | Respuesta |
|---|---|---|
| 50010 | Correo o contraseña incorrectos | `Unauthorized(...)` → 401 |
| 50011 | Cuenta bloqueada | `StatusCode(423, ...)` → 423 Locked |
| 50001 | Correo ya registrado | `Conflict(...)` → 409 |
| 50002, 50003 | Datos inválidos | `BadRequest(...)` → 400 |

### `POST /api/auth/registro`

1. Recibe un `RegistroRequest`.
2. Ejecuta `seguridad.sp_RegistrarUsuario`. El SP devuelve una columna `UsuarioId`, así que pueden leerla con `QuerySingleOrDefaultAsync<int>(...)`.
3. Devuelve `Ok(new { usuarioId = id })`.
4. Atrapen 50001, 50002 y 50003 según la tabla.

---

## Paso 5. `Controllers/SedesController.cs` (archivo nuevo)

Copien la estructura de `AuthController` (atributos, constructor con `SqlExecutor`) con la ruta `api/sedes`.

| Endpoint | SP | Respuesta |
|---|---|---|
| `GET /api/sedes` | `core.sp_ObtenerSedes` | `Ok(lista)` |
| `GET /api/sedes/{id}` | `core.sp_ObtenerSedePorId` | `Ok(sede)`, o `NotFound()` si devuelve `null` |

Para el `{id}`: `[HttpGet("{id}")]` y el método recibe `int id`. Al SP se lo pasan como `new { SedeId = id }`.

**Reto opcional:** `GET /api/sedes/{id}/menu`. No existe un SP que devuelva el menú de una sede con nombres y precios, así que primero hay que escribirlo en SQL (`menu.sp_ObtenerMenuPorSede`): un `JOIN` entre `menu.ProductoSede`, `menu.Producto` y `menu.Categoria`, filtrando `Disponible = 1` y usando `ISNULL(PrecioSede, PrecioBase)` como precio.

---

## Paso 6. Probar en Swagger

```bash
cd Api/PedidosRestaurantes.Api
dotnet run
```

En http://localhost:5080/swagger, abran cada endpoint → **Try it out** → **Execute**.

| Prueba | Resultado esperado |
|---|---|
| Login con `admin@artesanos.cr` / `Prueba123!` | 200 con los datos del usuario |
| Login con contraseña equivocada | 401 |
| 5 logins equivocados seguidos y luego el correcto | 423 (cuenta bloqueada) |
| Registro con un correo que ya existe | 409 |
| `GET /api/sedes` | 200 con las 3 sedes de prueba |
| `GET /api/sedes/999` | 404 |

Para desbloquear la cuenta después de la prueba: `EXEC seguridad.sp_DesbloquearUsuario @UsuarioId = 2;`

**Evidencia de seguridad para el manual:** conéctense en VS Code con `login_api_pedidos` y ejecuten `SELECT * FROM seguridad.Usuario;`. Debe dar *"The SELECT permission was denied"*. Eso demuestra que el API solo puede ejecutar SP.

Guarden capturas de cada prueba: sirven para la guía de uso del API que pide el manual técnico.

---

## Errores comunes

| Error | Causa |
|---|---|
| `NotImplementedException` | Falta completar `SqlExecutor` (Paso 2) |
| `Login failed for user 'login_api_pedidos'` | Contraseña mal en `appsettings.Development.json`, la base no se creó, o (Windows) falta activar el modo mixto |
| `A network-related or instance-specific error` | SQL Server está apagado. En Mac: `docker start sqlserver-bd2` |
| `Could not find stored procedure` | Falta ejecutar los archivos de `Queries PA` |
| `The ConnectionString property has not been initialized` | No crearon `appsettings.Development.json` |

---

## Paso 7. Subirlo

```bash
git add .
git commit -m "API: SqlExecutor, login, registro y sedes"
git push -u origin api-r2
```

Después abren el Pull Request en GitHub igual que la vez pasada.
