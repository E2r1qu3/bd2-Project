/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== PlanSuscripcion =====
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

            DELETE FROM core.PlanSuscripcion WHERE PlanId = @PlanId;
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
