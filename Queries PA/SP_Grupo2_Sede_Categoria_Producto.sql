/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures CRUD: core.Sede, menu.Categoria, menu.Producto
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   Cada SP se crea dentro del esquema de su tabla para que rol_api pueda ejecutarlo.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- ===== core.Sede =====
CREATE OR ALTER PROCEDURE core.sp_ObtenerSedes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress, Activa
    FROM core.Sede
    ORDER BY SedeId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerSedePorId
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress, Activa
    FROM core.Sede
    WHERE SedeId = @SedeId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarSede
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @DireccionExacta NVARCHAR(250),
    @Telefono VARCHAR(20) = NULL,
    @HoraApertura TIME(0),
    @HoraCierre TIME(0),
    @OfreceExpress BIT = 1,
    @Activa BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.Sede (RestauranteId, Nombre, Provincia, Canton, DireccionExacta, Telefono, HoraApertura, HoraCierre, OfreceExpress, Activa)
    VALUES (@RestauranteId, @Nombre, @Provincia, @Canton, @DireccionExacta, @Telefono, @HoraApertura, @HoraCierre, @OfreceExpress, @Activa);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarSede
    @SedeId INT,
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @DireccionExacta NVARCHAR(250),
    @Telefono VARCHAR(20) = NULL,
    @HoraApertura TIME(0),
    @HoraCierre TIME(0),
    @OfreceExpress BIT,
    @Activa BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.Sede
    SET RestauranteId = @RestauranteId,
        Nombre = @Nombre,
        Provincia = @Provincia,
        Canton = @Canton,
        DireccionExacta = @DireccionExacta,
        Telefono = @Telefono,
        HoraApertura = @HoraApertura,
        HoraCierre = @HoraCierre,
        OfreceExpress = @OfreceExpress,
        Activa = @Activa
    WHERE SedeId = @SedeId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE core.sp_EliminarSede
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Borrado lógico: el registro se desactiva para no perder pedidos ni historial asociados.
    UPDATE core.Sede
    SET Activa = 0
    WHERE SedeId = @SedeId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== menu.Categoria =====
CREATE OR ALTER PROCEDURE menu.sp_ObtenerCategorias
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, RestauranteId, Nombre, Orden
    FROM menu.Categoria
    ORDER BY CategoriaId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerCategoriaPorId
    @CategoriaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, RestauranteId, Nombre, Orden
    FROM menu.Categoria
    WHERE CategoriaId = @CategoriaId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_InsertarCategoria
    @RestauranteId INT,
    @Nombre NVARCHAR(60),
    @Orden SMALLINT = 0
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO menu.Categoria (RestauranteId, Nombre, Orden)
    VALUES (@RestauranteId, @Nombre, @Orden);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
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
    UPDATE menu.Categoria
    SET RestauranteId = @RestauranteId,
        Nombre = @Nombre,
        Orden = @Orden
    WHERE CategoriaId = @CategoriaId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_EliminarCategoria
    @CategoriaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM menu.Categoria
    WHERE CategoriaId = @CategoriaId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== menu.Producto =====
CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase, ImagenUrl, Activo
    FROM menu.Producto
    ORDER BY ProductoId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductoPorId
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductoId, RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase, ImagenUrl, Activo
    FROM menu.Producto
    WHERE ProductoId = @ProductoId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_InsertarProducto
    @RestauranteId INT,
    @CategoriaId INT,
    @Nombre NVARCHAR(100),
    @Descripcion NVARCHAR(400) = NULL,
    @PrecioBase DECIMAL(12,2),
    @ImagenUrl NVARCHAR(400) = NULL,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO menu.Producto (RestauranteId, CategoriaId, Nombre, Descripcion, PrecioBase, ImagenUrl, Activo)
    VALUES (@RestauranteId, @CategoriaId, @Nombre, @Descripcion, @PrecioBase, @ImagenUrl, @Activo);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ActualizarProducto
    @ProductoId INT,
    @RestauranteId INT,
    @CategoriaId INT,
    @Nombre NVARCHAR(100),
    @Descripcion NVARCHAR(400) = NULL,
    @PrecioBase DECIMAL(12,2),
    @ImagenUrl NVARCHAR(400) = NULL,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE menu.Producto
    SET RestauranteId = @RestauranteId,
        CategoriaId = @CategoriaId,
        Nombre = @Nombre,
        Descripcion = @Descripcion,
        PrecioBase = @PrecioBase,
        ImagenUrl = @ImagenUrl,
        Activo = @Activo
    WHERE ProductoId = @ProductoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_EliminarProducto
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Borrado lógico: el registro se desactiva para no perder pedidos ni historial asociados.
    UPDATE menu.Producto
    SET Activo = 0
    WHERE ProductoId = @ProductoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

