-- Ejecutar con la BD del proyecto seleccionada. Ajusta las longitudes de tipos a tus tablas.
SET NOCOUNT ON;
GO

-- ===== PlanSuscripcion =====
IF OBJECT_ID('sp_ObtenerPlanesSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_ObtenerPlanesSuscripcion;
GO
CREATE PROCEDURE sp_ObtenerPlanesSuscripcion
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, Nombre, MaxSedes, PrecioMensual FROM core.PlanSuscripcion;
END
GO

IF OBJECT_ID('sp_ObtenerPlanSuscripcionPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerPlanSuscripcionPorId;
GO
CREATE PROCEDURE sp_ObtenerPlanSuscripcionPorId
    @PlanId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, Nombre, MaxSedes, PrecioMensual FROM core.PlanSuscripcion WHERE PlanId = @PlanId;
END
GO

IF OBJECT_ID('sp_InsertarPlanSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_InsertarPlanSuscripcion;
GO
CREATE PROCEDURE sp_InsertarPlanSuscripcion
    @Nombre NVARCHAR(100),
    @MaxSedes INT,
    @PrecioMensual DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.PlanSuscripcion (Nombre, MaxSedes, PrecioMensual) VALUES (@Nombre, @MaxSedes, @PrecioMensual);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarPlanSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_ActualizarPlanSuscripcion;
GO
CREATE PROCEDURE sp_ActualizarPlanSuscripcion
    @PlanId INT,
    @Nombre NVARCHAR(100),
    @MaxSedes INT,
    @PrecioMensual DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.PlanSuscripcion
    SET Nombre = @Nombre,
        MaxSedes = @MaxSedes,
        PrecioMensual = @PrecioMensual
    WHERE PlanId = @PlanId;
END
GO

IF OBJECT_ID('sp_EliminarPlanSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_EliminarPlanSuscripcion;
GO
CREATE PROCEDURE sp_EliminarPlanSuscripcion
    @PlanId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM core.PlanSuscripcion WHERE PlanId = @PlanId;
END
GO

-- ===== Restaurante =====
IF OBJECT_ID('sp_ObtenerRestaurantes','P') IS NOT NULL DROP PROCEDURE sp_ObtenerRestaurantes;
GO
CREATE PROCEDURE sp_ObtenerRestaurantes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Activo FROM core.Restaurante;
END
GO

IF OBJECT_ID('sp_ObtenerRestaurantePorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerRestaurantePorId;
GO
CREATE PROCEDURE sp_ObtenerRestaurantePorId
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Activo FROM core.Restaurante WHERE RestauranteId = @RestauranteId;
END
GO

IF OBJECT_ID('sp_InsertarRestaurante','P') IS NOT NULL DROP PROCEDURE sp_InsertarRestaurante;
GO
CREATE PROCEDURE sp_InsertarRestaurante
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Activo) VALUES (@Nombre, @CedulaJuridica, @Correo, @Activo);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarRestaurante','P') IS NOT NULL DROP PROCEDURE sp_ActualizarRestaurante;
GO
CREATE PROCEDURE sp_ActualizarRestaurante
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.Restaurante
    SET Nombre = @Nombre,
        CedulaJuridica = @CedulaJuridica,
        Correo = @Correo,
        Activo = @Activo
    WHERE RestauranteId = @RestauranteId;
END
GO

IF OBJECT_ID('sp_EliminarRestaurante','P') IS NOT NULL DROP PROCEDURE sp_EliminarRestaurante;
GO
CREATE PROCEDURE sp_EliminarRestaurante
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM core.Restaurante WHERE RestauranteId = @RestauranteId;
END
GO

-- ===== Suscripcion =====
IF OBJECT_ID('sp_ObtenerSuscripciones','P') IS NOT NULL DROP PROCEDURE sp_ObtenerSuscripciones;
GO
CREATE PROCEDURE sp_ObtenerSuscripciones
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SuscripcionId, RestauranteId, PlanId, FechaInicio, FechaFin, Estado FROM core.Restaurante;
END
GO

IF OBJECT_ID('sp_ObtenerSuscripcionPorId','P') IS NOT NULL DROP PROCEDURE sp_ObtenerSuscripcionPorId;
GO
CREATE PROCEDURE sp_ObtenerSuscripcionPorId
    @SuscripcionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SuscripcionId, RestauranteId, PlanId, FechaInicio, FechaFin, Estado FROM core.Suscripcion WHERE SuscripcionId = @SuscripcionId;
END
GO

IF OBJECT_ID('sp_InsertarSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_InsertarSuscripcion;
GO
CREATE PROCEDURE sp_InsertarSuscripcion
    @RestauranteId INT,
    @PlanId INT,
    @FechaInicio DATE,
    @Estado VARCHAR(20),
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.Suscripcion (RestauranteId, PlanId, FechaInicio, FechaFin, Estado) VALUES (@RestauranteId, @PlanId, @FechaInicio, @FechaFin, @Estado);
    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS Id;
END
GO

IF OBJECT_ID('sp_ActualizarSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_ActualizarSuscripcion;
GO
CREATE PROCEDURE sp_ActualizarSuscripcion
    @SuscripcionId INT,
    @RestauranteId INT,
    @PlanId INT,
    @FechaInicio DATE,
    @Estado VARCHAR(20),
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.Suscripcion
    SET RestauranteId = @RestauranteId,
        PlanId = @PlanId,
        FechaInicio = @FechaInicio,
        FechaFin = @FechaFin,
        Estado = @Estado
    WHERE SuscripcionId = @SuscripcionId;
END
GO

IF OBJECT_ID('sp_EliminarSuscripcion','P') IS NOT NULL DROP PROCEDURE sp_EliminarSuscripcion;
GO
CREATE PROCEDURE sp_EliminarSuscripcion
    @SuscripcionId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM core.Suscripcion WHERE SuscripcionId = @SuscripcionId;
END
GO
