/* CRUD con transacciones. Cada INSERT/UPDATE/DELETE va en BEGIN TRY + BEGIN TRANSACTION;
   si algo falla, el CATCH hace ROLLBACK y relanza el error con THROW.
   Errores propios: 54001 (el registro no existe), 54002 (ya existe el identificador).
   Antes de ejecutar, compara los nombres con los SP que ya existen en Queries PA/:
   CREATE OR ALTER reemplazaría uno con el mismo nombre. */
USE PedidosRestaurantes;
GO

-- ===== Pago =====
CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPagos
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna, FechaPago FROM ventas.Pago;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ObtenerPagoPorId
    @PagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PagoId, PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna, FechaPago FROM ventas.Pago WHERE PagoId = @PagoId;
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_InsertarPago
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(12,2),
    @Estado VARCHAR(15) = 'Pendiente',
    @ReferenciaExterna VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO ventas.Pago (PedidoId, MetodoPagoId, Monto, Estado, ReferenciaExterna)
            VALUES (@PedidoId, @MetodoPagoId, @Monto, @Estado, @ReferenciaExterna);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS PagoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ventas.sp_ActualizarPago
    @PagoId INT,
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(12,2),
    @Estado VARCHAR(15),
    @ReferenciaExterna VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Pago WHERE PagoId = @PagoId)
                THROW 54001, N'Pago: el registro no existe.', 1;

            UPDATE ventas.Pago
            SET PedidoId = @PedidoId,
                MetodoPagoId = @MetodoPagoId,
                Monto = @Monto,
                Estado = @Estado,
                ReferenciaExterna = @ReferenciaExterna
            WHERE PagoId = @PagoId;
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

CREATE OR ALTER PROCEDURE ventas.sp_EliminarPago
    @PagoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM ventas.Pago WHERE PagoId = @PagoId)
                THROW 54001, N'Pago: el registro no existe.', 1;

            DELETE FROM ventas.Pago WHERE PagoId = @PagoId;
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
