/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures CRUD: menu.ProductoSede, ventas.Cliente, ventas.DireccionCliente
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   Cada SP se crea dentro del esquema de su tabla para que rol_api pueda ejecutarlo.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- ===== menu.ProductoSede =====
CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductosSede
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede
    FROM menu.ProductoSede
    ORDER BY SedeId, ProductoId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductoSedePorId
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede
    FROM menu.ProductoSede
    WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
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
    INSERT INTO menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede)
    VALUES (@SedeId, @ProductoId, @Disponible, @PrecioSede);

    SELECT @SedeId AS SedeId, @ProductoId AS ProductoId;
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
    UPDATE menu.ProductoSede
    SET Disponible = @Disponible,
        PrecioSede = @PrecioSede
    WHERE SedeId = @SedeId AND ProductoId = @ProductoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_EliminarProductoSede
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM menu.ProductoSede
    WHERE SedeId = @SedeId AND ProductoId = @ProductoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== ventas.Cliente =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerClientes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId, Nombre, Apellidos, Correo, Telefono, FechaRegistro
    FROM ventas.Cliente
    ORDER BY ClienteId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerClientePorId
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ClienteId, Nombre, Apellidos, Correo, Telefono, FechaRegistro
    FROM ventas.Cliente
    WHERE ClienteId = @ClienteId;
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
    INSERT INTO ventas.Cliente (Nombre, Apellidos, Correo, Telefono)
    VALUES (@Nombre, @Apellidos, @Correo, @Telefono);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
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
    UPDATE ventas.Cliente
    SET Nombre = @Nombre,
        Apellidos = @Apellidos,
        Correo = @Correo,
        Telefono = @Telefono
    WHERE ClienteId = @ClienteId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarCliente
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.Cliente
    WHERE ClienteId = @ClienteId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== ventas.DireccionCliente =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDireccionesCliente
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DireccionId, ClienteId, Alias, Provincia, Canton, Distrito, Detalle, Latitud, Longitud, Activa
    FROM ventas.DireccionCliente
    ORDER BY DireccionId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDireccionClientePorId
    @DireccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DireccionId, ClienteId, Alias, Provincia, Canton, Distrito, Detalle, Latitud, Longitud, Activa
    FROM ventas.DireccionCliente
    WHERE DireccionId = @DireccionId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarDireccionCliente
    @ClienteId INT,
    @Alias NVARCHAR(50),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @Distrito NVARCHAR(50),
    @Detalle NVARCHAR(250),
    @Latitud DECIMAL(9,6) = NULL,
    @Longitud DECIMAL(9,6) = NULL,
    @Activa BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.DireccionCliente (ClienteId, Alias, Provincia, Canton, Distrito, Detalle, Latitud, Longitud, Activa)
    VALUES (@ClienteId, @Alias, @Provincia, @Canton, @Distrito, @Detalle, @Latitud, @Longitud, @Activa);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarDireccionCliente
    @DireccionId INT,
    @ClienteId INT,
    @Alias NVARCHAR(50),
    @Provincia NVARCHAR(30),
    @Canton NVARCHAR(50),
    @Distrito NVARCHAR(50),
    @Detalle NVARCHAR(250),
    @Latitud DECIMAL(9,6) = NULL,
    @Longitud DECIMAL(9,6) = NULL,
    @Activa BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.DireccionCliente
    SET ClienteId = @ClienteId,
        Alias = @Alias,
        Provincia = @Provincia,
        Canton = @Canton,
        Distrito = @Distrito,
        Detalle = @Detalle,
        Latitud = @Latitud,
        Longitud = @Longitud,
        Activa = @Activa
    WHERE DireccionId = @DireccionId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarDireccionCliente
    @DireccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Borrado lógico: el registro se desactiva para no perder pedidos ni historial asociados.
    UPDATE ventas.DireccionCliente
    SET Activa = 0
    WHERE DireccionId = @DireccionId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

