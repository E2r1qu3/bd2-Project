-- Ejecutar con la BD del proyecto seleccionada. Ajusta las longitudes de tipos a tus tablas.
SET NOCOUNT ON;
GO

-- ===== Sede =====
IF OBJECT_ID('sp_ObtenerSedes','P') IS NOT NULL DROP PROCEDURE sp_ObtenerSedes;
GO
CREATE PROCEDURE sp_ObtenerSedes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, RestauranteId, Nombre, Provincia, HoraApertura, HoraCierre, OfreceExpress FROM core.Sede;
END
GO

IF OBJECT_ID('sp_ObtenerSedePorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerSedePorId;
GO
CREATE PROCEDURE sp_ObtenerSedePorId
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, RestauranteId, Nombre, Provincia, HoraApertura, HoraCierre, OfreceExpress FROM core.Sede WHERE SedeId = @SedeId;
END
GO

IF OBJECT_ID('sp_InsertarSede','P') IS NOT NULL DROP PROCEDURE sp_InsertarSede;
GO
CREATE PROCEDURE sp_InsertarSede
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @Provincia NVARCHAR(50),
    @HoraApertura TIME,
    @HoraCierre TIME,
    @OfreceExpress BIT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.Sede (RestauranteId, Nombre, Provincia, HoraApertura, HoraCierre, OfreceExpress) VALUES (@RestauranteId, @Nombre, @Provincia, @HoraApertura, @HoraCierre, @OfreceExpress);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarSede','P') IS NOT NULL DROP PROCEDURE sp_ActualizarSede;
GO
CREATE PROCEDURE sp_ActualizarSede
    @SedeId INT,
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @Provincia NVARCHAR(50),
    @HoraApertura TIME,
    @HoraCierre TIME,
    @OfreceExpress BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.Sede
    SET RestauranteId = @RestauranteId,
        Nombre = @Nombre,
        Provincia = @Provincia,
        HoraApertura = @HoraApertura,
        HoraCierre = @HoraCierre,
        OfreceExpress = @OfreceExpress
    WHERE SedeId = @SedeId;
END
GO

IF OBJECT_ID('sp_EliminarSede','P') IS NOT NULL DROP PROCEDURE sp_EliminarSede;
GO
CREATE PROCEDURE sp_EliminarSede
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM core.Sede WHERE SedeId = @SedeId;
END
GO

-- ===== Categoria =====
IF OBJECT_ID('sp_ObtenerCategorias','P') IS NOT NULL DROP PROCEDURE sp_ObtenerCategorias;
GO
CREATE PROCEDURE sp_ObtenerCategorias
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, RestauranteId, Nombre FROM menu.Categoria;
END
GO

IF OBJECT_ID('sp_ObtenerCategoriaPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerCategoriaPorId;
GO
CREATE PROCEDURE sp_ObtenerCategoriaPorId
    @CategoriaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, RestauranteId, Nombre FROM menu.Categoria WHERE CategoriaId = @CategoriaId;
END
GO

IF OBJECT_ID('sp_InsertarCategoria','P') IS NOT NULL DROP PROCEDURE sp_InsertarCategoria;
GO
CREATE PROCEDURE sp_InsertarCategoria
    @RestauranteId INT,
    @Nombre NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO menu.Categoria (RestauranteId, Nombre) VALUES (@RestauranteId, @Nombre);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarCategoria','P') IS NOT NULL DROP PROCEDURE sp_ActualizarCategoria;
GO
CREATE PROCEDURE sp_ActualizarCategoria
    @CategoriaId INT,
    @RestauranteId INT,
    @Nombre NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE menu.Categoria
    SET RestauranteId = @RestauranteId,
        Nombre = @Nombre
    WHERE CategoriaId = @CategoriaId;
END
GO

IF OBJECT_ID('sp_EliminarCategoria','P') IS NOT NULL DROP PROCEDURE sp_EliminarCategoria;
GO
CREATE PROCEDURE sp_EliminarCategoria
    @CategoriaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM menu.Categoria WHERE CategoriaId = @CategoriaId;
END
GO

-- ===== Producto =====
IF OBJECT_ID('sp_ObtenerProductos','P') IS NOT NULL DROP PROCEDURE sp_ObtenerProductos;
GO
CREATE PROCEDURE sp_ObtenerProductos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, RestauranteId, CategoriaId, Nombre, PrecioBase, Activo FROM menu.Producto;
END
GO

IF OBJECT_ID('sp_ObtenerProductoPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerProductoPorId;
GO
CREATE PROCEDURE sp_ObtenerProductoPorId
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, RestauranteId, CategoriaId, Nombre, PrecioBase, Activo FROM menu.Producto WHERE ProductoId = @ProductoId;
END
GO

IF OBJECT_ID('sp_InsertarProducto','P') IS NOT NULL DROP PROCEDURE sp_InsertarProducto;
GO
CREATE PROCEDURE sp_InsertarProducto
    @RestauranteId INT,
    @CategoriaId INT,
    @Nombre NVARCHAR(100),
    @PrecioBase DECIMAL(10,2),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO menu.Producto (RestauranteId, CategoriaId, Nombre, PrecioBase, Activo) VALUES (@RestauranteId, @CategoriaId, @Nombre, @PrecioBase, @Activo);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarProducto','P') IS NOT NULL DROP PROCEDURE sp_ActualizarProducto;
GO
CREATE PROCEDURE sp_ActualizarProducto
    @ProductoId INT,
    @RestauranteId INT,
    @CategoriaId INT,
    @Nombre NVARCHAR(100),
    @PrecioBase DECIMAL(10,2),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE menu.Producto
    SET RestauranteId = @RestauranteId,
        CategoriaId = @CategoriaId,
        Nombre = @Nombre,
        PrecioBase = @PrecioBase,
        Activo = @Activo
    WHERE ProductoId = @ProductoId;
END
GO

IF OBJECT_ID('sp_EliminarProducto','P') IS NOT NULL DROP PROCEDURE sp_EliminarProducto;
GO
CREATE PROCEDURE sp_EliminarProducto
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM menu.Producto WHERE ProductoId = @ProductoId;
END
GO
