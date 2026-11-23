USE PedidosRestaurantes;
GO

-- INDICE 1: Buscar pagos por pedido
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pago_PedidoId'
    AND object_id = OBJECT_ID('ventas.Pago')
)
    CREATE NONCLUSTERED INDEX IX_Pago_PedidoId
    ON ventas.Pago(PedidoId);
GO

-- INDICE 2: Buscar historial por pedido
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_HistorialEstadoPedido_PedidoId'
    AND object_id = OBJECT_ID('ventas.HistorialEstadoPedido')
)
    CREATE NONCLUSTERED INDEX IX_HistorialEstadoPedido_PedidoId
    ON ventas.HistorialEstadoPedido(PedidoId);
GO

-- INDICE 3: Buscar pedidos por cliente
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pedido_ClienteId'
    AND object_id = OBJECT_ID('ventas.Pedido')
)
    CREATE NONCLUSTERED INDEX IX_Pedido_ClienteId
    ON ventas.Pedido(ClienteId);
GO