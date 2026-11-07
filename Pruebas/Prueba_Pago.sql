USE PedidosRestaurantes;
GO

/* =========================================================
   R3 - Mila
   Pruebas de ventas.sp_RegistrarPago

   El archivo se puede ejecutar completo las veces que sea:
   al inicio crea un pedido nuevo y pendiente, y todas las
   pruebas trabajan sobre ese pedido. No toca el pedido 2.
   ========================================================= */

-- ---------------------------------------------------------
-- Preparación: crear un pedido pendiente solo para estas pruebas
-- (Carlos, retiro en Heredia: 1 hamburguesa clásica + 1 papas)
-- ---------------------------------------------------------
DROP TABLE IF EXISTS #PedidoPrueba;

CREATE TABLE #PedidoPrueba (
    PedidoId   INT,
    Subtotal   DECIMAL(12,2),
    Impuesto   DECIMAL(12,2),
    CostoEnvio DECIMAL(12,2),
    Total      DECIMAL(12,2)
);

INSERT INTO #PedidoPrueba
EXEC ventas.sp_CrearPedido
    @ClienteId = 2, @SedeId = 2, @ModalidadId = 2,
    @Lineas = N'[{"productoId":1,"cantidad":1},{"productoId":4,"cantidad":1}]';

SELECT 'Pedido de prueba creado' AS Paso, PedidoId, Total FROM #PedidoPrueba;
GO

-- ---------------------------------------------------------
-- Prueba 1: validación. Monto distinto al total del pedido
-- Esperado: error 53003
-- ---------------------------------------------------------
DECLARE @PedidoId INT = (SELECT PedidoId FROM #PedidoPrueba);

BEGIN TRY
    EXEC ventas.sp_RegistrarPago
        @PedidoId = @PedidoId, @MetodoPagoId = 2, @Monto = 1.00, @UsuarioId = 3;
END TRY
BEGIN CATCH
    SELECT 'Prueba 1: monto incorrecto' AS Prueba, ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH
GO

-- ---------------------------------------------------------
-- Prueba 2: validación. Pedido que no existe
-- Esperado: error 53001
-- ---------------------------------------------------------
BEGIN TRY
    EXEC ventas.sp_RegistrarPago
        @PedidoId = 999999, @MetodoPagoId = 2, @Monto = 1000, @UsuarioId = 3;
END TRY
BEGIN CATCH
    SELECT 'Prueba 2: pedido inexistente' AS Prueba, ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH
GO

-- ---------------------------------------------------------
-- Prueba 3: ROLLBACK
-- El SP inserta el pago y cambia el pedido a Confirmado, pero al
-- escribir el historial con @UsuarioId = 999 (no existe) choca con
-- la llave foránea FK_Historial_Usuario. La transacción debe
-- deshacer el pago y el cambio de estado.
-- Esperado: ROLLBACK OK
-- ---------------------------------------------------------
DECLARE @PedidoId INT = (SELECT PedidoId FROM #PedidoPrueba);
DECLARE @Total DECIMAL(12,2) = (SELECT Total FROM #PedidoPrueba);

DECLARE @PagosAntes  INT     = (SELECT COUNT(*) FROM ventas.Pago WHERE PedidoId = @PedidoId);
DECLARE @EstadoAntes TINYINT = (SELECT EstadoId FROM ventas.Pedido WHERE PedidoId = @PedidoId);

BEGIN TRY
    EXEC ventas.sp_RegistrarPago
        @PedidoId = @PedidoId, @MetodoPagoId = 2, @Monto = @Total,
        @ReferenciaExterna = 'SINPE-ROLLBACK', @UsuarioId = 999;
END TRY
BEGIN CATCH
    PRINT 'Error capturado: ' + ERROR_MESSAGE();
END CATCH

DECLARE @PagosDespues  INT     = (SELECT COUNT(*) FROM ventas.Pago WHERE PedidoId = @PedidoId);
DECLARE @EstadoDespues TINYINT = (SELECT EstadoId FROM ventas.Pedido WHERE PedidoId = @PedidoId);

SELECT 'Prueba 3: rollback' AS Prueba,
       @PagosAntes  AS PagosAntes,  @PagosDespues  AS PagosDespues,
       @EstadoAntes AS EstadoAntes, @EstadoDespues AS EstadoDespues,
       CASE WHEN @PagosAntes = @PagosDespues AND @EstadoAntes = @EstadoDespues
            THEN 'ROLLBACK OK' ELSE 'FALLÓ' END AS Resultado;
GO

-- ---------------------------------------------------------
-- Prueba 4: pago correcto con SINPE por el total exacto
-- Esperado: devuelve el PagoId y el pedido pasa a Confirmado (2)
-- ---------------------------------------------------------
DECLARE @PedidoId INT = (SELECT PedidoId FROM #PedidoPrueba);
DECLARE @Total DECIMAL(12,2) = (SELECT Total FROM #PedidoPrueba);

EXEC ventas.sp_RegistrarPago
    @PedidoId = @PedidoId, @MetodoPagoId = 2, @Monto = @Total,
    @ReferenciaExterna = 'SINPE-PRUEBA-OK', @UsuarioId = 3;

SELECT 'Prueba 4: pago correcto' AS Prueba,
       p.PedidoId, e.Nombre AS Estado, pg.Monto, pg.Estado AS EstadoPago
FROM ventas.Pedido p
JOIN ventas.EstadoPedido e ON e.EstadoId = p.EstadoId
JOIN ventas.Pago pg        ON pg.PedidoId = p.PedidoId
WHERE p.PedidoId = @PedidoId;
GO

-- ---------------------------------------------------------
-- Prueba 5: validación. Pagar otra vez el mismo pedido
-- Esperado: error 53004
-- ---------------------------------------------------------
DECLARE @PedidoId INT = (SELECT PedidoId FROM #PedidoPrueba);
DECLARE @Total DECIMAL(12,2) = (SELECT Total FROM #PedidoPrueba);

BEGIN TRY
    EXEC ventas.sp_RegistrarPago
        @PedidoId = @PedidoId, @MetodoPagoId = 2, @Monto = @Total, @UsuarioId = 3;
END TRY
BEGIN CATCH
    SELECT 'Prueba 5: pago duplicado' AS Prueba, ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
END CATCH
GO

DROP TABLE IF EXISTS #PedidoPrueba;
GO
