/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== ProductoSede =====
CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductosSede
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede FROM menu.ProductoSede;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductoSedePorId
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_InsertarProductoSede
    @SedeId INT,
    @ProductoId INT,
    @Disponible BIT = 1,
    @PrecioSede DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId)
                THROW 54002, N'ProductoSede: ya existe un registro con ese identificador.', 1;

            INSERT INTO menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede)
            VALUES (@SedeId, @ProductoId, @Disponible, @PrecioSede);

        COMMIT TRANSACTION;

        SELECT @SedeId AS SedeId, @ProductoId AS ProductoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ActualizarProductoSede
    @SedeId INT,
    @ProductoId INT,
    @Disponible BIT,
    @PrecioSede DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId)
                THROW 54001, N'ProductoSede: el registro no existe.', 1;

            UPDATE menu.ProductoSede
            SET Disponible = @Disponible,
                PrecioSede = @PrecioSede
            WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
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

CREATE OR ALTER PROCEDURE menu.sp_EliminarProductoSede
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId)
                THROW 54001, N'ProductoSede: el registro no existe.', 1;

            DELETE FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
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
