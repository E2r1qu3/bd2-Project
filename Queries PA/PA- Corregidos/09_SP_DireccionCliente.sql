/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== DireccionCliente =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDireccionesCliente
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DireccionId, ClienteId, Alias, Provincia, Canton, Distrito, Detalle, Latitud, Longitud, Activa FROM ventas.DireccionCliente;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDireccionClientePorId
    @DireccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DireccionId, ClienteId, Alias, Provincia, Canton, Distrito, Detalle, Latitud, Longitud, Activa FROM ventas.DireccionCliente WHERE DireccionId = @DireccionId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarDireccionCliente
    @ClienteId INT,
    @Alias NVARCHAR(50),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @Distrito NVARCHAR(50),
    @Detalle NVARCHAR(250),
    @Latitud DECIMAL(9,6) = NULL,
    @Longitud DECIMAL(9,6) = NULL,
    @Activa BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO ventas.DireccionCliente (ClienteId, Alias, Provincia, Canton, Distrito, Detalle, Latitud, Longitud, Activa)
            VALUES (@ClienteId, @Alias, @Provincia, @Canton, @Distrito, @Detalle, @Latitud, @Longitud, @Activa);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS DireccionId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarDireccionCliente
    @DireccionId INT,
    @ClienteId INT,
    @Alias NVARCHAR(50),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @Distrito NVARCHAR(50),
    @Detalle NVARCHAR(250),
    @Activa BIT,
    @Latitud DECIMAL(9,6) = NULL,
    @Longitud DECIMAL(9,6) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.DireccionCliente WHERE DireccionId = @DireccionId)
                THROW 54001, N'DireccionCliente: el registro no existe.', 1;

            UPDATE ventas.DireccionCliente
            SET ClienteId = @ClienteId,
                Alias = @Alias,
                Provincia = @Provincia,
                Canton = @Canton,
                Distrito = @Distrito,
                Detalle = @Detalle,
                Latitud = @Latitud,
                Longitud = @Longitud,
                Activa = @Activa
            WHERE DireccionId = @DireccionId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarDireccionCliente
    @DireccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.DireccionCliente WHERE DireccionId = @DireccionId)
                THROW 54001, N'DireccionCliente: el registro no existe.', 1;

            DELETE FROM ventas.DireccionCliente WHERE DireccionId = @DireccionId;
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
