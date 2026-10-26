USE PedidosRestaurantes;
GO

/* =========================================================
   Pruebas de ventas.sp_CrearPedido
   ========================================================= */

-- Prueba 1: pedido correcto (para retiro en Heredia, con precio de sede)
EXEC ventas.sp_CrearPedido
    @ClienteId = 2, @SedeId = 2, @ModalidadId = 2,
    @Lineas = N'[{"productoId":2,"cantidad":1},{"productoId":6,"cantidad":2}]';
-- Esperado: Subtotal 10400 (BBQ a 6800 en Heredia + 2 limonadas), envío 0
GO

-- Prueba 2: validación. Express en Heredia, que no ofrece express
BEGIN TRY
    EXEC ventas.sp_CrearPedido
        @ClienteId = 1, @SedeId = 2, @ModalidadId = 3, @DireccionId = 1,
        @Lineas = N'[{"productoId":1,"cantidad":1}]';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;   -- Esperado: 51005
END CATCH
GO

-- Prueba 3: ROLLBACK. Una línea con cantidad 0 falla al insertar el detalle,
-- DESPUÉS de que el pedido ya se insertó. La transacción debe deshacer todo.
DECLARE @PedidosAntes INT  = (SELECT COUNT(*) FROM ventas.Pedido);
DECLARE @DetalleAntes INT  = (SELECT COUNT(*) FROM ventas.DetallePedido);
DECLARE @HistAntes    INT  = (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido);

BEGIN TRY
    EXEC ventas.sp_CrearPedido
        @ClienteId = 1, @SedeId = 1, @ModalidadId = 2,
        @Lineas = N'[{"productoId":1,"cantidad":1},{"productoId":4,"cantidad":0}]';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

SELECT
    @PedidosAntes AS PedidosAntes, (SELECT COUNT(*) FROM ventas.Pedido) AS PedidosDespues,
    @DetalleAntes AS DetalleAntes, (SELECT COUNT(*) FROM ventas.DetallePedido) AS DetalleDespues,
    @HistAntes    AS HistAntes,    (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido) AS HistDespues,
    CASE WHEN @PedidosAntes = (SELECT COUNT(*) FROM ventas.Pedido)
         THEN 'ROLLBACK OK' ELSE 'FALLÓ' END AS Resultado;
GO
/* =========================================================
   Pruebas de core.sp_RegistrarRestaurante
   ========================================================= */

-- Prueba 4: registro correcto
EXEC core.sp_RegistrarRestaurante
    @Nombre = N'Pizzería Don Luigi', @CedulaJuridica = '3-101-555555',
    @Correo = N'contacto@donluigi.cr', @Telefono = '2222-3333',
    @PlanId = 1,
    @CorreoAdmin = N'admin@donluigi.cr', @ContrasenaAdmin = N'Luigi2026!';
-- Esperado: devuelve RestauranteId y UsuarioId nuevos
GO

-- Prueba 5: validación. Plan que no existe
BEGIN TRY
    EXEC core.sp_RegistrarRestaurante
        @Nombre = N'Restaurante X', @CedulaJuridica = '3-101-999999',
        @Correo = N'x@x.cr', @PlanId = 99,
        @CorreoAdmin = N'admin@x.cr', @ContrasenaAdmin = N'Clave1234!';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;   -- Esperado: 51012
END CATCH
GO

-- Prueba 6: ROLLBACK. El correo del admin ya existe (admin@artesanos.cr).
-- El restaurante y la suscripción se insertan, pero sp_RegistrarUsuario falla
-- con 50001 y la transacción tiene que deshacer todo.
DECLARE @RestAntes INT = (SELECT COUNT(*) FROM core.Restaurante);
DECLARE @SuscAntes INT = (SELECT COUNT(*) FROM core.Suscripcion);

BEGIN TRY
    EXEC core.sp_RegistrarRestaurante
        @Nombre = N'Sushi Kento', @CedulaJuridica = '3-101-777777',
        @Correo = N'hola@kento.cr', @PlanId = 2,
        @CorreoAdmin = N'admin@artesanos.cr', @ContrasenaAdmin = N'Kento2026!';
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

SELECT
    @RestAntes AS RestaurantesAntes, (SELECT COUNT(*) FROM core.Restaurante) AS RestaurantesDespues,
    @SuscAntes AS SuscripcionesAntes, (SELECT COUNT(*) FROM core.Suscripcion) AS SuscripcionesDespues,
    CASE WHEN @RestAntes = (SELECT COUNT(*) FROM core.Restaurante)
          AND @SuscAntes = (SELECT COUNT(*) FROM core.Suscripcion)
         THEN 'ROLLBACK OK' ELSE 'FALLÓ' END AS Resultado;
GO