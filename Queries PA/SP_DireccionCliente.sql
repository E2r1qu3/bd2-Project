/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.DireccionCliente

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Eliminar hace borrado lógico (Activa = 0).
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

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

            -- Borrado lógico: el registro queda inactivo y se conserva su historial.
            UPDATE ventas.DireccionCliente SET Activa = 0 WHERE DireccionId = @DireccionId;
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
