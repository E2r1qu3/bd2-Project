USE PedidosRestaurantes;
GO
 
-- --------------------------------------------------------------------------
-- Ventas por sede de un restaurante en un rango de fechas: cantidad de
-- pedidos y total, con una fila por sede (también las que no vendieron).
-- --------------------------------------------------------------------------
CREATE OR ALTER FUNCTION ventas.fn_VentasPorSede (@RestauranteId INT, @Desde DATE, @Hasta DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT s.SedeId,
           s.Nombre AS Sede,
           COUNT(p.PedidoId) AS Pedidos,
           ISNULL(SUM(p.Total), 0) AS TotalVentas
    FROM core.Sede s
    LEFT JOIN ventas.Pedido p
           ON p.SedeId = s.SedeId
          AND p.EstadoId <> 7
          AND p.FechaPedido >= @Desde
          AND p.FechaPedido <  DATEADD(DAY, 1, @Hasta)
    WHERE s.RestauranteId = @RestauranteId
    GROUP BY s.SedeId, s.Nombre
);
GO
 