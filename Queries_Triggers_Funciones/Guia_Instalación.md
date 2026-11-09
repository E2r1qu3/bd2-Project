# PedidosRestaurantes: R4, estados del pedido e instalación

José · Proyecto Bases de Datos II · Base de datos `PedidosRestaurantes`

## 1. Estados del pedido

El campo `EstadoId` de `ventas.Pedido` apunta a `ventas.EstadoPedido`. Los estados son:

| Id | Estado | Final | Significado |
|---|---|---|---|
| 1 | Pendiente | No | Pedido creado, sin pago |
| 2 | Confirmado | No | Pedido pagado |
| 3 | En preparación | No | La cocina lo está preparando |
| 4 | Listo | No | Listo para retirar o despachar |
| 5 | En camino | No | Salió a entregarse (solo express) |
| 6 | Entregado | Sí | Pedido completado |
| 7 | Cancelado | Sí | Pedido anulado |

**Flujo normal:** Pendiente → Confirmado → En preparación → Listo → En camino (solo express) → Entregado. Un pedido que no está en estado final se puede cancelar en cualquier momento.

**Quién cambia el estado**

| Procedimiento | Cambio |
|---|---|
| `ventas.sp_CrearPedido` | Crea el pedido en Pendiente |
| `ventas.sp_RegistrarPago` | Pendiente → Confirmado |
| `ventas.sp_CambiarEstadoPedido` | Estado no final → el estado indicado (excepto Cancelado) |
| `ventas.sp_CancelarPedido` | Estado no final → Cancelado |

**Reglas que se cumplen**

- Todo cambio de estado queda en `ventas.HistorialEstadoPedido`, con el usuario y la fecha.
- Un pedido Entregado o Cancelado no cambia más de estado (`sp_CambiarEstadoPedido`, error 52003, y el trigger `trg_Pedido_EstadoFinal`, error 55002).
- Solo los pedidos express (modalidad 3) pasan a En camino (error 52005).
- Cancelar se hace solo con `sp_CancelarPedido` (error 52004 en el otro procedimiento).
- Entrega de un pedido express: En camino la marca `EnCamino` con `FechaSalida`; Entregado la marca `Entregada` con `FechaEntrega`; Cancelado marca como `Fallida` las entregas `Asignada` o `EnCamino`.
- Al cancelar, el pago `Aprobado` pasa a `Reembolsado`.

`sp_CambiarEstadoPedido` no obliga un orden estricto entre los estados no finales: el flujo normal lo siguen los usuarios y el API.

## 2. Triggers

Archivos: `Queries PA/Triggers/R4_Trigger_<nombre>.sql`. Pruebas: `Pruebas/Triggers/Prueba_R4_Trigger_<nombre>.sql`. Errores propios: rango 55000–55099.

### 2.1 `ventas.trg_HistorialEstadoPedido_SoloLectura`

- **Tabla y evento:** `ventas.HistorialEstadoPedido`, `INSTEAD OF UPDATE, DELETE`.
- **Qué hace:** impide modificar o borrar el historial de estados. Es una bitácora: solo se inserta y se consulta.
- **Error:** 55001, el historial de estados es solo de lectura.
- Si el `UPDATE` o `DELETE` no afecta filas, no hace nada.
- **Prueba:** pruebas 1 (`UPDATE`), 2 (`DELETE`) y 3 (`INSERT` permitido).
- **Límite:** `TRUNCATE TABLE` y `DROP TRIGGER` no pasan por el trigger; solo quien administra la base puede hacerlos.

### 2.2 `ventas.trg_Pedido_EstadoFinal`

- **Tabla y evento:** `ventas.Pedido`, `AFTER UPDATE`.
- **Qué hace:** si un pedido está en un estado final (`EsFinal = 1`) y se intenta cambiar su `EstadoId`, deshace la transacción y lanza el error. Los demás campos, como las notas, sí se pueden actualizar.
- **Error:** 55002.
- **Prueba:** pruebas 4 y 5.

## 3. Funciones

Archivos: `Queries PA/Funciones/R4_Fn_<nombre>.sql`. Pruebas: `Pruebas/Funciones/Prueba_R4_Fn_<nombre>.sql`.

### 3.1 `menu.fn_PrecioProductoSede(@SedeId, @ProductoId)`

- Devuelve `DECIMAL(12,2)`: el precio de la sede (`PrecioSede`) o, si no tiene, el precio base. Devuelve `NULL` si el producto no se ofrece en esa sede.
- Ejemplo: `SELECT menu.fn_PrecioProductoSede(1, 1);`
- **Prueba:** 6 (en Heredia la BBQ cuesta 6 800 y la hamburguesa vegetariana da `NULL`).

### 3.2 `ventas.fn_TotalVentasSede(@SedeId, @Desde, @Hasta)`

- Devuelve `DECIMAL(14,2)`: suma del `Total` de los pedidos de la sede entre las dos fechas (inclusive) que no están cancelados. Sin ventas devuelve 0.
- Ejemplo: `SELECT ventas.fn_TotalVentasSede(1, '2026-01-01', '2026-12-31');`
- **Prueba:** 7 (se compara con una consulta directa).

### 3.3 `ventas.fn_VentasPorSede(@RestauranteId, @Desde, @Hasta)`

- Función de tabla en línea: una fila por sede del restaurante con `SedeId`, `Sede`, `Pedidos` y `TotalVentas`, incluidas las sedes sin ventas.
- Ejemplo: `SELECT * FROM ventas.fn_VentasPorSede(1, '2026-01-01', '2026-12-31');`
- **Prueba:** 8.

## 4. Guía de instalación

### 4.1 Orden de los scripts (igual en Windows y Mac)

1. `Bd/PedidosRest.sql`: crea la base, las tablas, los roles y los datos fijos.
2. Todos los archivos de `Queries PA/`, incluidas las subcarpetas `Triggers` y `Funciones` (procedimientos de cada tabla, autenticación, R3 y R4).
3. `Bd/Datos_Prueba.sql`: datos de ejemplo.
4. Opcional: los archivos de `Pruebas/`.

`Bd/PedidosRest.sql` borra y vuelve a crear la base: no se debe correr sobre datos que se quieran conservar.

### 4.2 Windows

1. Instalar SQL Server 2022 (Developer o Express), SQL Server Management Studio (SSMS), el SDK de .NET 10, Git y, si se desea, Visual Studio.
2. Clonar el repositorio: `git clone https://github.com/E2r1qu3/bd2-Project.git`
3. En SSMS, conectarse con Windows Authentication (anotar el Server name) y ejecutar los scripts en el orden de 4.1 con Archivo → Abrir → Archivo y F5.
4. En `Api/PedidosRestaurantes.Api` copiar `appsettings.Development.example.json` como `appsettings.Development.json` y poner:

```json
"PedidosDb": "Server=localhost;Database=PedidosRestaurantes;Trusted_Connection=True;TrustServerCertificate=True;"
```

Si la instancia es SQLEXPRESS, el servidor se escribe `.\\SQLEXPRESS` dentro del JSON.

### 4.3 Mac

1. Instalar Docker Desktop, el SDK de .NET 10, Git y sqlcmd (`brew install sqlcmd`). Para ver la base se puede usar la extensión SQL Server (mssql) de Visual Studio Code.
2. En un Mac con chip Apple, activar en Docker Desktop la opción de usar Rosetta para la emulación x86_64/amd64.
3. Levantar SQL Server. Se debe cambiar la contraseña por una con mayúsculas, minúsculas, números y símbolos:

```bash
docker run --platform linux/amd64 -e ACCEPT_EULA=Y -e 'MSSQL_SA_PASSWORD=<Contraseña>' -p 1433:1433 --name sqlserver -d mcr.microsoft.com/mssql/server:2022-latest
```

4. Clonar el repositorio y, desde su carpeta, ejecutar los scripts en el orden de 4.1:

```bash
sqlcmd -S localhost -U sa -P '<Contraseña>' -C -i Bd/PedidosRest.sql
find 'Queries PA' -name '*.sql' | sort | while read -r f; do sqlcmd -S localhost -U sa -P '<Contraseña>' -C -i "$f"; done
sqlcmd -S localhost -U sa -P '<Contraseña>' -C -i Bd/Datos_Prueba.sql
```

5. En `Api/PedidosRestaurantes.Api` crear `appsettings.Development.json` a partir del ejemplo con:

```json
"PedidosDb": "Server=localhost,1433;Database=PedidosRestaurantes;User Id=sa;Password=<Contraseña>;TrustServerCertificate=True;"
```

En Mac no funciona `Trusted_Connection`, que es solo de Windows.

### 4.4 Correr el API y probar (Windows y Mac)

```bash
cd Api/PedidosRestaurantes.Api
dotnet run --urls http://localhost:5080
```

Abrir http://localhost:5080/swagger y probar los endpoints. El archivo `appsettings.Development.json` no se sube a GitHub.
