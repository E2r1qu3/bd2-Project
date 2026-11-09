/* Pruebas R4 - José. Requiere Bd/PedidosRest.sql, Bd/Datos_Prueba.sql y el archivo del mismo nombre en Queries PA/.
   Ninguna prueba deja datos cambiados. Si ves además el error 3609 en las pruebas de triggers, es normal. */
USE PedidosRestaurantes;
GO

-- Prueba 1: modificar el historial -> 55001, el dato no cambia
DECLARE @Id BIGINT = (SELECT MIN(HistorialId) FROM ventas.HistorialEstadoPedido);
DECLARE @ComentarioAntes NVARCHAR(200) = (SELECT Comentario FROM ventas.HistorialEstadoPedido WHERE HistorialId = @Id);
BEGIN TRY
    UPDATE ventas.HistorialEstadoPedido SET Comentario = N'Cambio no permitido' WHERE HistorialId = @Id;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 55001
END CATCH
SELECT @ComentarioAntes AS ComentarioAntes,
       (SELECT Comentario FROM ventas.HistorialEstadoPedido WHERE HistorialId = @Id) AS ComentarioDespues;   -- iguales
GO

-- Prueba 2: borrar del historial -> 55001, el conteo no cambia
DECLARE @Antes INT = (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido);
BEGIN TRY
    DELETE FROM ventas.HistorialEstadoPedido WHERE HistorialId = (SELECT MIN(HistorialId) FROM ventas.HistorialEstadoPedido);
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 55001
END CATCH
SELECT @Antes AS FilasAntes, (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido) AS FilasDespues;   -- iguales
GO

-- Prueba 3: insertar en el historial SÍ está permitido (se deshace al final)
BEGIN TRANSACTION;
    INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
    VALUES (2, 1, NULL, N'Prueba de trigger');
    SELECT COUNT(*) AS LineasHistorialPedido2 FROM ventas.HistorialEstadoPedido WHERE PedidoId = 2;
ROLLBACK TRANSACTION;
GO
