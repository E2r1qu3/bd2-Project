/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Usuario =====
CREATE OR ALTER PROCEDURE seguridad.sp_ObtenerUsuarios
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, Correo, RolId, RestauranteId, SedeId, ClienteId, Activo, IntentosFallidos, UltimoAcceso, FechaCreacion FROM seguridad.Usuario;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_ObtenerUsuarioPorId
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, Correo, RolId, RestauranteId, SedeId, ClienteId, Activo, IntentosFallidos, UltimoAcceso, FechaCreacion FROM seguridad.Usuario WHERE UsuarioId = @UsuarioId;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_EliminarUsuario
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM seguridad.Usuario WHERE UsuarioId = @UsuarioId)
                THROW 54001, N'Usuario: el registro no existe.', 1;

            DELETE FROM seguridad.Usuario WHERE UsuarioId = @UsuarioId;
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
