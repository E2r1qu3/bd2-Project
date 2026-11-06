/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de la tabla core.Restaurante

   CRUD: cada INSERT/UPDATE/DELETE va en una transacción (BEGIN TRY +
   BEGIN TRANSACTION); si algo falla, el CATCH hace ROLLBACK y relanza el error.
   Errores del CRUD: 54001 (el registro no existe), 54002 (el identificador ya existe).
   Errores de los SP de negocio: 51011-51012 (sp_RegistrarRestaurante).
   Eliminar hace borrado lógico (Activo = 0).
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   ========================================================================== */
USE PedidosRestaurantes;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ===== CRUD =====

CREATE OR ALTER PROCEDURE core.sp_ObtenerRestaurantes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Telefono, Activo, FechaRegistro FROM core.Restaurante;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerRestaurantePorId
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Telefono, Activo, FechaRegistro FROM core.Restaurante WHERE RestauranteId = @RestauranteId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarRestaurante
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Telefono, Activo)
            VALUES (@Nombre, @CedulaJuridica, @Correo, @Telefono, @Activo);
            DECLARE @NuevoId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @NuevoId AS RestauranteId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarRestaurante
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Activo BIT,
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Restaurante WHERE RestauranteId = @RestauranteId)
                THROW 54001, N'Restaurante: el registro no existe.', 1;

            UPDATE core.Restaurante
            SET Nombre = @Nombre,
                CedulaJuridica = @CedulaJuridica,
                Correo = @Correo,
                Telefono = @Telefono,
                Activo = @Activo
            WHERE RestauranteId = @RestauranteId;
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

CREATE OR ALTER PROCEDURE core.sp_EliminarRestaurante
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF NOT EXISTS (SELECT 1 FROM core.Restaurante WHERE RestauranteId = @RestauranteId)
                THROW 54001, N'Restaurante: el registro no existe.', 1;

            -- Borrado lógico: el registro queda inactivo y se conserva su historial.
            UPDATE core.Restaurante SET Activo = 0 WHERE RestauranteId = @RestauranteId;
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
