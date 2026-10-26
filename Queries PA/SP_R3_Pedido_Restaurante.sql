USE PedidosRestaurantes;
GO

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

CREATE OR ALTER PROCEDURE core.sp_RegistrarRestaurante
    @Nombre          NVARCHAR(100),
    @CedulaJuridica  VARCHAR(20),
    @Correo          NVARCHAR(150),
    @Telefono        VARCHAR(20) = NULL,
    @PlanId          INT,
    @CorreoAdmin     NVARCHAR(150),
    @ContrasenaAdmin NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validaciones
        IF EXISTS (SELECT 1 FROM core.Restaurante WHERE CedulaJuridica = @CedulaJuridica)
            THROW 51011, N'Ya existe un restaurante con esa cédula jurídica.', 1;

        IF NOT EXISTS (SELECT 1 FROM core.PlanSuscripcion WHERE PlanId = @PlanId AND Activo = 1)
            THROW 51012, N'El plan no existe o no está activo.', 1;

        -- 2. Restaurante
        DECLARE @RestauranteId INT;

        INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Telefono)
        VALUES (@Nombre, @CedulaJuridica, @Correo, @Telefono);

        SET @RestauranteId = SCOPE_IDENTITY();

        -- 3. Suscripción
        INSERT INTO core.Suscripcion (RestauranteId, PlanId, FechaInicio, Estado)
        VALUES (@RestauranteId, @PlanId, CAST(GETDATE() AS DATE), 'Activa');

        -- 4. Usuario administrador (reutiliza el SP de R2)
        DECLARE @U TABLE (UsuarioId INT);

        INSERT INTO @U (UsuarioId)
        EXEC seguridad.sp_RegistrarUsuario
            @Correo        = @CorreoAdmin,
            @Contrasena    = @ContrasenaAdmin,
            @RolId         = 2,
            @RestauranteId = @RestauranteId;

        COMMIT TRANSACTION;

        SELECT @RestauranteId AS RestauranteId,
               (SELECT UsuarioId FROM @U) AS UsuarioId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
