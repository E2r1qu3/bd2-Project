/* Pruebas R4 - José. Requiere Bd/PedidosRest.sql, Bd/Datos_Prueba.sql y el archivo del mismo nombre en Queries PA/.
   Ninguna prueba deja datos cambiados. Si ves además el error 3609 en las pruebas de triggers, es normal. */
USE PedidosRestaurantes;
GO

-- Prueba 4: cambiar el estado de un pedido ya entregado -> 55002 y se deshace todo
DECLARE @PedidosAntes INT = (SELECT COUNT(*) FROM ventas.Pedido);
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
        SELECT ClienteId, SedeId, 2, 6, 1000 FROM ventas.Pedido WHERE PedidoId = 2;
        DECLARE @T INT = SCOPE_IDENTITY();
        UPDATE ventas.Pedido SET EstadoId = 3 WHERE PedidoId = @T;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 55002
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH
SELECT @PedidosAntes AS PedidosAntes, (SELECT COUNT(*) FROM ventas.Pedido) AS PedidosDespues;   -- iguales
GO

-- Prueba 5: en un pedido entregado SÍ se pueden cambiar otros campos (se deshace al final)
BEGIN TRANSACTION;
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
    SELECT ClienteId, SedeId, 2, 6, 1000 FROM ventas.Pedido WHERE PedidoId = 2;
    DECLARE @T2 INT = SCOPE_IDENTITY();
    UPDATE ventas.Pedido SET Notas = N'Nota permitida' WHERE PedidoId = @T2;
    SELECT PedidoId, EstadoId, Notas FROM ventas.Pedido WHERE PedidoId = @T2;   -- EstadoId 6, Notas actualizada
ROLLBACK TRANSACTION;
GO
