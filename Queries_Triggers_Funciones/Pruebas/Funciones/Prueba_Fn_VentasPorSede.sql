/* Pruebas R4 - José. Requiere Bd/PedidosRest.sql, Bd/Datos_Prueba.sql y el archivo del mismo nombre en Queries PA/.
   Ninguna prueba deja datos cambiados. Si ves además el error 3609 en las pruebas de triggers, es normal. */
USE PedidosRestaurantes;
GO

-- Prueba 8: ventas por sede de un restaurante
DECLARE @R INT = (SELECT TOP 1 RestauranteId FROM core.Restaurante ORDER BY RestauranteId);
SELECT * FROM ventas.fn_VentasPorSede(@R, '2000-01-01', '2100-01-01');
GO
