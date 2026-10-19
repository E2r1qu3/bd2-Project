/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Datos de prueba
   Requiere (en este orden):
     1. Bd/PedidosRest.sql
     2. Todos los archivos de "Queries PA" (usa seguridad.sp_RegistrarUsuario)

   Carga dos restaurantes para mostrar que la plataforma es multi-restaurante:
     - Artesanos (plan Crecimiento, 2 sedes)
     - Soda La Esquina (plan Básico, 1 sede)

   Usuarios de prueba (todos con la contraseña  Prueba123! ):
     admin@pedidosrestaurantes.cr   AdminPlataforma
     admin@artesanos.cr             AdminRestaurante (Artesanos)
     cocina.sanpedro@artesanos.cr   EmpleadoSede (Artesanos San Pedro)
     maria.rodriguez@correo.cr      Cliente
   ========================================================================== */
USE PedidosRestaurantes;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM core.Restaurante)
BEGIN
    RAISERROR(N'La base ya tiene datos. Ejecute de nuevo Bd/PedidosRest.sql para empezar desde cero.', 16, 1);
    SET NOEXEC ON;
END
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @PlanBasico INT      = (SELECT PlanId FROM core.PlanSuscripcion WHERE Nombre = N'Básico');
    DECLARE @PlanCrecimiento INT = (SELECT PlanId FROM core.PlanSuscripcion WHERE Nombre = N'Crecimiento');

    /* ---------------- Restaurantes y suscripciones ---------------- */
    DECLARE @Artesanos INT, @Soda INT;

    INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Telefono)
    VALUES (N'Artesanos', '3-101-456789', N'contacto@artesanos.cr', '2222-1000');
    SET @Artesanos = SCOPE_IDENTITY();

    INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Telefono)
    VALUES (N'Soda La Esquina', '3-102-112233', N'sodalaesquina@correo.cr', '2551-2020');
    SET @Soda = SCOPE_IDENTITY();

    INSERT INTO core.Suscripcion (RestauranteId, PlanId, FechaInicio, Estado) VALUES
        (@Artesanos, @PlanCrecimiento, '2026-08-01', 'Activa'),
        (@Soda,      @PlanBasico,      '2026-09-15', 'Activa');

    /* ---------------- Sedes ---------------- */
    DECLARE @SedeSanPedro INT, @SedeHeredia INT, @SedeCartago INT;

    INSERT INTO core.Sede (RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress)
    VALUES (@Artesanos, N'San Pedro', N'San José', N'Montes de Oca', N'100 m este del Mall San Pedro', '2222-1001', '11:00', '22:00', 1);
    SET @SedeSanPedro = SCOPE_IDENTITY();

    INSERT INTO core.Sede (RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress)
    VALUES (@Artesanos, N'Heredia Centro', N'Heredia', N'Heredia', N'Costado norte del Parque Central', '2222-1002', '11:00', '21:00', 0);
    SET @SedeHeredia = SCOPE_IDENTITY();

    INSERT INTO core.Sede (RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress)
    VALUES (@Soda, N'Cartago Centro', N'Cartago', N'Cartago', N'50 m sur de la Basílica de los Ángeles', '2551-2021', '06:30', '16:00', 1);
    SET @SedeCartago = SCOPE_IDENTITY();

    /* ---------------- Categorías ---------------- */
    INSERT INTO menu.Categoria (RestauranteId, Nombre, Orden) VALUES
        (@Artesanos, N'Hamburguesas',     1),
        (@Artesanos, N'Acompañamientos',  2),
        (@Artesanos, N'Bebidas',          3),
        (@Soda,      N'Casados',          1),
        (@Soda,      N'Bebidas',          2);

    DECLARE @CatHamb INT  = (SELECT CategoriaId FROM menu.Categoria WHERE RestauranteId = @Artesanos AND Nombre = N'Hamburguesas');
    DECLARE @CatAcomp INT = (SELECT CategoriaId FROM menu.Categoria WHERE RestauranteId = @Artesanos AND Nombre = N'Acompañamientos');
    DECLARE @CatBebA INT  = (SELECT CategoriaId FROM menu.Categoria WHERE RestauranteId = @Artesanos AND Nombre = N'Bebidas');
    DECLARE @CatCas INT   = (SELECT CategoriaId FROM menu.Categoria WHERE RestauranteId = @Soda AND Nombre = N'Casados');
    DECLARE @CatBebS INT  = (SELECT CategoriaId FROM menu.Categoria WHERE RestauranteId = @Soda AND Nombre = N'Bebidas');

    /* ---------------- Productos ---------------- */
    INSERT INTO menu.Producto (RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase) VALUES
        (@Artesanos, @CatHamb,  N'Hamburguesa Clásica',     N'Carne de res, queso cheddar, lechuga y tomate', 5500),
        (@Artesanos, @CatHamb,  N'Hamburguesa BBQ',         N'Carne de res, tocineta, cebolla caramelizada y salsa BBQ', 6500),
        (@Artesanos, @CatHamb,  N'Hamburguesa Vegetariana', N'Torta de garbanzo, aguacate y vegetales', 6000),
        (@Artesanos, @CatAcomp, N'Papas fritas',            N'Porción mediana', 2000),
        (@Artesanos, @CatAcomp, N'Aros de cebolla',         N'Porción mediana', 2500),
        (@Artesanos, @CatBebA,  N'Limonada natural',        N'500 ml', 1800),
        (@Artesanos, @CatBebA,  N'Refresco en lata',        N'355 ml', 1200),
        (@Soda,      @CatCas,   N'Casado con pollo',        N'Arroz, frijoles, ensalada, plátano y pollo en salsa', 3800),
        (@Soda,      @CatCas,   N'Casado con bistec',       N'Arroz, frijoles, ensalada, plátano y bistec encebollado', 4200),
        (@Soda,      @CatBebS,  N'Fresco de cas',           N'Vaso de 400 ml', 1000);

    DECLARE @PClasica INT = (SELECT ProductoId FROM menu.Producto WHERE RestauranteId = @Artesanos AND Nombre = N'Hamburguesa Clásica');
    DECLARE @PBBQ INT     = (SELECT ProductoId FROM menu.Producto WHERE RestauranteId = @Artesanos AND Nombre = N'Hamburguesa BBQ');
    DECLARE @PVeg INT     = (SELECT ProductoId FROM menu.Producto WHERE RestauranteId = @Artesanos AND Nombre = N'Hamburguesa Vegetariana');
    DECLARE @PPapas INT   = (SELECT ProductoId FROM menu.Producto WHERE RestauranteId = @Artesanos AND Nombre = N'Papas fritas');
    DECLARE @PLimonada INT= (SELECT ProductoId FROM menu.Producto WHERE RestauranteId = @Artesanos AND Nombre = N'Limonada natural');

    /* ---------------- Productos por sede ----------------
       - San Pedro vende todo el menú de Artesanos a precio base.
       - Heredia no tiene la vegetariana y vende la BBQ más cara.
       - Cartago vende todo el menú de la Soda.                       */
    INSERT INTO menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede)
    SELECT @SedeSanPedro, ProductoId, 1, NULL FROM menu.Producto WHERE RestauranteId = @Artesanos;

    INSERT INTO menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede)
    SELECT @SedeHeredia, ProductoId,
           CASE WHEN ProductoId = @PVeg THEN 0 ELSE 1 END,
           CASE WHEN ProductoId = @PBBQ THEN 6800 ELSE NULL END
    FROM menu.Producto WHERE RestauranteId = @Artesanos;

    INSERT INTO menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede)
    SELECT @SedeCartago, ProductoId, 1, NULL FROM menu.Producto WHERE RestauranteId = @Soda;

    /* ---------------- Clientes y direcciones ---------------- */
    DECLARE @Maria INT, @Carlos INT, @Ana INT;

    INSERT INTO ventas.Cliente (Nombre, Apellidos, Correo, Telefono) VALUES (N'María', N'Rodríguez Mora', N'maria.rodriguez@correo.cr', '8888-1111');
    SET @Maria = SCOPE_IDENTITY();
    INSERT INTO ventas.Cliente (Nombre, Apellidos, Correo, Telefono) VALUES (N'Carlos', N'Jiménez Solís', N'carlos.jimenez@correo.cr', '8888-2222');
    SET @Carlos = SCOPE_IDENTITY();
    INSERT INTO ventas.Cliente (Nombre, Apellidos, Correo, Telefono) VALUES (N'Ana', N'Vargas Quesada', N'ana.vargas@correo.cr', '8888-3333');
    SET @Ana = SCOPE_IDENTITY();

    DECLARE @DirMariaCasa INT;
    INSERT INTO ventas.DireccionCliente (ClienteId, Alias, Provincia, Canton, Distrito, Detalle)
    VALUES (@Maria, N'Casa', N'San José', N'Montes de Oca', N'San Pedro', N'Barrio Dent, casa 24, portón negro');
    SET @DirMariaCasa = SCOPE_IDENTITY();

    INSERT INTO ventas.DireccionCliente (ClienteId, Alias, Provincia, Canton, Distrito, Detalle) VALUES
        (@Maria,  N'Trabajo', N'San José', N'San José',  N'Carmen',  N'Edificio Torre Central, piso 5'),
        (@Carlos, N'Casa',    N'Heredia',  N'Heredia',   N'Mercedes', N'Residencial Los Arcos, casa 8'),
        (@Ana,    N'Casa',    N'Cartago',  N'Cartago',   N'Oriental', N'200 m norte del Colegio San Luis Gonzaga');

    /* ---------------- Usuarios (contraseña: Prueba123!) ---------------- */
    EXEC seguridad.sp_RegistrarUsuario @Correo = N'admin@pedidosrestaurantes.cr', @Contrasena = N'Prueba123!', @RolId = 1;
    EXEC seguridad.sp_RegistrarUsuario @Correo = N'admin@artesanos.cr',           @Contrasena = N'Prueba123!', @RolId = 2, @RestauranteId = @Artesanos;
    EXEC seguridad.sp_RegistrarUsuario @Correo = N'cocina.sanpedro@artesanos.cr', @Contrasena = N'Prueba123!', @RolId = 3, @RestauranteId = @Artesanos, @SedeId = @SedeSanPedro;
    EXEC seguridad.sp_RegistrarUsuario @Correo = N'maria.rodriguez@correo.cr',    @Contrasena = N'Prueba123!', @RolId = 4, @ClienteId = @Maria;

    DECLARE @Empleado INT = (SELECT UsuarioId FROM seguridad.Usuario WHERE Correo = N'cocina.sanpedro@artesanos.cr');

    /* ---------------- Pedido 1: María, express desde San Pedro, ya entregado ----------------
       2 x Hamburguesa Clásica (5 500) + 1 x Papas fritas (2 000) = 13 000
       IVA 13 % = 1 690, envío 1 500, total 16 190                                              */
    DECLARE @Pedido1 INT;
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, Subtotal, Impuesto, CostoEnvio, Notas)
    VALUES (@Maria, @SedeSanPedro, 3, 6, @DirMariaCasa, 13000, 1690, 1500, N'Tocar el timbre dos veces');
    SET @Pedido1 = SCOPE_IDENTITY();

    INSERT INTO ventas.DetallePedido (PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Nota) VALUES
        (@Pedido1, 1, @PClasica, 2, 5500, N'Una sin cebolla'),
        (@Pedido1, 2, @PPapas,   1, 2000, NULL);

    INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario) VALUES
        (@Pedido1, 1, NULL,      DATEADD(MINUTE, -60, SYSDATETIME()), N'Pedido creado por el cliente'),
        (@Pedido1, 2, @Empleado, DATEADD(MINUTE, -58, SYSDATETIME()), NULL),
        (@Pedido1, 3, @Empleado, DATEADD(MINUTE, -55, SYSDATETIME()), NULL),
        (@Pedido1, 4, @Empleado, DATEADD(MINUTE, -40, SYSDATETIME()), NULL),
        (@Pedido1, 5, @Empleado, DATEADD(MINUTE, -35, SYSDATETIME()), NULL),
        (@Pedido1, 6, @Empleado, DATEADD(MINUTE, -15, SYSDATETIME()), N'Entregado al cliente');

    INSERT INTO ventas.Pago (PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna)
    VALUES (@Pedido1, 2, 16190, 'Aprobado', 'SINPE-20261017-0001');

    INSERT INTO ventas.Entrega (PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega)
    VALUES (@Pedido1, N'Repartidor propio', 'ART-SP-0001', 'Entregada',
            DATEADD(MINUTE, -35, SYSDATETIME()), DATEADD(MINUTE, -15, SYSDATETIME()));

    /* ---------------- Pedido 2: Carlos, retiro en Heredia, pendiente ----------------
       1 x Hamburguesa BBQ (precio Heredia 6 800) + 1 x Limonada (1 800) = 8 600
       IVA 13 % = 1 118, sin envío, total 9 718                                         */
    DECLARE @Pedido2 INT;
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal, Impuesto, CostoEnvio)
    VALUES (@Carlos, @SedeHeredia, 2, 1, 8600, 1118, 0);
    SET @Pedido2 = SCOPE_IDENTITY();

    INSERT INTO ventas.DetallePedido (PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario) VALUES
        (@Pedido2, 1, @PBBQ,      1, 6800),
        (@Pedido2, 2, @PLimonada, 1, 1800);

    INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, Comentario)
    VALUES (@Pedido2, 1, N'Pedido creado por el cliente');

    COMMIT TRANSACTION;
    PRINT N'Datos de prueba cargados correctamente.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

SET NOEXEC OFF;
GO

/* Resumen de lo cargado */
SELECT 'Restaurantes' AS Tabla, COUNT(*) AS Filas FROM core.Restaurante
UNION ALL SELECT 'Sedes',          COUNT(*) FROM core.Sede
UNION ALL SELECT 'Productos',      COUNT(*) FROM menu.Producto
UNION ALL SELECT 'ProductoSede',   COUNT(*) FROM menu.ProductoSede
UNION ALL SELECT 'Clientes',       COUNT(*) FROM ventas.Cliente
UNION ALL SELECT 'Usuarios',       COUNT(*) FROM seguridad.Usuario
UNION ALL SELECT 'Pedidos',        COUNT(*) FROM ventas.Pedido
UNION ALL SELECT 'DetallePedido',  COUNT(*) FROM ventas.DetallePedido;
GO
