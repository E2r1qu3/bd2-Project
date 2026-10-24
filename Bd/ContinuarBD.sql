USE PedidosRestaurantes;
GO



SET QUOTED_IDENTIFIER ON;
GO



CREATE TABLE ventas.Pedido (
    PedidoId INT IDENTITY(1,1) PRIMARY KEY,
    ClienteId INT NOT NULL REFERENCES ventas.Cliente(ClienteId),
    SedeId INT NOT NULL REFERENCES core.Sede(SedeId),
    ModalidadId TINYINT NOT NULL REFERENCES ventas.Modalidad(ModalidadId),
    EstadoId TINYINT NOT NULL DEFAULT (1) REFERENCES ventas.EstadoPedido(EstadoId),
    DireccionId INT NULL REFERENCES ventas.DireccionCliente(DireccionId),
    FechaPedido DATETIME2(0) NOT NULL DEFAULT (SYSDATETIME()),
    Subtotal DECIMAL(12,2) NOT NULL DEFAULT (0),
    Impuesto DECIMAL(12,2) NOT NULL DEFAULT (0),
    CostoEnvio DECIMAL(12,2) NOT NULL DEFAULT (0),
    Total AS (Subtotal + Impuesto + CostoEnvio) PERSISTED,
    Notas NVARCHAR(300) NULL,
    CONSTRAINT CK_Pedido_Montos CHECK (Subtotal >= 0 AND Impuesto >= 0 AND CostoEnvio >= 0)
);
GO

CREATE TABLE ventas.DetallePedido (
    PedidoId INT NOT NULL REFERENCES ventas.Pedido(PedidoId),
    Linea SMALLINT NOT NULL,
    ProductoId INT NOT NULL REFERENCES menu.Producto(ProductoId),
    Cantidad SMALLINT NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(12,2) NOT NULL CHECK (PrecioUnitario > 0),
    Subtotal AS (Cantidad * PrecioUnitario) PERSISTED,
    Nota NVARCHAR(150) NULL,
    CONSTRAINT PK_DetallePedido PRIMARY KEY (PedidoId, Linea)
);
GO

CREATE TABLE ventas.HistorialEstadoPedido (
    HistorialId BIGINT IDENTITY(1,1) PRIMARY KEY,
    PedidoId INT NOT NULL REFERENCES ventas.Pedido(PedidoId),
    EstadoId TINYINT NOT NULL REFERENCES ventas.EstadoPedido(EstadoId),
    UsuarioId INT NULL REFERENCES seguridad.Usuario(UsuarioId),
    FechaCambio DATETIME2(0) NOT NULL DEFAULT (SYSDATETIME()),
    Comentario NVARCHAR(200) NULL
);
GO

CREATE TABLE ventas.Pago (
    PagoId INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId INT NOT NULL REFERENCES ventas.Pedido(PedidoId),
    MetodoPagoId TINYINT NOT NULL REFERENCES ventas.MetodoPago(MetodoPagoId),
    Monto DECIMAL(12,2) NOT NULL CHECK (Monto > 0),
    Estado VARCHAR(15) NOT NULL DEFAULT ('Pendiente'),
    ReferenciaExterna VARCHAR(100) NULL,
    FechaPago DATETIME2(0) NOT NULL DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Pago_Estado CHECK (Estado IN ('Pendiente','Aprobado','Rechazado','Reembolsado'))
);
GO

CREATE TABLE ventas.Entrega (
    EntregaId INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId INT NOT NULL UNIQUE REFERENCES ventas.Pedido(PedidoId),
    ProveedorEntrega NVARCHAR(60) NOT NULL,
    CodigoSeguimiento VARCHAR(60) NULL,
    Estado VARCHAR(15) NOT NULL DEFAULT ('Asignada'),
    FechaSalida DATETIME2(0) NULL,
    FechaEntrega DATETIME2(0) NULL,
    CONSTRAINT CK_Entrega_Estado CHECK (Estado IN ('Asignada','EnCamino','Entregada','Fallida')),
    CONSTRAINT CK_Entrega_Fechas CHECK (FechaEntrega IS NULL OR FechaSalida IS NULL OR FechaEntrega >= FechaSalida)
);
GO