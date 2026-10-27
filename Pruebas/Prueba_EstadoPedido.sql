/* ==========================================================================
   Pruebas R3 - José
   Requiere: Bd/PedidosRest.sql, Queries PA/SP_R3_EstadoPedido_Menu.sql y
             Bd/Datos_Prueba.sql (pedido 2 pendiente, usuario 3).
   Orden: primero las de rollback, luego validaciones y al final las exitosas.
   Las pruebas con "pedido temporal" no dejan datos: todo se deshace al final.
   La prueba 8 SÍ cambia el pedido 2; para repetir, reinstalar desde el paso 1.
   ========================================================================== */
USE PedidosRestaurantes;
GO

/* ---------- ROLLBACK ---------- */

-- Prueba 1 (rollback): cambiar estado con un usuario que no existe.
-- El UPDATE del pedido se hace, el historial falla por la FK y todo se deshace.
DECLARE @EstadoAntes TINYINT = (SELECT EstadoId FROM ventas.Pedido WHERE PedidoId = 2);
DECLARE @HistAntes   INT     = (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido WHERE PedidoId = 2);
BEGIN TRY
    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = 2, @NuevoEstadoId = 2, @UsuarioId = 999;
END TRY
BEGIN CATCH
    PRINT N'Error esperado: ' + ERROR_MESSAGE();
END CATCH
SELECT @EstadoAntes AS EstadoAntes,
       (SELECT EstadoId FROM ventas.Pedido WHERE PedidoId = 2) AS EstadoDespues,
       @HistAntes AS HistorialAntes,
       (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido WHERE PedidoId = 2) AS HistorialDespues;  -- deben ser iguales
GO

-- Prueba 2 (rollback): cancelar con un usuario que no existe.
DECLARE @EstadoAntes TINYINT = (SELECT EstadoId FROM ventas.Pedido WHERE PedidoId = 2);
DECLARE @HistAntes   INT     = (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido WHERE PedidoId = 2);
DECLARE @PagosAntes  INT     = (SELECT COUNT(*) FROM ventas.Pago WHERE PedidoId = 2 AND Estado = 'Reembolsado');
BEGIN TRY
    EXEC ventas.sp_CancelarPedido @PedidoId = 2, @Motivo = N'Prueba de rollback', @UsuarioId = 999;
END TRY
BEGIN CATCH
    PRINT N'Error esperado: ' + ERROR_MESSAGE();
END CATCH
SELECT @EstadoAntes AS EstadoAntes,
       (SELECT EstadoId FROM ventas.Pedido WHERE PedidoId = 2) AS EstadoDespues,
       @HistAntes AS HistorialAntes,
       (SELECT COUNT(*) FROM ventas.HistorialEstadoPedido WHERE PedidoId = 2) AS HistorialDespues,
       @PagosAntes AS ReembolsadosAntes,
       (SELECT COUNT(*) FROM ventas.Pago WHERE PedidoId = 2 AND Estado = 'Reembolsado') AS ReembolsadosDespues;  -- deben ser iguales
GO

/* ---------- VALIDACIONES ---------- */

-- Prueba 3: pedido que no existe -> 52001
BEGIN TRY
    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = 99999, @NuevoEstadoId = 2;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52001
END CATCH
GO

-- Prueba 4: estado que no existe -> 52002
BEGIN TRY
    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = 2, @NuevoEstadoId = 99;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52002
END CATCH
GO

-- Prueba 5: pasar a Cancelado por esta vía -> 52004
BEGIN TRY
    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = 2, @NuevoEstadoId = 7;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52004
END CATCH
GO

-- Prueba 6: pedido temporal ya entregado -> 52003; no express a "En camino" -> 52005.
-- El SP deshace la transacción completa, incluido el pedido temporal.
BEGIN TRY
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
    SELECT ClienteId, SedeId, 2, 6, 1000 FROM ventas.Pedido WHERE PedidoId = 2;
    DECLARE @T1 INT = SCOPE_IDENTITY();
    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = @T1, @NuevoEstadoId = 3;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52003
END CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

BEGIN TRY
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
    SELECT ClienteId, SedeId, 2, 2, 1000 FROM ventas.Pedido WHERE PedidoId = 2;
    DECLARE @T2 INT = SCOPE_IDENTITY();
    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = @T2, @NuevoEstadoId = 5;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52005
END CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

-- Prueba 7: cancelar pedido que no existe -> 52011
BEGIN TRY
    EXEC ventas.sp_CancelarPedido @PedidoId = 99999, @Motivo = N'Prueba';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52011
END CATCH
GO

-- Prueba 7b: cancelar un pedido ya cancelado -> 52012
BEGIN TRY
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
    SELECT ClienteId, SedeId, 2, 7, 1000 FROM ventas.Pedido WHERE PedidoId = 2;
    DECLARE @T3 INT = SCOPE_IDENTITY();
    EXEC ventas.sp_CancelarPedido @PedidoId = @T3, @Motivo = N'Prueba';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Numero, ERROR_MESSAGE() AS Mensaje;   -- 52012
END CATCH
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
GO

/* ---------- EXITOSAS SIN DEJAR DATOS (pedidos temporales) ---------- */

-- Prueba 9: pedido express temporal: Confirmado -> En camino -> Entregado, con su entrega.
BEGIN TRANSACTION;
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
    SELECT ClienteId, SedeId, 3, 4, 5000 FROM ventas.Pedido WHERE PedidoId = 2;
    DECLARE @E INT = SCOPE_IDENTITY();
    INSERT INTO ventas.Entrega (PedidoId, ProveedorEntrega) VALUES (@E, N'Prueba');

    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = @E, @NuevoEstadoId = 5, @UsuarioId = 3, @Comentario = N'Sale a entregar';
    SELECT Estado AS EntregaEnCamino, FechaSalida FROM ventas.Entrega WHERE PedidoId = @E;

    EXEC ventas.sp_CambiarEstadoPedido @PedidoId = @E, @NuevoEstadoId = 6, @UsuarioId = 3;
    SELECT Estado AS EntregaEntregada, FechaEntrega FROM ventas.Entrega WHERE PedidoId = @E;
    SELECT COUNT(*) AS LineasHistorial FROM ventas.HistorialEstadoPedido WHERE PedidoId = @E;   -- 2
ROLLBACK TRANSACTION;
GO

-- Prueba 10: cancelar un pedido temporal con pago aprobado -> el pago queda Reembolsado.
BEGIN TRANSACTION;
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, Subtotal)
    SELECT ClienteId, SedeId, 2, 2, 1000 FROM ventas.Pedido WHERE PedidoId = 2;
    DECLARE @C INT = SCOPE_IDENTITY();
    INSERT INTO ventas.Pago (PedidoId, MetodoPagoId, Monto, Estado) VALUES (@C, 2, 1000, 'Aprobado');

    EXEC ventas.sp_CancelarPedido @PedidoId = @C, @Motivo = N'El cliente cambió de opinión', @UsuarioId = 2;
    SELECT EstadoId AS EstadoPedido FROM ventas.Pedido WHERE PedidoId = @C;                  -- 7
    SELECT Estado AS EstadoPago FROM ventas.Pago WHERE PedidoId = @C;                        -- Reembolsado
ROLLBACK TRANSACTION;
GO

/* ---------- MENÚ ---------- */

-- Prueba 11: menú de la sede de Heredia: sin hamburguesa vegetariana y BBQ a 6 800.
DECLARE @Heredia INT = (SELECT TOP 1 SedeId FROM core.Sede WHERE Provincia = N'Heredia' OR Nombre LIKE N'%Heredia%');
EXEC menu.sp_ObtenerMenuPorSede @SedeId = @Heredia;
GO

/* ---------- EXITOSA QUE CAMBIA DATOS ---------- */

-- Prueba 8: pedido 2 de Pendiente a En preparación, con el usuario 3.
EXEC ventas.sp_CambiarEstadoPedido @PedidoId = 2, @NuevoEstadoId = 3, @UsuarioId = 3, @Comentario = N'En cocina';
SELECT * FROM ventas.HistorialEstadoPedido WHERE PedidoId = 2 ORDER BY FechaCambio;
GO
