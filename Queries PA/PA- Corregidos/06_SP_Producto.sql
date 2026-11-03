/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Producto =====
CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase, ImagenUrl, Activo FROM menu.Producto;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductoPorId
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase, ImagenUrl, Activo FROM menu.Producto WHERE ProductoId = @ProductoId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_InsertarProducto
    @RestauranteId INT,
    @CategoriaId INT,
    @Nombre NVARCHAR(100),
    @PrecioBase DECIMAL(12,2),
    @Descripcion NVARCHAR(400) = NULL,
    @ImagenUrl NVARCHAR(400) = NULL,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO menu.Producto (RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase, ImagenUrl, Activo)
            VALUES (@RestauranteId, @CategoriaId, @Nombre, @Descripcion, @PrecioBase, @ImagenUrl, @Activo);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS ProductoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ActualizarProducto
    @ProductoId INT,
    @RestauranteId INT,
    @CategoriaId INT,
    @Nombre NVARCHAR(100),
    @PrecioBase DECIMAL(12,2),
    @Activo BIT,
    @Descripcion NVARCHAR(400) = NULL,
    @ImagenUrl NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.Producto WHERE ProductoId = @ProductoId)
                THROW 54001, N'Producto: el registro no existe.', 1;

            UPDATE menu.Producto
            SET RestauranteId = @RestauranteId,
                CategoriaId = @CategoriaId,
                Nombre = @Nombre,
                Descripcion = @Descripcion,
                PrecioBase = @PrecioBase,
                ImagenUrl = @ImagenUrl,
                Activo = @Activo
            WHERE ProductoId = @ProductoId;
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

CREATE OR ALTER PROCEDURE menu.sp_EliminarProducto
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.Producto WHERE ProductoId = @ProductoId)
                THROW 54001, N'Producto: el registro no existe.', 1;

            DELETE FROM menu.Producto WHERE ProductoId = @ProductoId;
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
