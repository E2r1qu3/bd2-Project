/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla seguridad.Rol

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

CREATE OR ALTER PROCEDURE seguridad.sp_ObtenerRoles
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RolId, Nombre, Descripcion FROM seguridad.Rol;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_ObtenerRolPorId
    @RolId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RolId, Nombre, Descripcion FROM seguridad.Rol WHERE RolId = @RolId;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_InsertarRol
    @RolId TINYINT,
    @Nombre NVARCHAR(30),
    @Descripcion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM seguridad.Rol WHERE RolId = @RolId)
                THROW 54002, N'Rol: ya existe un registro con ese identificador.', 1;

            INSERT INTO seguridad.Rol (RolId, Nombre, Descripcion)
            VALUES (@RolId, @Nombre, @Descripcion);

        COMMIT TRANSACTION;

        SELECT @RolId AS RolId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_ActualizarRol
    @RolId TINYINT,
    @Nombre NVARCHAR(30),
    @Descripcion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM seguridad.Rol WHERE RolId = @RolId)
                THROW 54001, N'Rol: el registro no existe.', 1;

            UPDATE seguridad.Rol
            SET Nombre = @Nombre,
                Descripcion = @Descripcion
            WHERE RolId = @RolId;
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

CREATE OR ALTER PROCEDURE seguridad.sp_EliminarRol
    @RolId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM seguridad.Rol WHERE RolId = @RolId)
                THROW 54001, N'Rol: el registro no existe.', 1;

            DELETE FROM seguridad.Rol WHERE RolId = @RolId;
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
