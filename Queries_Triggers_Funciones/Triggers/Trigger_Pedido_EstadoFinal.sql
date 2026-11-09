USE PedidosRestaurantes;
GO

-- --------------------------------------------------------------------------
-- Un pedido Entregado o Cancelado (EsFinal = 1) ya no cambia de estado.
-- Otros campos del pedido (por ejemplo las notas) sí se pueden actualizar.
-- --------------------------------------------------------------------------
CREATE OR ALTER TRIGGER ventas.trg_Pedido_EstadoFinal
ON ventas.Pedido
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(EstadoId)
       AND EXISTS (SELECT 1
                   FROM deleted d
                   JOIN inserted i ON i.PedidoId = d.PedidoId
                   JOIN ventas.EstadoPedido e ON e.EstadoId = d.EstadoId
                   WHERE e.EsFinal = 1
                     AND i.EstadoId <> d.EstadoId)
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW 55002, N'Un pedido en estado final (Entregado o Cancelado) no puede cambiar de estado.', 1;
    END
END
GO