/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures CRUD: ventas.HistorialEstadoPedido, seguridad.Usuario, ventas.Pago, ventas.Entrega
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   Cada SP se crea dentro del esquema de su tabla para que rol_api pueda ejecutarlo.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- ===== ventas.HistorialEstadoPedido =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerHistorialEstadoPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario
    FROM ventas.HistorialEstadoPedido
    ORDER BY HistorialId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerHistorialEstadoPedidoPorId
    @HistorialId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario
    FROM ventas.HistorialEstadoPedido
    WHERE HistorialId = @HistorialId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarHistorialEstadoPedido
    @PedidoId INT,
    @EstadoId TINYINT,
    @UsuarioId INT = NULL,
    @Comentario NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
    VALUES (@PedidoId, @EstadoId, @UsuarioId, @Comentario);

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerHistorialPorPedido
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario
    FROM ventas.HistorialEstadoPedido
    WHERE PedidoId = @PedidoId
    ORDER BY FechaCambio, HistorialId;
END
GO

-- ===== seguridad.Usuario =====
CREATE OR ALTER PROCEDURE seguridad.sp_ObtenerUsuarios
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, Correo, RolId, RestauranteId, SedeId, ClienteId, Activo, IntentosFallidos, UltimoAcceso, FechaCreacion
    FROM seguridad.Usuario
    ORDER BY UsuarioId;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_ObtenerUsuarioPorId
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UsuarioId, Correo, RolId, RestauranteId, SedeId, ClienteId, Activo, IntentosFallidos, UltimoAcceso, FechaCreacion
    FROM seguridad.Usuario
    WHERE UsuarioId = @UsuarioId;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_InsertarUsuario
    @Correo NVARCHAR(150),
    @Contrasena NVARCHAR(128),
    @RolId TINYINT,
    @RestauranteId INT = NULL,
    @SedeId INT = NULL,
    @ClienteId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- La contraseña se encripta dentro de seguridad.sp_RegistrarUsuario (archivo SP_Autenticacion.sql).
    EXEC seguridad.sp_RegistrarUsuario
        @Correo = @Correo,
        @Contrasena = @Contrasena,
        @RolId = @RolId,
        @RestauranteId = @RestauranteId,
        @SedeId = @SedeId,
        @ClienteId = @ClienteId;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_ActualizarUsuario
    @UsuarioId INT,
    @Correo NVARCHAR(150),
    @RolId TINYINT,
    @RestauranteId INT = NULL,
    @SedeId INT = NULL,
    @ClienteId INT = NULL,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    -- La contraseña no se cambia aquí: se usa seguridad.sp_CambiarContrasena.
    UPDATE seguridad.Usuario
    SET Correo = @Correo,
        RolId = @RolId,
        RestauranteId = @RestauranteId,
        SedeId = @SedeId,
        ClienteId = @ClienteId,
        Activo = @Activo
    WHERE UsuarioId = @UsuarioId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE seguridad.sp_EliminarUsuario
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Borrado lógico: el usuario queda inactivo y ya no puede iniciar sesión.
    UPDATE seguridad.Usuario
    SET Activo = 0
    WHERE UsuarioId = @UsuarioId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== ventas.Pago =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPagos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna, FechaPago
    FROM ventas.Pago
    ORDER BY PagoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPagoPorId
    @PagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna, FechaPago
    FROM ventas.Pago
    WHERE PagoId = @PagoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarPago
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(12,2),
    @Estado VARCHAR(15) = 'Pendiente',
    @ReferenciaExterna VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.Pago (PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna)
    VALUES (@PedidoId, @MetodoPagoId, @Monto, @Estado, @ReferenciaExterna);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarPago
    @PagoId INT,
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(12,2),
    @Estado VARCHAR(15),
    @ReferenciaExterna VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.Pago
    SET PedidoId = @PedidoId,
        MetodoPagoId = @MetodoPagoId,
        Monto = @Monto,
        Estado = @Estado,
        ReferenciaExterna = @ReferenciaExterna
    WHERE PagoId = @PagoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarPago
    @PagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.Pago
    WHERE PagoId = @PagoId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== ventas.Entrega =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEntregas
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EntregaId, PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega
    FROM ventas.Entrega
    ORDER BY EntregaId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerEntregaPorId
    @EntregaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EntregaId, PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega
    FROM ventas.Entrega
    WHERE EntregaId = @EntregaId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarEntrega
    @PedidoId INT,
    @ProveedorEntrega NVARCHAR(60),
    @CodigoSeguimiento VARCHAR(60) = NULL,
    @Estado VARCHAR(15) = 'Asignada',
    @FechaSalida DATETIME2(0) = NULL,
    @FechaEntrega DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ventas.Entrega (PedidoId, ProveedorEntrega, CodigoSeguimiento, Estado, FechaSalida, FechaEntrega)
    VALUES (@PedidoId, @ProveedorEntrega, @CodigoSeguimiento, @Estado, @FechaSalida, @FechaEntrega);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarEntrega
    @EntregaId INT,
    @PedidoId INT,
    @ProveedorEntrega NVARCHAR(60),
    @CodigoSeguimiento VARCHAR(60) = NULL,
    @Estado VARCHAR(15),
    @FechaSalida DATETIME2(0) = NULL,
    @FechaEntrega DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ventas.Entrega
    SET PedidoId = @PedidoId,
        ProveedorEntrega = @ProveedorEntrega,
        CodigoSeguimiento = @CodigoSeguimiento,
        Estado = @Estado,
        FechaSalida = @FechaSalida,
        FechaEntrega = @FechaEntrega
    WHERE EntregaId = @EntregaId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_EliminarEntrega
    @EntregaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM ventas.Entrega
    WHERE EntregaId = @EntregaId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

