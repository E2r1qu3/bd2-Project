/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.Cliente

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

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerClientes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId, Nombre, Apellidos, Correo, Telefono, FechaRegistro FROM ventas.Cliente;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerClientePorId
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId, Nombre, Apellidos, Correo, Telefono, FechaRegistro FROM ventas.Cliente WHERE ClienteId = @ClienteId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarCliente
    @Nombre NVARCHAR(60),
    @Apellidos NVARCHAR(80),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO ventas.Cliente (Nombre, Apellidos, Correo, Telefono)
            VALUES (@Nombre, @Apellidos, @Correo, @Telefono);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS ClienteId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarCliente
    @ClienteId INT,
    @Nombre NVARCHAR(60),
    @Apellidos NVARCHAR(80),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Cliente WHERE ClienteId = @ClienteId)
                THROW 54001, N'Cliente: el registro no existe.', 1;

            UPDATE ventas.Cliente
            SET Nombre = @Nombre,
                Apellidos = @Apellidos,
                Correo = @Correo,
                Telefono = @Telefono
            WHERE ClienteId = @ClienteId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarCliente
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Cliente WHERE ClienteId = @ClienteId)
                THROW 54001, N'Cliente: el registro no existe.', 1;

            DELETE FROM ventas.Cliente WHERE ClienteId = @ClienteId;
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
