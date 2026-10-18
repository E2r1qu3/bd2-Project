/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures CRUD: core.PlanSuscripcion, core.Restaurante, core.Suscripcion
   Requiere: Bd/PedidosRest.sql ejecutado antes.
   Cada SP se crea dentro del esquema de su tabla para que rol_api pueda ejecutarlo.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- ===== core.PlanSuscripcion =====
CREATE OR ALTER PROCEDURE core.sp_ObtenerPlanesSuscripcion
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, Nombre, MaxSedes, PrecioMensual, Activo
    FROM core.PlanSuscripcion
    ORDER BY PlanId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerPlanSuscripcionPorId
    @PlanId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlanId, Nombre, MaxSedes, PrecioMensual, Activo
    FROM core.PlanSuscripcion
    WHERE PlanId = @PlanId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarPlanSuscripcion
    @Nombre NVARCHAR(50),
    @MaxSedes INT,
    @PrecioMensual DECIMAL(12,2),
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.PlanSuscripcion (Nombre, MaxSedes, PrecioMensual, Activo)
    VALUES (@Nombre, @MaxSedes, @PrecioMensual, @Activo);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarPlanSuscripcion
    @PlanId INT,
    @Nombre NVARCHAR(50),
    @MaxSedes INT,
    @PrecioMensual DECIMAL(12,2),
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.PlanSuscripcion
    SET Nombre = @Nombre,
        MaxSedes = @MaxSedes,
        PrecioMensual = @PrecioMensual,
        Activo = @Activo
    WHERE PlanId = @PlanId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE core.sp_EliminarPlanSuscripcion
    @PlanId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Borrado lógico: el registro se desactiva para no perder pedidos ni historial asociados.
    UPDATE core.PlanSuscripcion
    SET Activo = 0
    WHERE PlanId = @PlanId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== core.Restaurante =====
CREATE OR ALTER PROCEDURE core.sp_ObtenerRestaurantes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Telefono, Activo, FechaRegistro
    FROM core.Restaurante
    ORDER BY RestauranteId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerRestaurantePorId
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RestauranteId, Nombre, CedulaJuridica, Correo, Telefono, Activo, FechaRegistro
    FROM core.Restaurante
    WHERE RestauranteId = @RestauranteId;
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
    INSERT INTO core.Restaurante (Nombre, CedulaJuridica, Correo, Telefono, Activo)
    VALUES (@Nombre, @CedulaJuridica, @Correo, @Telefono, @Activo);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarRestaurante
    @RestauranteId INT,
    @Nombre NVARCHAR(100),
    @CedulaJuridica VARCHAR(20),
    @Correo NVARCHAR(150),
    @Telefono VARCHAR(20) = NULL,
    @Activo BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE core.Restaurante
    SET Nombre = @Nombre,
        CedulaJuridica = @CedulaJuridica,
        Correo = @Correo,
        Telefono = @Telefono,
        Activo = @Activo
    WHERE RestauranteId = @RestauranteId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE core.sp_EliminarRestaurante
    @RestauranteId INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Borrado lógico: el registro se desactiva para no perder pedidos ni historial asociados.
    UPDATE core.Restaurante
    SET Activo = 0
    WHERE RestauranteId = @RestauranteId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- ===== core.Suscripcion =====
CREATE OR ALTER PROCEDURE core.sp_ObtenerSuscripciones
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SuscripcionId, RestauranteId, PlanId, FechaInicio, FechaFin, Estado
    FROM core.Suscripcion
    ORDER BY SuscripcionId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ObtenerSuscripcionPorId
    @SuscripcionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SuscripcionId, RestauranteId, PlanId, FechaInicio, FechaFin, Estado
    FROM core.Suscripcion
    WHERE SuscripcionId = @SuscripcionId;
END
GO

CREATE OR ALTER PROCEDURE core.sp_InsertarSuscripcion
    @RestauranteId INT,
    @PlanId INT,
    @FechaInicio DATE,
    @FechaFin DATE = NULL,
    @Estado VARCHAR(15) = 'Activa'
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO core.Suscripcion (RestauranteId, PlanId, FechaInicio, FechaFin, Estado)
    VALUES (@RestauranteId, @PlanId, @FechaInicio, @FechaFin, @Estado);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id;
END
GO

CREATE OR ALTER PROCEDURE core.sp_ActualizarSuscripcion
    @SuscripcionId INT,
    @RestauranteId INT,
    @PlanId INT,
    @FechaInicio DATE,
    @FechaFin DATE = NULL,
    @Estado VARCHAR(15)
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

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

CREATE OR ALTER PROCEDURE core.sp_EliminarSuscripcion
    @SuscripcionId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM core.Suscripcion
    WHERE SuscripcionId = @SuscripcionId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

