/* Pruebas R4 - José. Requiere Bd/PedidosRest.sql, Bd/Datos_Prueba.sql y el archivo del mismo nombre en Queries PA/.
   Ninguna prueba deja datos cambiados. Si ves además el error 3609 en las pruebas de triggers, es normal. */
USE PedidosRestaurantes;
GO

-- Prueba 7: total de ventas por sede; debe coincidir con la consulta directa de abajo
SELECT s.SedeId, s.Nombre,
       ventas.fn_TotalVentasSede(s.SedeId, '2000-01-01', '2100-01-01') AS TotalFuncion
FROM core.Sede s
ORDER BY s.SedeId;

SELECT SedeId, SUM(Total) AS TotalDirecto
FROM ventas.Pedido
WHERE EstadoId <> 7
GROUP BY SedeId
ORDER BY SedeId;

SELECT ventas.fn_TotalVentasSede(1, '2000-01-01', '2000-01-31') AS RangoSinVentas;   -- 0
GO
