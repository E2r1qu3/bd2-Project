-- Ejecutar con la BD del proyecto seleccionada. Ajusta las longitudes de tipos a tus tablas.
SET NOCOUNT ON;
GO

-- ===== HistorialEstadoPedido =====
IF OBJECT_ID('sp_ObtenerHistorialEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_ObtenerHistorialEstadoPedido;
GO
CREATE PROCEDURE sp_ObtenerHistorialEstadoPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio FROM HistorialEstadoPedido;
END
GO

IF OBJECT_ID('sp_ObtenerHistorialEstadoPedidoPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerHistorialEstadoPedidoPorId;
GO
CREATE PROCEDURE sp_ObtenerHistorialEstadoPedidoPorId
    @HistorialId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio FROM HistorialEstadoPedido WHERE HistorialId = @HistorialId;
END
GO

IF OBJECT_ID('sp_InsertarHistorialEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_InsertarHistorialEstadoPedido;
GO
CREATE PROCEDURE sp_InsertarHistorialEstadoPedido
    @PedidoId INT,
    @EstadoId TINYINT,
    @FechaCambio DATETIME2,
    @UsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, FechaCambio) VALUES (@PedidoId, @EstadoId, @UsuarioId, @FechaCambio);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarHistorialEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_ActualizarHistorialEstadoPedido;
GO
CREATE PROCEDURE sp_ActualizarHistorialEstadoPedido
    @HistorialId BIGINT,
    @PedidoId INT,
    @EstadoId TINYINT,
    @FechaCambio DATETIME2,
    @UsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE HistorialEstadoPedido
    SET PedidoId = @PedidoId,
        EstadoId = @EstadoId,
        UsuarioId = @UsuarioId,
        FechaCambio = @FechaCambio
    WHERE HistorialId = @HistorialId;
END
GO

IF OBJECT_ID('sp_EliminarHistorialEstadoPedido','P') IS NOT NULL DROP PROCEDURE sp_EliminarHistorialEstadoPedido;
GO
CREATE PROCEDURE sp_EliminarHistorialEstadoPedido
    @HistorialId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM HistorialEstadoPedido WHERE HistorialId = @HistorialId;
END
GO

-- ===== Usuario =====
IF OBJECT_ID('sp_ObtenerUsuarios','P') IS NOT NULL DROP PROCEDURE sp_ObtenerUsuarios;
GO
CREATE PROCEDURE sp_ObtenerUsuarios
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, Correo, ContrasenaHash, RolId, RestauranteId, SedeId, ClienteId FROM Usuario;
END
GO

IF OBJECT_ID('sp_ObtenerUsuarioPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerUsuarioPorId;
GO
CREATE PROCEDURE sp_ObtenerUsuarioPorId
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, Correo, ContrasenaHash, RolId, RestauranteId, SedeId, ClienteId FROM Usuario WHERE UsuarioId = @UsuarioId;
END
GO

IF OBJECT_ID('sp_InsertarUsuario','P') IS NOT NULL DROP PROCEDURE sp_InsertarUsuario;
GO
CREATE PROCEDURE sp_InsertarUsuario
    @Correo NVARCHAR(150),
    @ContrasenaHash VARBINARY(256),
    @RolId TINYINT,
    @RestauranteId INT = NULL,
    @SedeId INT = NULL,
    @ClienteId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Usuario (Correo, ContrasenaHash, RolId, RestauranteId, SedeId, ClienteId) VALUES (@Correo, @ContrasenaHash, @RolId, @RestauranteId, @SedeId, @ClienteId);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarUsuario','P') IS NOT NULL DROP PROCEDURE sp_ActualizarUsuario;
GO
CREATE PROCEDURE sp_ActualizarUsuario
    @UsuarioId INT,
    @Correo NVARCHAR(150),
    @ContrasenaHash VARBINARY(256),
    @RolId TINYINT,
    @RestauranteId INT = NULL,
    @SedeId INT = NULL,
    @ClienteId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Usuario
    SET Correo = @Correo,
        ContrasenaHash = @ContrasenaHash,
        RolId = @RolId,
        RestauranteId = @RestauranteId,
        SedeId = @SedeId,
        ClienteId = @ClienteId
    WHERE UsuarioId = @UsuarioId;
END
GO

IF OBJECT_ID('sp_EliminarUsuario','P') IS NOT NULL DROP PROCEDURE sp_EliminarUsuario;
GO
CREATE PROCEDURE sp_EliminarUsuario
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Usuario WHERE UsuarioId = @UsuarioId;
END
GO

-- ===== Pago =====
IF OBJECT_ID('sp_ObtenerPagos','P') IS NOT NULL DROP PROCEDURE sp_ObtenerPagos;
GO
CREATE PROCEDURE sp_ObtenerPagos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado FROM Pago;
END
GO

IF OBJECT_ID('sp_ObtenerPagoPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerPagoPorId;
GO
CREATE PROCEDURE sp_ObtenerPagoPorId
    @PagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado FROM Pago WHERE PagoId = @PagoId;
END
GO

IF OBJECT_ID('sp_InsertarPago','P') IS NOT NULL DROP PROCEDURE sp_InsertarPago;
GO
CREATE PROCEDURE sp_InsertarPago
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(10,2),
    @Estado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Pago (PedidoId, MetodoPagoId, Monto, Estado) VALUES (@PedidoId, @MetodoPagoId, @Monto, @Estado);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarPago','P') IS NOT NULL DROP PROCEDURE sp_ActualizarPago;
GO
CREATE PROCEDURE sp_ActualizarPago
    @PagoId INT,
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(10,2),
    @Estado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Pago
    SET PedidoId = @PedidoId,
        MetodoPagoId = @MetodoPagoId,
        Monto = @Monto,
        Estado = @Estado
    WHERE PagoId = @PagoId;
END
GO

IF OBJECT_ID('sp_EliminarPago','P') IS NOT NULL DROP PROCEDURE sp_EliminarPago;
GO
CREATE PROCEDURE sp_EliminarPago
    @PagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Pago WHERE PagoId = @PagoId;
END
GO

-- ===== Entrega =====
IF OBJECT_ID('sp_ObtenerEntregas','P') IS NOT NULL DROP PROCEDURE sp_ObtenerEntregas;
GO
CREATE PROCEDURE sp_ObtenerEntregas
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EntregaId, PedidoId, ProveedorEntrega, Estado FROM Entrega;
END
GO

IF OBJECT_ID('sp_ObtenerEntregaPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerEntregaPorId;
GO
CREATE PROCEDURE sp_ObtenerEntregaPorId
    @EntregaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EntregaId, PedidoId, ProveedorEntrega, Estado FROM Entrega WHERE EntregaId = @EntregaId;
END
GO

IF OBJECT_ID('sp_InsertarEntrega','P') IS NOT NULL DROP PROCEDURE sp_InsertarEntrega;
GO
CREATE PROCEDURE sp_InsertarEntrega
    @PedidoId INT,
    @Estado VARCHAR(20),
    @ProveedorEntrega NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Entrega (PedidoId, ProveedorEntrega, Estado) VALUES (@PedidoId, @ProveedorEntrega, @Estado);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarEntrega','P') IS NOT NULL DROP PROCEDURE sp_ActualizarEntrega;
GO
CREATE PROCEDURE sp_ActualizarEntrega
    @EntregaId INT,
    @PedidoId INT,
    @Estado VARCHAR(20),
    @ProveedorEntrega NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Entrega
    SET PedidoId = @PedidoId,
        ProveedorEntrega = @ProveedorEntrega,
        Estado = @Estado
    WHERE EntregaId = @EntregaId;
END
GO

IF OBJECT_ID('sp_EliminarEntrega','P') IS NOT NULL DROP PROCEDURE sp_EliminarEntrega;
GO
CREATE PROCEDURE sp_EliminarEntrega
    @EntregaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Entrega WHERE EntregaId = @EntregaId;
END
GO
