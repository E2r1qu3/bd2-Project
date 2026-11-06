/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.EstadoPedido

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

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEstadosPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EstadoId, Nombre, EsFinal FROM ventas.EstadoPedido;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEstadoPedidoPorId
    @EstadoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EstadoId, Nombre, EsFinal FROM ventas.EstadoPedido WHERE EstadoId = @EstadoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarEstadoPedido
    @EstadoId TINYINT,
    @Nombre NVARCHAR(30),
    @EsFinal BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoId)
                THROW 54002, N'EstadoPedido: ya existe un registro con ese identificador.', 1;

            INSERT INTO ventas.EstadoPedido (EstadoId, Nombre, EsFinal)
            VALUES (@EstadoId, @Nombre, @EsFinal);

        COMMIT TRANSACTION;

        SELECT @EstadoId AS EstadoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarEstadoPedido
    @EstadoId TINYINT,
    @Nombre NVARCHAR(30),
    @EsFinal BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoId)
                THROW 54001, N'EstadoPedido: el registro no existe.', 1;

            UPDATE ventas.EstadoPedido
            SET Nombre = @Nombre,
                EsFinal = @EsFinal
            WHERE EstadoId = @EstadoId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarEstadoPedido
    @EstadoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoId)
                THROW 54001, N'EstadoPedido: el registro no existe.', 1;

            DELETE FROM ventas.EstadoPedido WHERE EstadoId = @EstadoId;
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
