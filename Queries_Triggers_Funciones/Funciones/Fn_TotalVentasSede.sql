USE PedidosRestaurantes;
GO
 
-- --------------------------------------------------------------------------
-- Total de ventas de una sede en un rango de fechas (ambas incluidas).
-- Cuenta los pedidos que no están cancelados (EstadoId <> 7). Sin ventas: 0.
-- --------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ventas.fn_TotalVentasSede (@SedeId INT, @Desde DATE, @Hasta DATE)
RETURNS DECIMAL(14,2)
AS
BEGIN
    DECLARE @Total DECIMAL(14,2);
 
    SELECT @Total = ISNULL(SUM(p.Total), 0)
    FROM ventas.Pedido p
    WHERE p.SedeId = @SedeId
      AND p.EstadoId <> 7
      AND p.FechaPedido >= @Desde
      AND p.FechaPedido <  DATEADD(DAY, 1, @Hasta);
 
    RETURN @Total;
END
GO
