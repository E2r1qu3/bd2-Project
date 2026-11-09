USE PedidosRestaurantes;
GO

-- --------------------------------------------------------------------------
-- Precio final de un producto en una sede: el precio de la sede si existe,
-- si no el precio base. Devuelve NULL si el producto no se ofrece en esa sede.
-- --------------------------------------------------------------------------
CREATE OR ALTER FUNCTION menu.fn_PrecioProductoSede (@SedeId INT, @ProductoId INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Precio DECIMAL(12,2);

    SELECT @Precio = ISNULL(ps.PrecioSede, p.PrecioBase)
    FROM menu.ProductoSede ps
    JOIN menu.Producto p ON p.ProductoId = ps.ProductoId
    WHERE ps.SedeId = @SedeId
      AND ps.ProductoId = @ProductoId;

    RETURN @Precio;
END
GO