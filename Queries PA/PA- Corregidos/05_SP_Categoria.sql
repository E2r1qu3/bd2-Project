/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Categoria =====
CREATE OR ALTER PROCEDURE menu.sp_ObtenerCategorias
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, RestauranteId, Nombre, Orden FROM menu.Categoria;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerCategoriaPorId
    @CategoriaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, RestauranteId, Nombre, Orden FROM menu.Categoria WHERE CategoriaId = @CategoriaId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_InsertarCategoria
    @RestauranteId INT,
    @Nombre NVARCHAR(60),
    @Orden SMALLINT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO menu.Categoria (RestauranteId, Nombre, Orden)
            VALUES (@RestauranteId, @Nombre, @Orden);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS CategoriaId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ActualizarCategoria
    @CategoriaId INT,
    @RestauranteId INT,
    @Nombre NVARCHAR(60),
    @Orden SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.Categoria WHERE CategoriaId = @CategoriaId)
                THROW 54001, N'Categoria: el registro no existe.', 1;

            UPDATE menu.Categoria
            SET RestauranteId = @RestauranteId,
                Nombre = @Nombre,
                Orden = @Orden
            WHERE CategoriaId = @CategoriaId;
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

CREATE OR ALTER PROCEDURE menu.sp_EliminarCategoria
    @CategoriaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.Categoria WHERE CategoriaId = @CategoriaId)
                THROW 54001, N'Categoria: el registro no existe.', 1;

            DELETE FROM menu.Categoria WHERE CategoriaId = @CategoriaId;
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
