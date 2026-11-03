/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Sede =====
CREATE OR ALTER PROCEDURE core.sp_ObtenerSedes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress, Activa FROM core.Sede;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerSedePorId
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress, Activa FROM core.Sede WHERE SedeId = @SedeId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarSede
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @DireccionExacta NVARCHAR(250),
    @HoraApertura TIME(0),
    @HoraCierre TIME(0),
    @Telefono VARCHAR(20) = NULL,
    @OfreceExpress BIT = 1,
    @Activa BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO core.Sede (RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress, Activa)
            VALUES (@RestauranteId, @Nombre, @Provincia, @Canton, @DireccionExacta, @Telefono, @HoraApertura, @HoraCierre, @OfreceExpress, @Activa);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS SedeId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarSede
    @SedeId INT,
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @DireccionExacta NVARCHAR(250),
    @HoraApertura TIME(0),
    @HoraCierre TIME(0),
    @OfreceExpress BIT,
    @Activa BIT,
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Sede WHERE SedeId = @SedeId)
                THROW 54001, N'Sede: el registro no existe.', 1;

            UPDATE core.Sede
            SET RestauranteId = @RestauranteId,
                Nombre = @Nombre,
                Provincia = @Provincia,
                Canton = @Canton,
                DireccionExacta = @DireccionExacta,
                Telefono = @Telefono,
                HoraApertura = @HoraApertura,
                HoraCierre = @HoraCierre,
                OfreceExpress = @OfreceExpress,
                Activa = @Activa
            WHERE SedeId = @SedeId;
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

CREATE OR ALTER PROCEDURE core.sp_EliminarSede
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Sede WHERE SedeId = @SedeId)
                THROW 54001, N'Sede: el registro no existe.', 1;

            DELETE FROM core.Sede WHERE SedeId = @SedeId;
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
