USE PedidosRestaurantes;
GO

SET SHOWPLAN_XML ON;
GO

-- CONSULTA 1: Pagos por pedido
SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado, FechaPago
FROM ventas.Pago
WHERE PedidoId = 1;
GO

-- CONSULTA 2: Historial de estados por pedido
SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario
FROM ventas.HistorialEstadoPedido
WHERE PedidoId = 1;
GO

-- CONSULTA 3: Pedidos de un cliente existente
SELECT PedidoId, ClienteId, SedeId, EstadoId, FechaPedido, Total
FROM ventas.Pedido
WHERE ClienteId = (SELECT MIN(ClienteId) FROM ventas.Pedido);
GO

SET SHOWPLAN_XML OFF;
GO