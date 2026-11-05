/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.HistorialEstadoPedido

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Es una bitácora: solo se consulta e inserta, nunca se modifica ni se borra.
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerHistorialEstadoPedido
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario FROM ventas.HistorialEstadoPedido;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerHistorialEstadoPedidoPorId
    @HistorialId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario FROM ventas.HistorialEstadoPedido WHERE HistorialId = @HistorialId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarHistorialEstadoPedido
    @PedidoId INT,
    @EstadoId TINYINT,
    @UsuarioId INT = NULL,
    @Comentario NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
            VALUES (@PedidoId, @EstadoId, @UsuarioId, @Comentario);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS HistorialId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerHistorialPorPedido
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT HistorialId, PedidoId, EstadoId, UsuarioId, FechaCambio, Comentario
    FROM ventas.HistorialEstadoPedido
    WHERE PedidoId = @PedidoId
    ORDER BY FechaCambio, HistorialId;
END
GO
