-- Ejecutar con la BD del proyecto seleccionada. Ajusta las longitudes de tipos a tus tablas.
SET NOCOUNT ON;
GO

-- ===== Pedido =====
IF OBJECT_ID('sp_ObtenerPedidos','P') IS NOT NULL DROP PROCEDURE sp_ObtenerPedidos;
GO
CREATE PROCEDURE sp_ObtenerPedidos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total FROM Pedido;
END
GO

IF OBJECT_ID('sp_ObtenerPedidoPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerPedidoPorId;
GO
CREATE PROCEDURE sp_ObtenerPedidoPorId
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total FROM Pedido WHERE PedidoId = @PedidoId;
END
GO

IF OBJECT_ID('sp_InsertarPedido','P') IS NOT NULL DROP PROCEDURE sp_InsertarPedido;
GO
CREATE PROCEDURE sp_InsertarPedido
    @ClienteId INT,
    @SedeId INT,
    @ModalidadId TINYINT,
    @EstadoId TINYINT,
    @FechaPedido DATETIME2,
    @Subtotal DECIMAL(10,2),
    @Impuesto DECIMAL(10,2),
    @CostoEnvio DECIMAL(10,2),
    @Total DECIMAL(10,2),
    @DireccionId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Pedido (ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total) VALUES (@ClienteId, @SedeId, @ModalidadId, @EstadoId, @DireccionId, @FechaPedido, @Subtotal, @Impuesto, @CostoEnvio, @Total);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarPedido','P') IS NOT NULL DROP PROCEDURE sp_ActualizarPedido;
GO
CREATE PROCEDURE sp_ActualizarPedido
    @PedidoId INT,
    @ClienteId INT,
    @SedeId INT,
    @ModalidadId TINYINT,
    @EstadoId TINYINT,
    @FechaPedido DATETIME2,
    @Subtotal DECIMAL(10,2),
    @Impuesto DECIMAL(10,2),
    @CostoEnvio DECIMAL(10,2),
    @Total DECIMAL(10,2),
    @DireccionId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Pedido
    SET ClienteId = @ClienteId,
        SedeId = @SedeId,
        ModalidadId = @ModalidadId,
        EstadoId = @EstadoId,
        DireccionId = @DireccionId,
        FechaPedido = @FechaPedido,
        Subtotal = @Subtotal,
        Impuesto = @Impuesto,
        CostoEnvio = @CostoEnvio,
        Total = @Total
    WHERE PedidoId = @PedidoId;
END
GO

IF OBJECT_ID('sp_EliminarPedido','P') IS NOT NULL DROP PROCEDURE sp_EliminarPedido;
GO
CREATE PROCEDURE sp_EliminarPedido
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Pedido WHERE PedidoId = @PedidoId;
END
GO

-- ===== EstadoPedido =====
IF OBJECT_ID('sp_ObtenerEstadosPedido','P') IS NOT NULL DROP PROCEDURE sp_ObtenerEstadosPedido;
GO
CREATE PROCEDURE sp_ObtenerEstadosPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EstadoId, Nombre, EsFinal FROM EstadoPedido;
END
GO

IF OBJECT_ID('sp_ObtenerEstadoPedidoPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerEstadoPedidoPorId;
GO
CREATE PROCEDURE sp_ObtenerEstadoPedidoPorId
    @EstadoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EstadoId, Nombre, EsFinal FROM EstadoPedido WHERE EstadoId = @EstadoId;
END
GO

IF OBJECT_ID('sp_InsertarEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_InsertarEstadoPedido;
GO
CREATE PROCEDURE sp_InsertarEstadoPedido
    @Nombre NVARCHAR(50),
    @EsFinal BIT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO EstadoPedido (Nombre, EsFinal) VALUES (@Nombre, @EsFinal);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_ActualizarEstadoPedido;
GO
CREATE PROCEDURE sp_ActualizarEstadoPedido
    @EstadoId TINYINT,
    @Nombre NVARCHAR(50),
    @EsFinal BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE EstadoPedido
    SET Nombre = @Nombre,
        EsFinal = @EsFinal
    WHERE EstadoId = @EstadoId;
END
GO

IF OBJECT_ID('sp_EliminarEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_EliminarEstadoPedido;
GO
CREATE PROCEDURE sp_EliminarEstadoPedido
    @EstadoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM EstadoPedido WHERE EstadoId = @EstadoId;
END
GO

-- ===== DetallePedido =====
IF OBJECT_ID('sp_ObtenerDetallesPedido','P') IS NOT NULL DROP PROCEDURE sp_ObtenerDetallesPedido;
GO
CREATE PROCEDURE sp_ObtenerDetallesPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario FROM DetallePedido;
END
GO

IF OBJECT_ID('sp_ObtenerDetallePedidoPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerDetallePedidoPorId;
GO
CREATE PROCEDURE sp_ObtenerDetallePedidoPorId
    @PedidoId INT,
    @Linea SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario FROM DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea;
END
GO

IF OBJECT_ID('sp_InsertarDetallePedido','P') IS NOT NULL DROP PROCEDURE sp_InsertarDetallePedido;
GO
CREATE PROCEDURE sp_InsertarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT,
    @ProductoId INT,
    @Cantidad SMALLINT,
    @PrecioUnitario DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO DetallePedido (PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario) VALUES (@PedidoId, @Linea, @ProductoId, @Cantidad, @PrecioUnitario);
END
GO

IF OBJECT_ID('sp_ActualizarDetallePedido','P') IS NOT NULL DROP PROCEDURE sp_ActualizarDetallePedido;
GO
CREATE PROCEDURE sp_ActualizarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT,
    @ProductoId INT,
    @Cantidad SMALLINT,
    @PrecioUnitario DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE DetallePedido
    SET ProductoId = @ProductoId,
        Cantidad = @Cantidad,
        PrecioUnitario = @PrecioUnitario
    WHERE PedidoId = @PedidoId AND Linea = @Linea;
END
GO

IF OBJECT_ID('sp_EliminarDetallePedido','P') IS NOT NULL DROP PROCEDURE sp_EliminarDetallePedido;
GO
CREATE PROCEDURE sp_EliminarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM DetallePedido WHERE PedidoId = @PedidoId AND Linea = @Linea;
END
GO
