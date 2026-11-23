# PedidosRestaurantes

Proyecto del curso Bases de Datos II. Base de datos en SQL Server para una plataforma SaaS de pedidos para restaurantes: cualquier restaurante se suscribe, registra sus sedes y su menú, y sus clientes hacen pedidos para comer en el local, retirar o recibir por express.

## Estructura

```
Bd/
  PedidosRest.sql        Crea la base, los 4 esquemas, las tablas, los catálogos, los usuarios y los roles (R1)
  Datos_Prueba.sql       Carga dos restaurantes, sedes, menú, clientes, usuarios y pedidos de ejemplo
Queries PA/
  SP_Grupo1_PlanSuscripcion_Restaurante_Suscripcion.sql
  SP_Grupo2_Sede_Categoria_Producto.sql
  SP_Grupo3_ProductoSede_Cliente_DireccionCliente.sql
  SP_Grupo4_Pedido_EstadoPedido_DetallePedido.sql
  SP_Grupo5_HistorialEstadoPedido_Usuario_Pago_Entrega.sql
  SP_Autenticacion.sql   Registro, login, cambio de contraseña y desbloqueo
```

## Instalación

Requisitos: SQL Server 2019 o superior y un usuario con rol `sysadmin` (por ejemplo `sa`).

Ejecutar los scripts en este orden, cada uno completo:

1. `Bd/PedidosRest.sql`
2. Todos los archivos de `Queries PA/` (el orden entre ellos no importa)
3. `Bd/Datos_Prueba.sql`

`PedidosRest.sql` borra y vuelve a crear la base `PedidosRestaurantes`, así que se puede usar para empezar desde cero.

## Esquemas

| Esquema | Contenido |
|---|---|
| `core` | Planes, restaurantes, suscripciones y sedes |
| `menu` | Categorías, productos y disponibilidad por sede |
| `ventas` | Clientes, direcciones, pedidos, detalle, historial, pagos y entregas |
| `seguridad` | Roles y usuarios de la aplicación |

Cada stored procedure está dentro del esquema de su tabla, por ejemplo `core.sp_ObtenerSedes` o `ventas.sp_InsertarPedido`. El usuario de la API (`login_api_pedidos`) solo tiene permiso de ejecutar stored procedures en esos cuatro esquemas.

## Usuarios de prueba

Los carga `Datos_Prueba.sql`. Todos tienen la contraseña `Prueba123!`.

| Correo | Rol |
|---|---|
| admin@pedidosrestaurantes.cr | AdminPlataforma |
| admin@artesanos.cr | AdminRestaurante (Artesanos) |
| cocina.sanpedro@artesanos.cr | EmpleadoSede (Artesanos San Pedro) |
| maria.rodriguez@correo.cr | Cliente |

Prueba rápida del login:

```sql
EXEC seguridad.sp_Login @Correo = N'admin@artesanos.cr', @Contrasena = N'Prueba123!';
```

## Stored procedures

- **CRUD** de las 16 tablas (Obtener, ObtenerPorId, Insertar, Actualizar, Eliminar).
  - Las tablas con columna `Activo`/`Activa` usan borrado lógico: Eliminar desactiva el registro en vez de borrarlo.
  - El historial de estados es una bitácora: solo se puede consultar e insertar.
  - Insertar devuelve el `Id` creado; Actualizar y Eliminar devuelven `FilasAfectadas`.
- **Autenticación** (`SP_Autenticacion.sql`):
  - `seguridad.sp_RegistrarUsuario`: guarda la contraseña como hash SHA-512 con sal aleatoria.
  - `seguridad.sp_Login`: valida credenciales y bloquea la cuenta después de 5 intentos fallidos.
  - `seguridad.sp_CambiarContrasena` y `seguridad.sp_DesbloquearUsuario`.

### Códigos de error de autenticación

| Código | Mensaje |
|---|---|
| 50001 | El correo ya está registrado. |
| 50002 | La contraseña debe tener al menos 8 caracteres. |
| 50003 | El rol no corresponde con el restaurante, sede o cliente indicado. |
| 50010 | Correo o contraseña incorrectos. |
| 50011 | Cuenta bloqueada por intentos fallidos. |
| 50012 | La contraseña actual no es correcta. |

## API

Proyecto ASP.NET Core en `Api/PedidosRestaurantes.Api`. Se conecta con `login_api_pedidos`, que solo puede ejecutar stored procedures.

1. Copiar `appsettings.Development.example.json` como `appsettings.Development.json` y ajustar la conexión.
2. `cd Api/PedidosRestaurantes.Api` y `dotnet run`.
3. Abrir http://localhost:5080/swagger.

La guía paso a paso está en `Api/GUIA_API.md`.

## Índices y planes de ejecución (R4)

Para evaluar el rendimiento de las consultas se seleccionaron tres consultas SQL y se capturaron sus planes de ejecución antes y después de crear índices no agrupados (NONCLUSTERED INDEX).

### Índices creados

| Índice | Tabla | Columna |
|---|---|---|
| IX_Pago_PedidoId | ventas.Pago | PedidoId |
| IX_HistorialEstadoPedido_PedidoId | ventas.HistorialEstadoPedido | PedidoId |
| IX_Pedido_ClienteId | ventas.Pedido | ClienteId |

Los índices permiten organizar información adicional sobre las columnas utilizadas en las condiciones de búsqueda, facilitando el acceso a los registros.

### Comparación de planes de ejecución

Se analizaron las siguientes consultas:

1. Búsqueda de pagos por pedido.
2. Consulta del historial de estados de un pedido.
3. Búsqueda de pedidos por cliente.

Resultados obtenidos:

| Consulta | Plan antes | Plan después |
|---|---|---|
| Pagos por pedido | Clustered Index Scan | Clustered Index Scan |
| Historial por pedido | Clustered Index Scan | Clustered Index Scan |
| Pedidos por cliente | Clustered Index Scan | Index Scan y Clustered Index Seek |

### Análisis de resultados

En las consultas de pagos e historial, SQL Server mantuvo el uso de Clustered Index Scan. Esto puede deberse a que las tablas contienen pocos registros y el optimizador considera que recorrerlas resulta conveniente.

En la consulta de pedidos por cliente, el nuevo índice IX_Pedido_ClienteId aparece en el plan de ejecución mediante un Index Scan, acompañado de un Clustered Index Seek para recuperar los registros correspondientes.

Los resultados demuestran que la creación de índices puede modificar el plan de ejecución, pero su utilización depende de las características de los datos y de las decisiones del optimizador de SQL Server.

### Archivos de evidencia

- `Queries PA/R4_Consultas.sql`: consultas utilizadas para capturar los planes.
- `Queries PA/R4_Indices.sql`: creación de los índices.
- `R4_Planes_Antes.txt`: planes de ejecución antes de crear los índices.
- `R4_Planes_Despues.txt`: planes de ejecución después de crear los índices.
- `R4_Crear_Indices.txt`: resultado de la ejecución del script de índices.