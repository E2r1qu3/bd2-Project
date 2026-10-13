-- Ejecutar con la BD del proyecto seleccionada. Ajusta las longitudes de tipos a tus tablas.
SET NOCOUNT ON;
GO

-- ===== ProductoSede =====
IF OBJECT_ID('sp_ObtenerProductosSede','P') IS NOT NULL DROP PROCEDURE sp_ObtenerProductosSede;
GO
CREATE PROCEDURE sp_ObtenerProductosSede
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede FROM menu.ProductoSede;
END
GO

IF OBJECT_ID('sp_ObtenerProductoSedePorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerProductoSedePorId;
GO
CREATE PROCEDURE sp_ObtenerProductoSedePorId
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
END
GO

IF OBJECT_ID('sp_InsertarProductoSede','P') IS NOT NULL DROP PROCEDURE sp_InsertarProductoSede;
GO
CREATE PROCEDURE sp_InsertarProductoSede
    @SedeId INT,
    @ProductoId INT,
    @Disponible BIT,
    @PrecioSede DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO  menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede) VALUES (@SedeId, @ProductoId, @Disponible, @PrecioSede);
END
GO

IF OBJECT_ID('sp_ActualizarProductoSede','P') IS NOT NULL DROP PROCEDURE sp_ActualizarProductoSede;
GO
CREATE PROCEDURE sp_ActualizarProductoSede
    @SedeId INT,
    @ProductoId INT,
    @Disponible BIT,
    @PrecioSede DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE  menu.ProductoSede
    SET Disponible = @Disponible,
        PrecioSede = @PrecioSede
    WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
END
GO

IF OBJECT_ID('sp_EliminarProductoSede','P') IS NOT NULL DROP PROCEDURE sp_EliminarProductoSede;
GO
CREATE PROCEDURE sp_EliminarProductoSede
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM  menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
END
GO

-- ===== Cliente =====
IF OBJECT_ID('sp_ObtenerClientes','P') IS NOT NULL DROP PROCEDURE sp_ObtenerClientes;
GO
CREATE PROCEDURE sp_ObtenerClientes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId, Nombre, Apellidos, Correo, Telefono FROM ventas.Cliente;
END
GO

IF OBJECT_ID('sp_ObtenerClientePorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerClientePorId;
GO
CREATE PROCEDURE sp_ObtenerClientePorId
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId, Nombre, Apellidos, Correo, Telefono FROM ventas.Cliente WHERE ClienteId = @ClienteId;
END
GO

IF OBJECT_ID('sp_InsertarCliente','P') IS NOT NULL DROP PROCEDURE sp_InsertarCliente;
GO
CREATE PROCEDURE sp_InsertarCliente
    @Nombre NVARCHAR(100),
    @Apellidos NVARCHAR(100),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.Cliente (Nombre, Apellidos, Correo, Telefono) VALUES (@Nombre, @Apellidos, @Correo, @Telefono);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarCliente','P') IS NOT NULL DROP PROCEDURE sp_ActualizarCliente;
GO
CREATE PROCEDURE sp_ActualizarCliente
    @ClienteId INT,
    @Nombre NVARCHAR(100),
    @Apellidos NVARCHAR(100),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.Cliente
    SET Nombre = @Nombre,
        Apellidos = @Apellidos,
        Correo = @Correo,
        Telefono = @Telefono
    WHERE ClienteId = @ClienteId;
END
GO

IF OBJECT_ID('sp_EliminarCliente','P') IS NOT NULL DROP PROCEDURE sp_EliminarCliente;
GO
CREATE PROCEDURE sp_EliminarCliente
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.Cliente WHERE ClienteId = @ClienteId;
END
GO

-- ===== DireccionCliente =====
IF OBJECT_ID('sp_ObtenerDireccionesCliente','P') IS NOT NULL DROP PROCEDURE sp_ObtenerDireccionesCliente;
GO
CREATE PROCEDURE sp_ObtenerDireccionesCliente
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DireccionId, ClienteId, Alias, Provincia, Detalle FROM ventas.DireccionCliente;
END
GO

IF OBJECT_ID('sp_ObtenerDireccionClientePorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerDireccionClientePorId;
GO
CREATE PROCEDURE sp_ObtenerDireccionClientePorId
    @DireccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DireccionId, ClienteId, Alias, Provincia, Detalle FROM ventas.DireccionCliente WHERE DireccionId = @DireccionId;
END
GO

IF OBJECT_ID('sp_InsertarDireccionCliente','P') IS NOT NULL DROP PROCEDURE sp_InsertarDireccionCliente;
GO
CREATE PROCEDURE sp_InsertarDireccionCliente
    @ClienteId INT,
    @Alias NVARCHAR(50),
    @Provincia NVARCHAR(50),
    @Detalle NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.DireccionCliente (ClienteId, Alias, Provincia, Detalle) VALUES (@ClienteId, @Alias, @Provincia, @Detalle);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarDireccionCliente','P') IS NOT NULL DROP PROCEDURE sp_ActualizarDireccionCliente;
GO
CREATE PROCEDURE sp_ActualizarDireccionCliente
    @DireccionId INT,
    @ClienteId INT,
    @Alias NVARCHAR(50),
    @Provincia NVARCHAR(50),
    @Detalle NVARCHAR(250)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.DireccionCliente
    SET ClienteId = @ClienteId,
        Alias = @Alias,
        Provincia = @Provincia,
        Detalle = @Detalle
    WHERE DireccionId = @DireccionId;
END
GO

IF OBJECT_ID('sp_EliminarDireccionCliente','P') IS NOT NULL DROP PROCEDURE sp_EliminarDireccionCliente;
GO
CREATE PROCEDURE sp_EliminarDireccionCliente
    @DireccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.DireccionCliente WHERE DireccionId = @DireccionId;
END
GO