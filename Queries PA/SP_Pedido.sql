/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla ventas.Pedido

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Errores de los SP de negocio: 51001-51007 (sp_CrearPedido), 52001-52012 (cambiar estado y cancelar).
   Un pedido no se borra en cascada: para anularlo se usa sp_CancelarPedido.
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

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

            -- No se borran en cascada el detalle, los pagos ni el historial: si el pedido
            -- ya los tiene, la llave foránea impide borrarlo. Para anular un pedido
            -- se usa ventas.sp_CancelarPedido, que deja todo registrado.
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

-- ===== Lógica de negocio =====

CREATE OR ALTER PROCEDURE ventas.sp_CrearPedido
    @ClienteId   INT,
    @SedeId      INT,
    @ModalidadId TINYINT,
    @DireccionId INT = NULL,
    @Lineas      NVARCHAR(MAX),
    @Notas       NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CostoEnvioExpress DECIMAL(12,2) = 1500;
    DECLARE @TasaIVA           DECIMAL(5,4)  = 0.13;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Cliente, sede y modalidad
        IF NOT EXISTS (SELECT 1 FROM ventas.Cliente WHERE ClienteId = @ClienteId)
            THROW 51001, N'El cliente no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM core.Sede WHERE SedeId = @SedeId AND Activa = 1)
            THROW 51002, N'La sede no existe o está inactiva.', 1;

        DECLARE @RequiereDireccion BIT;
        SELECT @RequiereDireccion = RequiereDireccion
        FROM ventas.Modalidad
        WHERE ModalidadId = @ModalidadId;

        IF @RequiereDireccion IS NULL
            THROW 51003, N'La modalidad no existe.', 1;

        -- 2. Reglas de express
        IF @RequiereDireccion = 1
        BEGIN
            IF @DireccionId IS NULL OR NOT EXISTS (
                SELECT 1 FROM ventas.DireccionCliente
                WHERE DireccionId = @DireccionId AND ClienteId = @ClienteId AND Activa = 1)
                THROW 51004, N'Un pedido express necesita una dirección válida del cliente.', 1;

            IF NOT EXISTS (SELECT 1 FROM core.Sede WHERE SedeId = @SedeId AND OfreceExpress = 1)
                THROW 51005, N'La sede no ofrece servicio express.', 1;
        END
        ELSE
            SET @DireccionId = NULL;

        -- 3. Leer las líneas del JSON
        DECLARE @L TABLE (
            ProductoId INT,
            Cantidad   SMALLINT,
            Nota       NVARCHAR(150),
            Precio     DECIMAL(12,2)
        );

        INSERT INTO @L (ProductoId, Cantidad, Nota)
        SELECT ProductoId, Cantidad, Nota
        FROM OPENJSON(@Lineas)
        WITH (
            ProductoId INT           '$.productoId',
            Cantidad   SMALLINT      '$.cantidad',
            Nota       NVARCHAR(150) '$.nota'
        );

        IF NOT EXISTS (SELECT 1 FROM @L)
            THROW 51006, N'El pedido no tiene productos.', 1;

        -- 4. Precio de cada línea según la sede
        UPDATE l
        SET Precio = ISNULL(ps.PrecioSede, p.PrecioBase)
        FROM @L l
        JOIN menu.ProductoSede ps ON ps.ProductoId = l.ProductoId
                                 AND ps.SedeId = @SedeId
                                 AND ps.Disponible = 1
        JOIN menu.Producto p      ON p.ProductoId = l.ProductoId
                                 AND p.Activo = 1;

        IF EXISTS (SELECT 1 FROM @L WHERE Precio IS NULL)
            THROW 51007, N'Algún producto no está disponible en esta sede.', 1;

        -- 5. Totales
        DECLARE @Subtotal   DECIMAL(12,2) = (SELECT SUM(Cantidad * Precio) FROM @L);
        DECLARE @Impuesto   DECIMAL(12,2) = ROUND(@Subtotal * @TasaIVA, 2);
        DECLARE @CostoEnvio DECIMAL(12,2) = CASE WHEN @RequiereDireccion = 1
                                                 THEN @CostoEnvioExpress ELSE 0 END;

        -- 6. Escrituras: pedido, detalle e historial
        DECLARE @PedidoId INT;

        INSERT INTO ventas.Pedido (ClienteId, SedeId, ModalidadId, EstadoId, DireccionId,
                                   Subtotal, Impuesto, CostoEnvio, Notas)
        VALUES (@ClienteId, @SedeId, @ModalidadId, 1, @DireccionId,
                @Subtotal, @Impuesto, @CostoEnvio, @Notas);

        SET @PedidoId = SCOPE_IDENTITY();

        INSERT INTO ventas.DetallePedido (PedidoId, Linea, ProductoId, Cantidad, PrecioUnitario, Nota)
        SELECT @PedidoId, ROW_NUMBER() OVER (ORDER BY ProductoId), ProductoId, Cantidad, Precio, Nota
        FROM @L;

        INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, Comentario)
        VALUES (@PedidoId, 1, N'Pedido creado');

        COMMIT TRANSACTION;

        SELECT PedidoId, Subtotal, Impuesto, CostoEnvio, Total
        FROM ventas.Pedido
        WHERE PedidoId = @PedidoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- --------------------------------------------------------------------------
-- Cambia el estado de un pedido, lo registra en el historial y, si es
-- express, actualiza la entrega. Todo en una sola transacción.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.sp_CambiarEstadoPedido
    @PedidoId      INT,
    @NuevoEstadoId TINYINT,
    @UsuarioId     INT = NULL,
    @Comentario    NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @EstadoActual TINYINT, @ModalidadId TINYINT;

            -- Se lee con UPDLOCK: si dos personas cambian el mismo pedido, la segunda espera.
            SELECT @EstadoActual = p.EstadoId,
                   @ModalidadId  = p.ModalidadId
            FROM ventas.Pedido AS p WITH (UPDLOCK)
            WHERE p.PedidoId = @PedidoId;

            IF @EstadoActual IS NULL
                THROW 52001, N'El pedido no existe.', 1;

            IF NOT EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @NuevoEstadoId)
                THROW 52002, N'El estado nuevo no existe.', 1;

            IF EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoActual AND EsFinal = 1)
                THROW 52003, N'El pedido ya está en un estado final.', 1;

            IF @NuevoEstadoId = 7
                THROW 52004, N'Para cancelar un pedido use ventas.sp_CancelarPedido.', 1;

            IF @NuevoEstadoId = 5 AND @ModalidadId <> 3
                THROW 52005, N'Solo los pedidos express pueden pasar a En camino.', 1;

            UPDATE ventas.Pedido
            SET EstadoId = @NuevoEstadoId
            WHERE PedidoId = @PedidoId;

            INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
            VALUES (@PedidoId, @NuevoEstadoId, @UsuarioId, @Comentario);

            IF @NuevoEstadoId = 5
                UPDATE ventas.Entrega
                SET Estado = 'EnCamino', FechaSalida = SYSDATETIME()
                WHERE PedidoId = @PedidoId;
            ELSE IF @NuevoEstadoId = 6
                UPDATE ventas.Entrega
                SET Estado = 'Entregada', FechaEntrega = SYSDATETIME()
                WHERE PedidoId = @PedidoId;

        COMMIT TRANSACTION;

        SELECT p.PedidoId, p.EstadoId, e.Nombre AS Estado
        FROM ventas.Pedido p
        JOIN ventas.EstadoPedido e ON e.EstadoId = p.EstadoId
        WHERE p.PedidoId = @PedidoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- --------------------------------------------------------------------------
-- Cancela un pedido, reembolsa el pago aprobado y marca la entrega como
-- fallida si no se completó.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.sp_CancelarPedido
    @PedidoId  INT,
    @Motivo    NVARCHAR(200),
    @UsuarioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @EstadoActual TINYINT, @Reembolsados INT;

            SELECT @EstadoActual = p.EstadoId
            FROM ventas.Pedido AS p WITH (UPDLOCK)
            WHERE p.PedidoId = @PedidoId;

            IF @EstadoActual IS NULL
                THROW 52011, N'El pedido no existe.', 1;

            IF EXISTS (SELECT 1 FROM ventas.EstadoPedido WHERE EstadoId = @EstadoActual AND EsFinal = 1)
                THROW 52012, N'El pedido ya está entregado o cancelado.', 1;

            UPDATE ventas.Pedido
            SET EstadoId = 7
            WHERE PedidoId = @PedidoId;

            INSERT INTO ventas.HistorialEstadoPedido (PedidoId, EstadoId, UsuarioId, Comentario)
            VALUES (@PedidoId, 7, @UsuarioId, @Motivo);

            UPDATE ventas.Pago
            SET Estado = 'Reembolsado'
            WHERE PedidoId = @PedidoId AND Estado = 'Aprobado';
            SET @Reembolsados = @@ROWCOUNT;

            UPDATE ventas.Entrega
            SET Estado = 'Fallida'
            WHERE PedidoId = @PedidoId AND Estado IN ('Asignada', 'EnCamino');

        COMMIT TRANSACTION;

        SELECT @PedidoId AS PedidoId,
               CAST(7 AS TINYINT) AS EstadoId,
               N'Cancelado' AS Estado,
               @Reembolsados AS PagosReembolsados;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
