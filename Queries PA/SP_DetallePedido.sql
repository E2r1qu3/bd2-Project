/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.DetallePedido

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDetallesPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Subtotal, Nota FROM ventas.DetallePedido;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDetallePedidoPorId
    @PedidoId INT,
    @Linea SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Subtotal, Nota FROM ventas.DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT,
    @ProductoId INT,
    @Cantidad SMALLINT,
    @PrecioUnitario DECIMAL(12,2),
    @Nota NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM ventas.DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea)
                THROW 54002, N'DetallePedido: ya existe un registro con ese identificador.', 1;

            INSERT INTO ventas.DetallePedido (PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Nota)
            VALUES (@PedidoId, @Linea, @ProductoId, @Cantidad, @PrecioUnitario, @Nota);

        COMMIT TRANSACTION;

        SELECT @PedidoId AS PedidoId, @Linea AS Linea;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT,
    @ProductoId INT,
    @Cantidad SMALLINT,
    @PrecioUnitario DECIMAL(12,2),
    @Nota NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea)
                THROW 54001, N'DetallePedido: el registro no existe.', 1;

            UPDATE ventas.DetallePedido
            SET ProductoId = @ProductoId,
                Cantidad = @Cantidad,
                PrecioUnitario = @PrecioUnitario,
                Nota = @Nota
            WHERE PedidoId = @PedidoId AND Linea = @Linea;
            DECLARE @Filas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @Filas AS FilasAfectadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea)
                THROW 54001, N'DetallePedido: el registro no existe.', 1;

            DELETE FROM ventas.DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea;
            DECLARE @Filas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @Filas AS FilasAfectadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
