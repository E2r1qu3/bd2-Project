/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Restaurante =====
CREATE OR ALTER PROCEDURE core.sp_ObtenerRestaurantes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Telefono, Activo, FechaRegistro FROM core.Restaurante;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerRestaurantePorId
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Telefono, Activo, FechaRegistro FROM core.Restaurante WHERE RestauranteId = @RestauranteId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarRestaurante
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Telefono, Activo)
            VALUES (@Nombre, @CedulaJuridica, @Correo, @Telefono, @Activo);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS RestauranteId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarRestaurante
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Activo BIT,
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Restaurante WHERE RestauranteId = @RestauranteId)
                THROW 54001, N'Restaurante: el registro no existe.', 1;

            UPDATE core.Restaurante
            SET Nombre = @Nombre,
                CedulaJuridica = @CedulaJuridica,
                Correo = @Correo,
                Telefono = @Telefono,
                Activo = @Activo
            WHERE RestauranteId = @RestauranteId;
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

CREATE OR ALTER PROCEDURE core.sp_EliminarRestaurante
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Restaurante WHERE RestauranteId = @RestauranteId)
                THROW 54001, N'Restaurante: el registro no existe.', 1;

            DELETE FROM core.Restaurante WHERE RestauranteId = @RestauranteId;
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
