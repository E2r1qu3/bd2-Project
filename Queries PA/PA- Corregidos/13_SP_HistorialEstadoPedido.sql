/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== HistorialEstadoPedido =====
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
