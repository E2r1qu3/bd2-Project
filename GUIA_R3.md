# Guía de R3: transacciones explícitas

R3 (semana 8) pide el 80 % de los stored procedures y **transacciones explícitas**. El porcentaje ya está cubierto (83 SP); lo que falta son 6 SP de negocio que escriben en varias tablas a la vez, sus pruebas de rollback y sus endpoints en el API.

Cada integrante hace una funcionalidad completa (SP + prueba + endpoint), para que en la defensa cada uno pueda explicar una transacción de principio a fin.

## Reparto

| | Agus | José | Mila |
|---|---|---|---|
| SP con transacción | `ventas.sp_CrearPedido`<br>`core.sp_RegistrarRestaurante` | `ventas.sp_CambiarEstadoPedido`<br>`ventas.sp_CancelarPedido` | `ventas.sp_RegistrarPago` |
| SP sin transacción | — | `menu.sp_ObtenerMenuPorSede` | — |
| Endpoints | `POST /api/pedidos`<br>`POST /api/restaurantes` | `PUT /api/pedidos/{id}/estado`<br>`POST /api/pedidos/{id}/cancelar`<br>`GET /api/sedes/{id}/menu` | `POST /api/pedidos/{id}/pago`<br>`GET /api/sedes`, `GET /api/sedes/{id}` |
| Archivo SQL | `Queries PA/SP_R3_Pedido_Restaurante.sql` | `Queries PA/SP_R3_EstadoPedido_Menu.sql` | `Queries PA/SP_R3_Pago.sql` |
| Archivo de pruebas | `Pruebas/Prueba_Pedido_Restaurante.sql` | `Pruebas/Prueba_EstadoPedido.sql` | `Pruebas/Prueba_Pago.sql` |
| Controllers | `PedidosController.cs`<br>`RestaurantesController.cs` | `EstadoPedidoController.cs`<br>`MenuController.cs` | `PagosController.cs`<br>`SedesController.cs` |
| Rama | `r3-agus` | `r3-jose` | `r3-mila` |
| Números de error | 51000–51099 | 52000–52099 | 53000–53099 |

Nadie depende de otro para empezar: José y Mila prueban con el **pedido 2** de `Datos_Prueba.sql` (Carlos, Heredia, pendiente).

## Reglas para no chocar

1. Antes de empezar: `git checkout master`, `git pull` y `git checkout -b r3-<nombre>`.
2. Cada uno toca **solo sus archivos** de la tabla. Varios controllers pueden usar la misma ruta (`api/pedidos`, `api/sedes`); ASP.NET los junta.
3. Cada uno usa **su rango de números** en los `THROW`.
4. Al terminar: `git push -u origin r3-<nombre>` y Pull Request a `master`.
5. Cada uno escribe la **descripción de sus SP** para el manual: qué hace, parámetros, errores y cómo se prueba.

---

## Cómo se escribe un SP con transacción

Todos los SP de R3 siguen esta estructura:

```sql
CREATE OR ALTER PROCEDURE ventas.sp_Ejemplo
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            -- 1. Validaciones: si algo está mal, THROW y no se guarda nada
            IF NOT EXISTS (SELECT 1 FROM ventas.Pedido WHERE PedidoId = @PedidoId)
                THROW 51001, N'El pedido no existe.', 1;

            -- 2. Escrituras en varias tablas
            UPDATE ventas.Pedido SET ... WHERE PedidoId = @PedidoId;
            INSERT INTO ventas.HistorialEstadoPedido (...) VALUES (...);

        COMMIT TRANSACTION;

        -- 3. Lo que se devuelve al API
        SELECT @PedidoId AS PedidoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
```

| Pieza | Qué hace |
|---|---|
| `SET XACT_ABORT ON` | Si cualquier instrucción falla, SQL Server marca la transacción para deshacerla. Evita que quede a medias |
| `BEGIN TRANSACTION` | Desde aquí, todo es un solo paquete |
| `THROW 51001, 'mensaje', 1` | Detiene el SP con un error propio; salta al `CATCH` |
| `COMMIT TRANSACTION` | Confirma: todo se guarda de verdad |
| `ROLLBACK TRANSACTION` | Deshace todo lo que se escribió desde el `BEGIN TRANSACTION` |
| `IF @@TRANCOUNT > 0` | Solo hace rollback si hay una transacción abierta |
| `THROW;` (sin números) | Vuelve a lanzar el error original para que el API lo reciba |

**Leer y bloquear:** cuando un SP lee un dato que va a cambiar (por ejemplo el estado actual de un pedido), se lee con `WITH (UPDLOCK)`. Así, si dos personas cambian el mismo pedido al mismo tiempo, la segunda espera a que termine la primera:

```sql
SELECT @EstadoActual = EstadoId
FROM ventas.Pedido WITH (UPDLOCK)
WHERE PedidoId = @PedidoId;
```

## Cómo se escribe la prueba de rollback

La prueba tiene que demostrar que, si algo falla **después de una escritura**, no queda nada guardado. La forma es contar antes y después:

```sql
USE PedidosRestaurantes;
GO

-- Prueba: <qué se intenta y por qué debe fallar>
DECLARE @Antes INT = (SELECT COUNT(*) FROM ventas.Pedido);

BEGIN TRY
    EXEC ventas.sp_Ejemplo @PedidoId = ...;
END TRY
BEGIN CATCH
    PRINT N'Error esperado: ' + ERROR_MESSAGE();
END CATCH

SELECT @Antes AS FilasAntes,
       (SELECT COUNT(*) FROM ventas.Pedido) AS FilasDespues;   -- deben ser iguales
GO
```

Cada archivo de pruebas tiene al menos:
1. Una **prueba exitosa** (el SP funciona y se ven los cambios).
2. Una **prueba de validación** (un `THROW` propio, con el mensaje esperado).
3. Una **prueba de rollback** (falla después de escribir y los conteos quedan iguales).

Guarden una captura de cada resultado: van al manual técnico.

---

## Agus

### `ventas.sp_CrearPedido`

Crea un pedido completo con sus líneas, en una sola transacción.

**Parámetros**

| Parámetro | Tipo | Notas |
|---|---|---|
| `@ClienteId` | INT | |
| `@SedeId` | INT | |
| `@ModalidadId` | TINYINT | 1 comer aquí, 2 retiro, 3 express |
| `@DireccionId` | INT = NULL | Obligatoria si es express |
| `@Lineas` | NVARCHAR(MAX) | JSON: `[{"productoId":1,"cantidad":2,"nota":"sin cebolla"}]` |
| `@Notas` | NVARCHAR(300) = NULL | |

**Validaciones**

| Error | Cuándo |
|---|---|
| 51001 | El cliente no existe |
| 51002 | La sede no existe o está inactiva |
| 51003 | La modalidad no existe |
| 51004 | Es express y no trae dirección, o la dirección no es de ese cliente |
| 51005 | Es express y la sede no ofrece express |
| 51006 | No trae líneas |
| 51007 | Algún producto no está disponible en esa sede |

**Pasos**

1. Leer el JSON en una variable de tabla con `OPENJSON`:
   ```sql
   DECLARE @L TABLE (ProductoId INT, Cantidad SMALLINT, Nota NVARCHAR(150));
   INSERT INTO @L
   SELECT ProductoId, Cantidad, Nota
   FROM OPENJSON(@Lineas) WITH (ProductoId INT '$.productoId',
                                Cantidad SMALLINT '$.cantidad',
                                Nota NVARCHAR(150) '$.nota');
   ```
2. Validar todo lo de la tabla de arriba.
3. Calcular el precio de cada línea: `ISNULL(ps.PrecioSede, p.PrecioBase)`, uniendo `@L` con `menu.ProductoSede` y `menu.Producto`.
4. `Subtotal` = suma de cantidad × precio. `Impuesto` = `ROUND(Subtotal * 0.13, 2)` (IVA 13 %). `CostoEnvio` = 1500 si es express, 0 si no (documentar este valor como supuesto del proyecto).
5. `INSERT` en `ventas.Pedido` (estado 1, Pendiente) y guardar el id con `SCOPE_IDENTITY()`.
6. `INSERT` en `ventas.DetallePedido`; el número de línea sale de `ROW_NUMBER() OVER (ORDER BY ProductoId)`.
7. `INSERT` en `ventas.HistorialEstadoPedido` con estado 1.
8. `COMMIT` y devolver `PedidoId` y `Total`.

**Prueba de rollback:** una línea con `"cantidad": 0`. El pedido se inserta, pero el detalle choca con `CK_Detalle_Cantidad` (cantidad > 0), así que la transacción se deshace. El conteo de `ventas.Pedido` debe quedar igual.

### `core.sp_RegistrarRestaurante`

Da de alta un restaurante nuevo en la plataforma: el restaurante, su suscripción y su usuario administrador.

**Parámetros:** `@Nombre NVARCHAR(100)`, `@CedulaJuridica VARCHAR(20)`, `@Correo NVARCHAR(150)`, `@Telefono VARCHAR(20) = NULL`, `@PlanId INT`, `@CorreoAdmin NVARCHAR(150)`, `@ContrasenaAdmin NVARCHAR(128)`.

| Error | Cuándo |
|---|---|
| 51011 | Ya existe un restaurante con esa cédula jurídica |
| 51012 | El plan no existe o está inactivo |

**Pasos**

1. Validar cédula y plan.
2. `INSERT` en `core.Restaurante`.
3. `INSERT` en `core.Suscripcion` con `FechaInicio = CAST(GETDATE() AS DATE)` y estado `Activa`.
4. Crear el administrador llamando al SP que ya existe, guardando su resultado en una variable de tabla (si no, su `SELECT` sale como un resultado extra y confunde al API):
   ```sql
   DECLARE @U TABLE (UsuarioId INT);
   INSERT INTO @U
   EXEC seguridad.sp_RegistrarUsuario @Correo = @CorreoAdmin, @Contrasena = @ContrasenaAdmin,
                                      @RolId = 2, @RestauranteId = @RestauranteId;
   ```
5. `COMMIT` y devolver `RestauranteId` y `UsuarioId`.

**Prueba de rollback:** usar como `@CorreoAdmin` un correo que ya existe (`admin@artesanos.cr`). El restaurante y la suscripción se insertan, pero `sp_RegistrarUsuario` lanza el error 50001 y todo se deshace. El conteo de `core.Restaurante` debe quedar igual.

### Endpoints

| Endpoint | Cuerpo | Respuestas |
|---|---|---|
| `POST /api/pedidos` | `{ "clienteId": 1, "sedeId": 1, "modalidadId": 3, "direccionId": 1, "lineas": [ { "productoId": 1, "cantidad": 2 } ] }` | 200 `{ "pedidoId", "total" }` · 400 errores 51001–51007 |
| `POST /api/restaurantes` | `{ "nombre", "cedulaJuridica", "correo", "planId", "correoAdmin", "contrasenaAdmin" }` | 200 `{ "restauranteId", "usuarioId" }` · 409 cédula o correo repetido · 400 plan inválido |

Para `POST /api/pedidos`, el modelo recibe `lineas` como una lista de C#. El controller la convierte a texto JSON antes de mandarla al SP:

```csharp
var lineasJson = System.Text.Json.JsonSerializer.Serialize(request.Lineas);
var resultado = await _db.QuerySingleOrDefaultAsync<PedidoCreadoDto>("ventas.sp_CrearPedido",
    new { request.ClienteId, request.SedeId, request.ModalidadId, request.DireccionId,
          Lineas = lineasJson, request.Notas });
```

---

## José

### `ventas.sp_CambiarEstadoPedido`

Cambia el estado de un pedido y lo deja registrado en el historial.

**Parámetros:** `@PedidoId INT`, `@NuevoEstadoId TINYINT`, `@UsuarioId INT = NULL`, `@Comentario NVARCHAR(200) = NULL`.

| Error | Cuándo |
|---|---|
| 52001 | El pedido no existe |
| 52002 | El estado nuevo no existe |
| 52003 | El pedido ya está en un estado final (`EsFinal = 1`: Entregado o Cancelado) |
| 52004 | Se intenta pasar a Cancelado (para eso está `sp_CancelarPedido`) |
| 52005 | Se intenta pasar a "En camino" y el pedido no es express |

**Pasos**

1. Leer el estado actual y la modalidad con `WITH (UPDLOCK)`.
2. Validar.
3. `UPDATE ventas.Pedido SET EstadoId = @NuevoEstadoId`.
4. `INSERT` en `ventas.HistorialEstadoPedido` con el usuario y el comentario.
5. Si el pedido es express y tiene entrega: con "En camino" (5) poner la entrega en `EnCamino` y `FechaSalida = SYSDATETIME()`; con "Entregado" (6), en `Entregada` y `FechaEntrega = SYSDATETIME()`.
6. `COMMIT` y devolver el pedido con su estado nuevo.

**Prueba de rollback:** cambiar el pedido 2 a estado 2 con `@UsuarioId = 999`. El `UPDATE` del pedido se hace, pero el historial choca con la llave foránea del usuario y todo se deshace. El estado del pedido 2 debe seguir en 1.

### `ventas.sp_CancelarPedido`

Cancela un pedido y, si ya se había pagado, marca el pago como reembolsado.

**Parámetros:** `@PedidoId INT`, `@Motivo NVARCHAR(200)`, `@UsuarioId INT = NULL`.

| Error | Cuándo |
|---|---|
| 52011 | El pedido no existe |
| 52012 | El pedido ya está entregado o cancelado |

**Pasos**

1. Leer el estado actual con `WITH (UPDLOCK)` y validar.
2. `UPDATE` del pedido a estado 7 (Cancelado).
3. `INSERT` en el historial con el motivo como comentario.
4. `UPDATE ventas.Pago SET Estado = 'Reembolsado' WHERE PedidoId = @PedidoId AND Estado = 'Aprobado'`.
5. Si tiene entrega que no se completó, ponerla en `Fallida`.
6. `COMMIT` y devolver el pedido y cuántos pagos se reembolsaron.

### `menu.sp_ObtenerMenuPorSede` (sin transacción, solo lectura)

Devuelve el menú disponible en una sede: categoría, producto, descripción y precio final.

```sql
-- Pista: JOIN de menu.ProductoSede con menu.Producto y menu.Categoria,
-- WHERE ps.SedeId = @SedeId AND ps.Disponible = 1 AND p.Activo = 1,
-- precio = ISNULL(ps.PrecioSede, p.PrecioBase), ORDER BY c.Orden, p.Nombre
```

Probar con la sede de Heredia: no debe salir la hamburguesa vegetariana y la BBQ debe costar 6 800.

### Endpoints

| Endpoint | Cuerpo | Respuestas |
|---|---|---|
| `PUT /api/pedidos/{id}/estado` | `{ "nuevoEstadoId": 3, "usuarioId": 3, "comentario": "En cocina" }` | 200 · 404 pedido no existe · 409 estado final · 400 demás |
| `POST /api/pedidos/{id}/cancelar` | `{ "motivo": "El cliente cambió de opinión", "usuarioId": 2 }` | 200 · 404 · 409 ya entregado o cancelado |
| `GET /api/sedes/{id}/menu` | — | 200 con la lista del menú |

`MenuController` usa `[Route("api/sedes")]` y `[HttpGet("{id}/menu")]`, para no tocar el `SedesController` de Mila.

---

## Mila

### `ventas.sp_RegistrarPago`

Registra el pago de un pedido y, si estaba pendiente, lo pasa a Confirmado.

**Parámetros:** `@PedidoId INT`, `@MetodoPagoId TINYINT`, `@Monto DECIMAL(12,2)`, `@ReferenciaExterna VARCHAR(100) = NULL`, `@UsuarioId INT = NULL`.

| Error | Cuándo |
|---|---|
| 53001 | El pedido no existe |
| 53002 | El pedido está cancelado |
| 53003 | El monto no es igual al total del pedido |
| 53004 | El pedido ya tiene un pago aprobado |
| 53005 | El método de pago no existe |

**Pasos**

1. Leer el pedido (estado y total) y validar.
2. `INSERT` en `ventas.Pago` con estado `Aprobado`; guardar el id con `SCOPE_IDENTITY()`.
3. Si el pedido está en estado 1 (Pendiente): `UPDATE` a estado 2 (Confirmado) e `INSERT` en el historial con el usuario.
4. `COMMIT` y devolver `PagoId`.

**Prueba de rollback (va primero en el archivo):** pagar el pedido 2 con SINPE por 9 718, pero con `@UsuarioId = 999`. El pago se inserta, pero el historial choca con la llave foránea del usuario y todo se deshace. El conteo de `ventas.Pago` debe quedar igual y el pedido seguir pendiente.

**Prueba exitosa (después):** pagar el pedido 2 con SINPE (método 2) por 9 718 y `@UsuarioId = 3`. El pedido pasa a Confirmado y aparece en el historial. Si se corre antes que la de rollback, esa falla con 53004 (ya pagado) antes de escribir y no demuestra el rollback.

### `SedesController`

Está escrito completo en el **Paso 5** de `Api/GUIA_API.md`: `GET /api/sedes` y `GET /api/sedes/{id}`. El modelo `SedeDto` ya existe.

### Endpoint

| Endpoint | Cuerpo | Respuestas |
|---|---|---|
| `POST /api/pedidos/{id}/pago` | `{ "metodoPagoId": 2, "monto": 9718, "referenciaExterna": "SINPE-0002", "usuarioId": 3 }` | 200 `{ "pagoId" }` · 404 pedido no existe · 409 ya pagado o cancelado · 400 monto o método inválido |

---

## Orden de instalación actualizado

1. `Bd/PedidosRest.sql`
2. Todos los archivos de `Queries PA/` (incluidos los `SP_R3_...`)
3. `Bd/Datos_Prueba.sql`
4. Los archivos de `Pruebas/` (cada uno se puede correr por separado; algunas pruebas cambian datos, así que para repetirlas se vuelve a empezar desde el paso 1)

## Checklist por persona

- [ ] SP escritos y ejecutados sin error en su SQL Server
- [ ] Archivo de pruebas con prueba exitosa, de validación y de rollback
- [ ] Capturas de las pruebas
- [ ] Endpoints funcionando en Swagger, con capturas
- [ ] Descripción de cada SP para el manual
- [ ] Pull Request a `master`
