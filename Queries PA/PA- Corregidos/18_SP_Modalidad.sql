/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Modalidad =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerModalidades
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ModalidadId, Nombre, RequiereDireccion FROM ventas.Modalidad;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerModalidadPorId
    @ModalidadId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ModalidadId, Nombre, RequiereDireccion FROM ventas.Modalidad WHERE ModalidadId = @ModalidadId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarModalidad
    @ModalidadId TINYINT,
    @Nombre NVARCHAR(30),
    @RequiereDireccion BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM ventas.Modalidad WHERE ModalidadId = @ModalidadId)
                THROW 54002, N'Modalidad: ya existe un registro con ese identificador.', 1;

            INSERT INTO ventas.Modalidad (ModalidadId, Nombre, RequiereDireccion)
            VALUES (@ModalidadId, @Nombre, @RequiereDireccion);

        COMMIT TRANSACTION;

        SELECT @ModalidadId AS ModalidadId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarModalidad
    @ModalidadId TINYINT,
    @Nombre NVARCHAR(30),
    @RequiereDireccion BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Modalidad WHERE ModalidadId = @ModalidadId)
                THROW 54001, N'Modalidad: el registro no existe.', 1;

            UPDATE ventas.Modalidad
            SET Nombre = @Nombre,
                RequiereDireccion = @RequiereDireccion
            WHERE ModalidadId = @ModalidadId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarModalidad
    @ModalidadId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Modalidad WHERE ModalidadId = @ModalidadId)
                THROW 54001, N'Modalidad: el registro no existe.', 1;

            DELETE FROM ventas.Modalidad WHERE ModalidadId = @ModalidadId;
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
