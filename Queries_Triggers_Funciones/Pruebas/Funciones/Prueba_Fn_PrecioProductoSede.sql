/* Pruebas R4 - José. Requiere Bd/PedidosRest.sql, Bd/Datos_Prueba.sql y el archivo del mismo nombre en Queries PA/.
   Ninguna prueba deja datos cambiados. Si ves además el error 3609 en las pruebas de triggers, es normal. */
USE PedidosRestaurantes;
GO

-- Prueba 6: precio por sede. En Heredia la BBQ cuesta 6 800 y la hamburguesa vegetariana sale NULL.
DECLARE @Heredia INT = (SELECT TOP 1 SedeId FROM core.Sede WHERE Provincia = N'Heredia' OR Nombre LIKE N'%Heredia%');
SELECT p.ProductoId,
       p.Nombre,
       p.PrecioBase,
       menu.fn_PrecioProductoSede(@Heredia, p.ProductoId) AS PrecioHeredia
FROM menu.Producto p
ORDER BY p.ProductoId;
SELECT menu.fn_PrecioProductoSede(@Heredia, 99999) AS ProductoInexistente;   -- NULL
GO
