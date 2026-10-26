```sql
USE PedidosRestaurantes;
GO

/*
=====================================================
R3 - MILA
Pruebas de ventas.sp_RegistrarPago
=====================================================

IMPORTANTE:
- El pedido 2 ya tiene un pago aprobado.
- No repetir la prueba exitosa sobre ese pedido.
- Las pruebas de rollback y de pago exitoso se ejecutan
  primero sobre datos independientes y preparados para
  pruebas.
- Este archivo no debe ejecutarse completo en la BD
  actual porque algunas pruebas modifican información.
*/

-- ===================================================
-- PRUEBA 1: VALIDACIÓN DE MONTO INCORRECTO
-- Resultado esperado: error 53003.
-- No debe insertarse un pago.
-- ===================================================

/*
Ejecutar solo si el pedido indicado existe y su total
es distinto de 1.00. El pedido 2 cumple esta condición
en la base de datos utilizada durante las pruebas.
*/

BEGIN TRY
    EXEC ventas.sp_RegistrarPago
        @PedidoId = 2,
        @MetodoPagoId = 2,
        @Monto = 1.00,
        @ReferenciaExterna = 'PRUEBA-MONTO-INVALIDO',
        @UsuarioId = 3;

    PRINT N'ERROR: se esperaba el error 53003.';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 53003
        PRINT N'PRUEBA CORRECTA: monto incorrecto rechazado.';
    ELSE
        PRINT N'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO

-- ===================================================
-- PRUEBA 2: ROLLBACK POR ERROR EN EL HISTORIAL
-- Ejecutar únicamente con un pedido pendiente,
-- sin pago aprobado, y datos de prueba independientes.
-- Resultado esperado: la transacción se revierte y
-- los conteos antes y después permanecen iguales.
-- ===================================================

/*
Antes de ejecutar:
1. Sustituir @PedidoPrueba por un pedido de prueba
   pendiente, sin pagos aprobados.
2. Confirmar que el usuario 999 no existe.
3. Ajustar el monto al total real del pedido de prueba.
4. Ejecutar esta prueba antes de la prueba exitosa.

DECLARE @PedidoPrueba INT = NULL;
DECLARE @MontoPrueba DECIMAL(12,2) = NULL;
DECLARE @PagosAntes INT;
DECLARE @PagosDespues INT;

IF @PedidoPrueba IS NULL OR @MontoPrueba IS NULL
BEGIN
    PRINT N'Configurar un pedido de prueba independiente antes de ejecutar.';
    RETURN;
END;

SELECT