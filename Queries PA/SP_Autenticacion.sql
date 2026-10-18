/* ==========================================================================
   Proyecto Bases de Datos II - PedidosRestaurantes
   Stored procedures de autenticación (requisito de R2)
     - seguridad.sp_RegistrarUsuario
     - seguridad.sp_Login
     - seguridad.sp_CambiarContrasena
     - seguridad.sp_DesbloquearUsuario
   Requiere: Bd/PedidosRest.sql ejecutado antes.

   Cómo se guarda la contraseña:
     - Por cada usuario se genera una sal aleatoria de 32 bytes con CRYPT_GEN_RANDOM.
     - Se guarda HASHBYTES('SHA2_512', contraseña + sal). La contraseña nunca se guarda.
     - Dos usuarios con la misma contraseña tienen hashes distintos por la sal.

   Errores que devuelven (para que el API los traduzca a mensajes/códigos HTTP):
     50001  El correo ya está registrado.
     50002  La contraseña debe tener al menos 8 caracteres.
     50003  El rol no corresponde con el restaurante, sede o cliente indicado.
     50010  Correo o contraseña incorrectos.
     50011  Cuenta bloqueada por intentos fallidos.
     50012  La contraseña actual no es correcta.
   ========================================================================== */
USE PedidosRestaurantes;
GO

-- --------------------------------------------------------------------------
-- Registrar usuario: valida los datos, genera la sal y guarda el hash.
-- Devuelve el UsuarioId creado.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE seguridad.sp_RegistrarUsuario
    @Correo        NVARCHAR(150),
    @Contrasena    NVARCHAR(128),
    @RolId         TINYINT,
    @RestauranteId INT = NULL,
    @SedeId        INT = NULL,
    @ClienteId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Correo = LOWER(LTRIM(RTRIM(@Correo)));

    IF EXISTS (SELECT 1 FROM seguridad.Usuario WHERE Correo = @Correo)
        THROW 50001, N'El correo ya está registrado.', 1;

    IF @Contrasena IS NULL OR LEN(@Contrasena) < 8
        THROW 50002, N'La contraseña debe tener al menos 8 caracteres.', 1;

    -- Misma regla que CK_Usuario_Ambito, pero con un mensaje claro para el API.
    IF NOT (
           (@RolId = 1 AND @RestauranteId IS NULL     AND @SedeId IS NULL     AND @ClienteId IS NULL)
        OR (@RolId = 2 AND @RestauranteId IS NOT NULL AND @SedeId IS NULL     AND @ClienteId IS NULL)
        OR (@RolId = 3 AND @RestauranteId IS NOT NULL AND @SedeId IS NOT NULL AND @ClienteId IS NULL)
        OR (@RolId = 4 AND @RestauranteId IS NULL     AND @SedeId IS NULL     AND @ClienteId IS NOT NULL)
    )
        THROW 50003, N'El rol no corresponde con el restaurante, sede o cliente indicado.', 1;

    DECLARE @Sal VARBINARY(32) = CRYPT_GEN_RANDOM(32);
    DECLARE @Hash VARBINARY(64) = HASHBYTES('SHA2_512', CAST(@Contrasena AS VARBINARY(256)) + @Sal);

    INSERT INTO seguridad.Usuario (Correo, ContrasenaHash, Sal, RolId, RestauranteId, SedeId, ClienteId)
    VALUES (@Correo, @Hash, @Sal, @RolId, @RestauranteId, @SedeId, @ClienteId);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS UsuarioId;
END
GO

-- --------------------------------------------------------------------------
-- Login: valida correo y contraseña.
--   - Si es correcto: reinicia los intentos fallidos, guarda el último acceso
--     y devuelve los datos del usuario (nunca el hash ni la sal).
--   - Si es incorrecto: suma un intento fallido. Con 5 intentos la cuenta se bloquea.
--   - Para no revelar qué correos existen, el mensaje es el mismo si el correo
--     no existe, si el usuario está inactivo o si la contraseña está mal.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE seguridad.sp_Login
    @Correo     NVARCHAR(150),
    @Contrasena NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaxIntentos TINYINT = 5;
    DECLARE @UsuarioId INT,
            @Hash      VARBINARY(64),
            @Sal       VARBINARY(32),
            @Activo    BIT,
            @Intentos  TINYINT;

    SELECT @UsuarioId = UsuarioId,
           @Hash      = ContrasenaHash,
           @Sal       = Sal,
           @Activo    = Activo,
           @Intentos  = IntentosFallidos
    FROM seguridad.Usuario
    WHERE Correo = LOWER(LTRIM(RTRIM(@Correo)));

    IF @UsuarioId IS NULL OR @Activo = 0
        THROW 50010, N'Correo o contraseña incorrectos.', 1;

    IF @Intentos >= @MaxIntentos
        THROW 50011, N'La cuenta está bloqueada por demasiados intentos fallidos. Contacte al administrador.', 1;

    IF HASHBYTES('SHA2_512', CAST(@Contrasena AS VARBINARY(256)) + @Sal) <> @Hash
    BEGIN
        UPDATE seguridad.Usuario
        SET IntentosFallidos = IntentosFallidos + 1
        WHERE UsuarioId = @UsuarioId;

        THROW 50010, N'Correo o contraseña incorrectos.', 1;
    END;

    UPDATE seguridad.Usuario
    SET IntentosFallidos = 0,
        UltimoAcceso     = SYSDATETIME()
    WHERE UsuarioId = @UsuarioId;

    SELECT u.UsuarioId,
           u.Correo,
           u.RolId,
           r.Nombre AS Rol,
           u.RestauranteId,
           u.SedeId,
           u.ClienteId,
           u.UltimoAcceso
    FROM seguridad.Usuario u
    JOIN seguridad.Rol r ON r.RolId = u.RolId
    WHERE u.UsuarioId = @UsuarioId;
END
GO

-- --------------------------------------------------------------------------
-- Cambiar contraseña: exige la contraseña actual y genera una sal nueva.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE seguridad.sp_CambiarContrasena
    @UsuarioId        INT,
    @ContrasenaActual NVARCHAR(128),
    @ContrasenaNueva  NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Hash VARBINARY(64), @Sal VARBINARY(32);

    SELECT @Hash = ContrasenaHash, @Sal = Sal
    FROM seguridad.Usuario
    WHERE UsuarioId = @UsuarioId AND Activo = 1;

    IF @Hash IS NULL
       OR HASHBYTES('SHA2_512', CAST(@ContrasenaActual AS VARBINARY(256)) + @Sal) <> @Hash
        THROW 50012, N'La contraseña actual no es correcta.', 1;

    IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
        THROW 50002, N'La contraseña debe tener al menos 8 caracteres.', 1;

    DECLARE @NuevaSal VARBINARY(32) = CRYPT_GEN_RANDOM(32);

    UPDATE seguridad.Usuario
    SET Sal              = @NuevaSal,
        ContrasenaHash   = HASHBYTES('SHA2_512', CAST(@ContrasenaNueva AS VARBINARY(256)) + @NuevaSal),
        IntentosFallidos = 0
    WHERE UsuarioId = @UsuarioId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO

-- --------------------------------------------------------------------------
-- Desbloquear usuario: lo usa un administrador cuando una cuenta llegó
-- al máximo de intentos fallidos.
-- --------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE seguridad.sp_DesbloquearUsuario
    @UsuarioId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE seguridad.Usuario
    SET IntentosFallidos = 0
    WHERE UsuarioId = @UsuarioId;

    SELECT @@ROWCOUNT AS FilasAfectadas;
END
GO
