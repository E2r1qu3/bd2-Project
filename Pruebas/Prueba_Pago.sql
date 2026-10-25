
USE PedidosRestaurantes;
GO

/*
R3 - MILA
Procedimiento: ventas.sp_RegistrarPago

IMPORTANTE:
Las pruebas se ejecutan por separado.
El pedido 2 ya tiene un pago aprobado en la BD actual.
No ejecutar las pruebas de nuevo sobre ese pedido sin
preparar previamente datos de prueba independientes.
*/

-- =============================================
-- PRUEBA 1: ROLLBACK
-- Ejecutar solo con un pedido pendiente y sin pago
-- aprobado. UsuarioId 999 debe provocar un error
-- de FK al insertar el historial.
-- =============================================

/*
DECLARE @PagosAntes INT;
DECLARE @PagosDespues INT;

SELECT @PagosAntes = COUNT(*)
FROM ventas.Pago
WHERE PedidoId = 2;

BEGIN TRY
    EXEC ventas.sp_RegistrarPago
        @PedidoId = 2,
        @MetodoPagoId = 2,
        @Monto = 9718.00,
        @ReferenciaExterna = 'PRUEBA-ROLLBACK',
        @UsuarioId = 999;

    PRINT N'ERROR: se esperaba un fallo de clave foránea.';
END TRY
BEGIN CATCH
    PRINT N'Error esperado: ' + ERROR_MESSAGE();
END CATCH;

SELECT @PagosDespues = COUNT(*)
FROM ventas.Pago
WHERE PedidoId = 2;

SELECT
    @PagosAntes AS PagosAntes,
    @PagosDespues AS PagosDespues;

SELECT PedidoId, EstadoId
FROM ventas.Pedido
WHERE PedidoId = 2;
GO
*/

-- =============================================
-- PRUEBA 2: PAGO EXITOSO
-- Ya se ejecutó correctamente:
-- PagoId 4, pedido 2, monto 9718.00.
-- Se deja documentada para no duplicar el pago.
-- =============================================

SELECT
    p.PedidoId,
    p.EstadoId,
    p.Total,
    pg.PagoId,
    pg.Monto,
    pg.Estado,
    pg.ReferenciaExterna
FROM ventas.Pedido AS p
INNER JOIN ventas.Pago AS pg
    ON pg.PedidoId = p.PedidoId
WHERE p.PedidoId = 2;
GO
