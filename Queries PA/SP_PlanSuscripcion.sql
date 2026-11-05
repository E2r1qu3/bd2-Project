/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla core.PlanSuscripcion

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Eliminar hace borrado lógico (Activo = 0).
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

CREATE OR ALTER PROCEDURE core.sp_ObtenerPlanesSuscripcion
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, Nombre, MaxSedes, PrecioMensual, Activo FROM core.PlanSuscripcion;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerPlanSuscripcionPorId
    @PlanId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, Nombre, MaxSedes, PrecioMensual, Activo FROM core.PlanSuscripcion WHERE PlanId = @PlanId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarPlanSuscripcion
    @Nombre NVARCHAR(50),
    @MaxSedes INT,
    @PrecioMensual DECIMAL(12,2),
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO core.PlanSuscripcion (Nombre, MaxSedes, PrecioMensual, Activo)
            VALUES (@Nombre, @MaxSedes, @PrecioMensual, @Activo);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS PlanId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarPlanSuscripcion
    @PlanId INT,
    @Nombre NVARCHAR(50),
    @MaxSedes INT,
    @PrecioMensual DECIMAL(12,2),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.PlanSuscripcion WHERE PlanId = @PlanId)
                THROW 54001, N'PlanSuscripcion: el registro no existe.', 1;

            UPDATE core.PlanSuscripcion
            SET Nombre = @Nombre,
                MaxSedes = @MaxSedes,
                PrecioMensual = @PrecioMensual,
                Activo = @Activo
            WHERE PlanId = @PlanId;
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

CREATE OR ALTER PROCEDURE core.sp_EliminarPlanSuscripcion
    @PlanId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.PlanSuscripcion WHERE PlanId = @PlanId)
                THROW 54001, N'PlanSuscripcion: el registro no existe.', 1;

            -- Borrado lógico: el registro queda inactivo y se conserva su historial.
            UPDATE core.PlanSuscripcion SET Activo = 0 WHERE PlanId = @PlanId;
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
