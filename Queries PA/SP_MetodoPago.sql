/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.MetodoPago

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

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerMetodosPago
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MetodoPagoId, Nombre FROM ventas.MetodoPago;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerMetodoPagoPorId
    @MetodoPagoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MetodoPagoId, Nombre FROM ventas.MetodoPago WHERE MetodoPagoId = @MetodoPagoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarMetodoPago
    @MetodoPagoId TINYINT,
    @Nombre NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM ventas.MetodoPago WHERE MetodoPagoId = @MetodoPagoId)
                THROW 54002, N'MetodoPago: ya existe un registro con ese identificador.', 1;

            INSERT INTO ventas.MetodoPago (MetodoPagoId, Nombre)
            VALUES (@MetodoPagoId, @Nombre);

        COMMIT TRANSACTION;

        SELECT @MetodoPagoId AS MetodoPagoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarMetodoPago
    @MetodoPagoId TINYINT,
    @Nombre NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.MetodoPago WHERE MetodoPagoId = @MetodoPagoId)
                THROW 54001, N'MetodoPago: el registro no existe.', 1;

            UPDATE ventas.MetodoPago
            SET Nombre = @Nombre
            WHERE MetodoPagoId = @MetodoPagoId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarMetodoPago
    @MetodoPagoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.MetodoPago WHERE MetodoPagoId = @MetodoPagoId)
                THROW 54001, N'MetodoPago: el registro no existe.', 1;

            DELETE FROM ventas.MetodoPago WHERE MetodoPagoId = @MetodoPagoId;
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
