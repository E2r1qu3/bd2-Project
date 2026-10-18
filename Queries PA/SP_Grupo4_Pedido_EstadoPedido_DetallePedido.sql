/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures CRUD: ventas.Pedido, ventas.EstadoPedido, ventas.DetallePedido
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   Cada SP se crea dentro del esquema de su tabla para que rol_api pueda ejecutarlo.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- ===== ventas.Pedido =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPedidos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total, Notas
    FROM ventas.Pedido
    ORDER BY PedidoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPedidoPorId
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total, Notas
    FROM ventas.Pedido
    WHERE PedidoId = @PedidoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarPedido
    @ClienteId INT,
    @SedeId INT,
    @ModalidadId TINYINT,
    @EstadoId TINYINT = 1,
    @DireccionId INT = NULL,
    @Subtotal DECIMAL(12,2) = 0,
    @Impuesto DECIMAL(12,2) = 0,
    @CostoEnvio DECIMAL(12,2) = 0,
    @Notas NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, Subtotal, Impuesto, CostoEnvio, Notas)
    VALUES (@ClienteId, @SedeId, @ModalidadId, @EstadoId, @DireccionId, @Subtotal, @Impuesto, @CostoEnvio, @Notas);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarPedido
    @PedidoId INT,
    @ClienteId INT,
    @SedeId INT,
    @ModalidadId TINYINT,
    @EstadoId TINYINT,
    @DireccionId INT = NULL,
    @Subtotal DECIMAL(12,2),
    @Impuesto DECIMAL(12,2),
    @CostoEnvio DECIMAL(12,2),
    @Notas NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.Pedido
    SET ClienteId = @ClienteId,
        SedeId = @SedeId,
        ModalidadId = @ModalidadId,
        EstadoId = @EstadoId,
        DireccionId = @DireccionId,
        Subtotal = @Subtotal,
        Impuesto = @Impuesto,
        CostoEnvio = @CostoEnvio,
        Notas = @Notas
    WHERE PedidoId = @PedidoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarPedido
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.Pedido
    WHERE PedidoId = @PedidoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== ventas.EstadoPedido =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEstadosPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EstadoId, Nombre, EsFinal
    FROM ventas.EstadoPedido
    ORDER BY EstadoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEstadoPedidoPorId
    @EstadoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EstadoId, Nombre, EsFinal
    FROM ventas.EstadoPedido
    WHERE EstadoId = @EstadoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarEstadoPedido
    @EstadoId TINYINT,
    @Nombre NVARCHAR(30),
    @EsFinal BIT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.EstadoPedido (EstadoId, Nombre, EsFinal)
    VALUES (@EstadoId, @Nombre, @EsFinal);

    SELECT @EstadoId AS EstadoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarEstadoPedido
    @EstadoId TINYINT,
    @Nombre NVARCHAR(30),
    @EsFinal BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.EstadoPedido
    SET Nombre = @Nombre,
        EsFinal = @EsFinal
    WHERE EstadoId = @EstadoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarEstadoPedido
    @EstadoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.EstadoPedido
    WHERE EstadoId = @EstadoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== ventas.DetallePedido =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDetallesPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Subtotal, Nota
    FROM ventas.DetallePedido
    ORDER BY PedidoId, Linea;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerDetallePedidoPorId
    @PedidoId INT,
    @Linea SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Subtotal, Nota
    FROM ventas.DetallePedido
    WHERE PedidoId = @PedidoId AND Linea = @Linea;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT,
    @ProductoId INT,
    @Cantidad SMALLINT,
    @PrecioUnitario DECIMAL(12,2),
    @Nota NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.DetallePedido (PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Nota)
    VALUES (@PedidoId, @Linea, @ProductoId, @Cantidad, @PrecioUnitario, @Nota);

    SELECT @PedidoId AS PedidoId, @Linea AS Linea;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT,
    @ProductoId INT,
    @Cantidad SMALLINT,
    @PrecioUnitario DECIMAL(12,2),
    @Nota NVARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.DetallePedido
    SET ProductoId = @ProductoId,
        Cantidad = @Cantidad,
        PrecioUnitario = @PrecioUnitario,
        Nota = @Nota
    WHERE PedidoId = @PedidoId AND Linea = @Linea;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarDetallePedido
    @PedidoId INT,
    @Linea SMALLINT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.DetallePedido
    WHERE PedidoId = @PedidoId AND Linea = @Linea;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

