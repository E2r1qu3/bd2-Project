USE PedidosRestaurantes;
GO
 
-- --------------------------------------------------------------------------
-- El historial de estados es una bitácora: se inserta y se consulta, pero
-- nunca se modifica ni se borra. INSTEAD OF evita que el cambio llegue a la tabla.
-- --------------------------------------------------------------------------
CREATE OR ALTER TRIGGER ventas.trg_HistorialEstadoPedido_SoloLectura
ON ventas.HistorialEstadoPedido
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
 
    -- "deleted" trae las filas afectadas; si el UPDATE/DELETE no tocó filas, no se bloquea nada.
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 55001, N'El historial de estados es solo de lectura: no se puede modificar ni eliminar.', 1;
END
GO