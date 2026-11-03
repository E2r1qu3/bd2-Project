/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Pedido =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPedidos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total, Notas FROM ventas.Pedido;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPedidoPorId
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoId, ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, FechaPedido, Subtotal, Impuesto, CostoEnvio, Total, Notas FROM ventas.Pedido WHERE PedidoId = @PedidoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarPedido
    @ClienteId INT,
    @SedeId INT,
    @ModalidadId TINYINT,
    @EstadoId TINYINT = 1,
    @DireccionId INT = NULL,
    @Subtotal DECIMAL(12,2) = 0,
    @Impuesto DECIMAL(12,2) = 0,
    @CostoEnvio DECIMAL(12,2) = 0,
    @Notas NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, DireccionId, Subtotal, Impuesto, CostoEnvio, Notas)
            VALUES (@ClienteId, @SedeId, @ModalidadId, @EstadoId, @DireccionId, @Subtotal, @Impuesto, @CostoEnvio, @Notas);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS PedidoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarPedido
    @PedidoId INT,
    @ClienteId INT,
    @SedeId INT,
    @ModalidadId TINYINT,
    @Subtotal DECIMAL(12,2),
    @Impuesto DECIMAL(12,2),
    @CostoEnvio DECIMAL(12,2),
    @DireccionId INT = NULL,
    @Notas NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Pedido WHERE PedidoId = @PedidoId)
                THROW 54001, N'Pedido: el registro no existe.', 1;

            UPDATE ventas.Pedido
            SET ClienteId = @ClienteId,
                SedeId = @SedeId,
                ModalidadId = @ModalidadId,
                DireccionId = @DireccionId,
                Subtotal = @Subtotal,
                Impuesto = @Impuesto,
                CostoEnvio = @CostoEnvio,
                Notas = @Notas
            WHERE PedidoId = @PedidoId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarPedido
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Pedido WHERE PedidoId = @PedidoId)
                THROW 54001, N'Pedido: el registro no existe.', 1;

            DELETE FROM ventas.Entrega WHERE PedidoId = @PedidoId;
            DELETE FROM ventas.Pago WHERE PedidoId = @PedidoId;
            DELETE FROM ventas.HistorialEstadoPedido WHERE PedidoId = @PedidoId;
            DELETE FROM ventas.DetallePedido WHERE PedidoId = @PedidoId;
            DELETE FROM ventas.Pedido WHERE PedidoId = @PedidoId;
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
