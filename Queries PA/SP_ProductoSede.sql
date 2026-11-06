/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla menu.ProductoSede

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductosSede
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede FROM menu.ProductoSede;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ObtenerProductoSedePorId
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SedeId, ProductoId, Disponible, PrecioSede FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
END
GO

CREATE OR ALTER PROCEDURE menu.sp_InsertarProductoSede
    @SedeId INT,
    @ProductoId INT,
    @Disponible BIT = 1,
    @PrecioSede DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF EXISTS (SELECT 1 FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId)
                THROW 54002, N'ProductoSede: ya existe un registro con ese identificador.', 1;

            INSERT INTO menu.ProductoSede (SedeId, ProductoId, Disponible, PrecioSede)
            VALUES (@SedeId, @ProductoId, @Disponible, @PrecioSede);

        COMMIT TRANSACTION;

        SELECT @SedeId AS SedeId, @ProductoId AS ProductoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE menu.sp_ActualizarProductoSede
    @SedeId INT,
    @ProductoId INT,
    @Disponible BIT,
    @PrecioSede DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId)
                THROW 54001, N'ProductoSede: el registro no existe.', 1;

            UPDATE menu.ProductoSede
            SET Disponible = @Disponible,
                PrecioSede = @PrecioSede
            WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
            DECLARE @Filas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @Filas AS FilasAfectadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE menu.sp_EliminarProductoSede
    @SedeId INT,
    @ProductoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId)
                THROW 54001, N'ProductoSede: el registro no existe.', 1;

            DELETE FROM menu.ProductoSede WHERE SedeId = @SedeId AND ProductoId = @ProductoId;
            DECLARE @Filas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @Filas AS FilasAfectadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- ===== Lógica de negocio =====

-- --------------------------------------------------------------------------
-- Menú disponible en una sede, con el precio final (precio de sede o base).
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE menu.sp_ObtenerMenuPorSede
    @SedeId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.CategoriaId,
           c.Nombre AS Categoria,
           p.ProductoId,
           p.Nombre AS Producto,
           p.Descripcion,
           ISNULL(ps.PrecioSede, p.PrecioBase) AS Precio,
           p.ImagenUrl
    FROM menu.ProductoSede ps
    JOIN menu.Producto  p ON p.ProductoId  = ps.ProductoId
    JOIN menu.Categoria c ON c.CategoriaId = p.CategoriaId
    WHERE ps.SedeId = @SedeId
      AND ps.Disponible = 1
      AND p.Activo = 1
    ORDER BY c.Orden, p.Nombre;
END
GO
