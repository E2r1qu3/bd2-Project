/* ==========================================================================
   R3 - José: estado de pedidos y menú
     - ventas.sp_CambiarEstadoPedido  (transacción)
     - ventas.sp_CancelarPedido       (transacción)
     - menu.sp_ObtenerMenuPorSede     (solo lectura)

   Errores (rango 52000-52099):
     52001  El pedido no existe.
     52002  El estado nuevo no existe.
     52003  El pedido ya está en un estado final.
     52004  Para cancelar se debe usar sp_CancelarPedido.
     52005  Solo los pedidos express pueden pasar a En camino.
     52011  El pedido no existe (cancelar).
     52012  El pedido ya está entregado o cancelado.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- --------------------------------------------------------------------------
-- Cambia el estado de un pedido, lo registra en el historial y, si es
-- express, actualiza la entrega. Todo en una sola transacción.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.sp_CambiarEstadoPedido
    @PedidoId      INT,
    @NuevoEstadoId TINYINT,
    @UsuarioId     INT = NULL,
    @Comentario    NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @EstadoActual TINYINT, @ModalidadId TINYINT;

            -- Se lee con UPDLOCK: si dos personas cambian el mismo pedido, la segunda espera.
            SELECT @EstadoActual = p.EstadoId,
                   @ModalidadId  = p.ModalidadId
            FROM ventas.Pedido AS p WITH (UPDLOCK)
            WHERE p.PedidoId = @PedidoId;

            IF @EstadoActual IS NULL
                THROW 52001, N'El pedido no existe.', 1;

            IF NOT EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @NuevoEstadoId)
                THROW 52002, N'El estado nuevo no existe.', 1;

            IF EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoActual AND EsFinal = 1)
                THROW 52003, N'El pedido ya está en un estado final.', 1;

            IF @NuevoEstadoId = 7
                THROW 52004, N'Para cancelar un pedido use ventas.sp_CancelarPedido.', 1;

            IF @NuevoEstadoId = 5 AND @ModalidadId <> 3
                THROW 52005, N'Solo los pedidos express pueden pasar a En camino.', 1;

            UPDATE ventas.Pedido
            SET EstadoId = @NuevoEstadoId
            WHERE PedidoId = @PedidoId;

            INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
            VALUES (@PedidoId, @NuevoEstadoId, @UsuarioId, @Comentario);

            IF @NuevoEstadoId = 5
                UPDATE ventas.Entrega
                SET Estado = 'EnCamino', FechaSalida = SYSDATETIME()
                WHERE PedidoId = @PedidoId;
            ELSE IF @NuevoEstadoId = 6
                UPDATE ventas.Entrega
                SET Estado = 'Entregada', FechaEntrega = SYSDATETIME()
                WHERE PedidoId = @PedidoId;

        COMMIT TRANSACTION;

        SELECT p.PedidoId, p.EstadoId, e.Nombre AS Estado
        FROM ventas.Pedido p
        JOIN ventas.EstadoPedido e ON e.EstadoId = p.EstadoId
        WHERE p.PedidoId = @PedidoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- --------------------------------------------------------------------------
-- Cancela un pedido, reembolsa el pago aprobado y marca la entrega como
-- fallida si no se completó.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.sp_CancelarPedido
    @PedidoId  INT,
    @Motivo    NVARCHAR(200),
    @UsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @EstadoActual TINYINT, @Reembolsados INT;

            SELECT @EstadoActual = p.EstadoId
            FROM ventas.Pedido AS p WITH (UPDLOCK)
            WHERE p.PedidoId = @PedidoId;

            IF @EstadoActual IS NULL
                THROW 52011, N'El pedido no existe.', 1;

            IF EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoActual AND EsFinal = 1)
                THROW 52012, N'El pedido ya está entregado o cancelado.', 1;

            UPDATE ventas.Pedido
            SET EstadoId = 7
            WHERE PedidoId = @PedidoId;

            INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
            VALUES (@PedidoId, 7, @UsuarioId, @Motivo);

            UPDATE ventas.Pago
            SET Estado = 'Reembolsado'
            WHERE PedidoId = @PedidoId AND Estado = 'Aprobado';
            SET @Reembolsados = @@ROWCOUNT;

            UPDATE ventas.Entrega
            SET Estado = 'Fallida'
            WHERE PedidoId = @PedidoId AND Estado IN ('Asignada', 'EnCamino');

        COMMIT TRANSACTION;

        SELECT @PedidoId AS PedidoId,
               CAST(7 AS TINYINT) AS EstadoId,
               N'Cancelado' AS Estado,
               @Reembolsados AS PagosReembolsados;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- --------------------------------------------------------------------------
-- Menú disponible en una sede, con el precio final (precio de sede o base).
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE menu.sp_ObtenerMenuPorSede
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.CategoriaId,
           c.Nombre AS Categoria,
           p.ProductoId,
           p.Nombre AS Producto,
           p.Descripcion,
           ISNULL(ps.PrecioSede, p.PrecioBase) AS Precio,
           p.ImagenUrl
    FROM menu.ProductoSede ps
    JOIN menu.Producto  p ON p.ProductoId  = ps.ProductoId
    JOIN menu.Categoria c ON c.CategoriaId = p.CategoriaId
    WHERE ps.SedeId = @SedeId
      AND ps.Disponible = 1
      AND p.Activo = 1
    ORDER BY c.Orden, p.Nombre;
END
GO
