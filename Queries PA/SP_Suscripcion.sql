/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla core.Suscripcion

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

CREATE OR ALTER PROCEDURE core.sp_ObtenerSuscripciones
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SuscripcionId, RestauranteId, PlanId, FechaInicio, FechaFin, Estado FROM core.Suscripcion;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerSuscripcionPorId
    @SuscripcionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SuscripcionId, RestauranteId, PlanId, FechaInicio, FechaFin, Estado FROM core.Suscripcion WHERE SuscripcionId = @SuscripcionId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarSuscripcion
    @RestauranteId INT,
    @PlanId INT,
    @FechaInicio DATE,
    @FechaFin DATE = NULL,
    @Estado VARCHAR(15) = 'Activa'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO core.Suscripcion (RestauranteId, PlanId, FechaInicio, FechaFin, Estado)
            VALUES (@RestauranteId, @PlanId, @FechaInicio, @FechaFin, @Estado);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS SuscripcionId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarSuscripcion
    @SuscripcionId INT,
    @RestauranteId INT,
    @PlanId INT,
    @FechaInicio DATE,
    @Estado VARCHAR(15),
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Suscripcion WHERE SuscripcionId = @SuscripcionId)
                THROW 54001, N'Suscripcion: el registro no existe.', 1;

            UPDATE core.Suscripcion
            SET RestauranteId = @RestauranteId,
                PlanId = @PlanId,
                FechaInicio = @FechaInicio,
                FechaFin = @FechaFin,
                Estado = @Estado
            WHERE SuscripcionId = @SuscripcionId;
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

CREATE OR ALTER PROCEDURE core.sp_EliminarSuscripcion
    @SuscripcionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Suscripcion WHERE SuscripcionId = @SuscripcionId)
                THROW 54001, N'Suscripcion: el registro no existe.', 1;

            DELETE FROM core.Suscripcion WHERE SuscripcionId = @SuscripcionId;
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
