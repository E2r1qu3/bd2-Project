/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.Entrega

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

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEntregas
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EntregaId, PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega FROM ventas.Entrega;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEntregaPorId
    @EntregaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EntregaId, PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega FROM ventas.Entrega WHERE EntregaId = @EntregaId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarEntrega
    @PedidoId INT,
    @ProveedorEntrega NVARCHAR(60),
    @CodigoSeguimiento VARCHAR(60) = NULL,
    @Estado VARCHAR(15) = 'Asignada',
    @FechaSalida DATETIME2(0) = NULL,
    @FechaEntrega DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO ventas.Entrega (PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega)
            VALUES (@PedidoId, @ProveedorEntrega, @CodigoSeguimiento, @Estado, @FechaSalida, @FechaEntrega);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS EntregaId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarEntrega
    @EntregaId INT,
    @PedidoId INT,
    @ProveedorEntrega NVARCHAR(60),
    @Estado VARCHAR(15),
    @CodigoSeguimiento VARCHAR(60) = NULL,
    @FechaSalida DATETIME2(0) = NULL,
    @FechaEntrega DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Entrega WHERE EntregaId = @EntregaId)
                THROW 54001, N'Entrega: el registro no existe.', 1;

            UPDATE ventas.Entrega
            SET PedidoId = @PedidoId,
                ProveedorEntrega = @ProveedorEntrega,
                CodigoSeguimiento = @CodigoSeguimiento,
                Estado = @Estado,
                FechaSalida = @FechaSalida,
                FechaEntrega = @FechaEntrega
            WHERE EntregaId = @EntregaId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarEntrega
    @EntregaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Entrega WHERE EntregaId = @EntregaId)
                THROW 54001, N'Entrega: el registro no existe.', 1;

            DELETE FROM ventas.Entrega WHERE EntregaId = @EntregaId;
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
