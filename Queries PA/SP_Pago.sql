/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.Pago

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Errores de los SP de negocio: 53001-53005 (sp_RegistrarPago).
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

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

-- ===== Lógica de negocio =====

CREATE OR ALTER PROCEDURE ventas.sp_RegistrarPago
    @PedidoId INT,
    @MetodoPagoId TINYINT,
    @Monto DECIMAL(12,2),
    @ReferenciaExterna VARCHAR(100) = NULL,
    @UsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual TINYINT;
    DECLARE @TotalPedido DECIMAL(12,2);
    DECLARE @PagoId INT;

    BEGIN TRY
        BEGIN TRANSACTION;

    
        SELECT
            @EstadoActual = EstadoId,
            @TotalPedido = Total
        FROM ventas.Pedido WITH (UPDLOCK, HOLDLOCK)
        WHERE PedidoId = @PedidoId;

        IF @EstadoActual IS NULL
            THROW 53001, N'El pedido no existe.', 1;


        IF @EstadoActual = 7
            THROW 53002, N'El pedido está cancelado.', 1;


        IF @Monto IS NULL OR @Monto <> @TotalPedido
            THROW 53003, N'El monto no coincide con el total del pedido.', 1;

        
        IF EXISTS (
            SELECT 1
            FROM ventas.Pago
            WHERE PedidoId = @PedidoId
              AND Estado = 'Aprobado'
        )
            THROW 53004, N'El pedido ya tiene un pago aprobado.', 1;

      
        IF NOT EXISTS (
            SELECT 1
            FROM ventas.MetodoPago
            WHERE MetodoPagoId = @MetodoPagoId
        )
            THROW 53005, N'El método de pago no existe.', 1;

        --  registra el pago
        INSERT INTO ventas.Pago (
            PedidoId,
            MetodoPagoId,
            Monto,
            Estado,
            ReferenciaExterna
        )
        VALUES (
            @PedidoId,
            @MetodoPagoId,
            @Monto,
            'Aprobado',
            @ReferenciaExterna
        );

        SET @PagoId = CONVERT(INT, SCOPE_IDENTITY());

        
        IF @EstadoActual = 1
        BEGIN
            UPDATE ventas.Pedido
            SET EstadoId = 2
            WHERE PedidoId = @PedidoId;

            INSERT INTO ventas.HistorialEstadoPedido (
                PedidoId,
                EstadoId,
                UsuarioId,
                Comentario
            )
            VALUES (
                @PedidoId,
                2,
                @UsuarioId,
                N'Pedido confirmado por pago aprobado.'
            );
        END;

        -- 8. Confirmar todos los cambios
        COMMIT TRANSACTION;

        SELECT @PagoId AS PagoId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
