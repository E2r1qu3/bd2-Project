USE master;
GO

IF DB_ID(N'PedidosRestaurantes') IS NOT NULL
BEGIN
    ALTER DATABASE PedidosRestaurantes SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PedidosRestaurantes;
END
GO

CREATE DATABASE PedidosRestaurantes COLLATE Modern_Spanish_CI_AS;
GO

USE PedidosRestaurantes;
GO

CREATE SCHEMA core      AUTHORIZATION dbo;
GO
CREATE SCHEMA menu      AUTHORIZATION dbo;
GO
CREATE SCHEMA ventas    AUTHORIZATION dbo;
GO
CREATE SCHEMA seguridad AUTHORIZATION dbo;
GO

CREATE TABLE core.PlanSuscripcion (
    PlanId          INT IDENTITY(1,1) CONSTRAINT PK_PlanSuscripcion PRIMARY KEY,
    Nombre          NVARCHAR(50)  NOT NULL CONSTRAINT UQ_PlanSuscripcion_Nombre UNIQUE,
    MaxSedes        INT           NOT NULL CONSTRAINT CK_Plan_MaxSedes CHECK (MaxSedes > 0),
    PrecioMensual   DECIMAL(12,2) NOT NULL CONSTRAINT CK_Plan_Precio CHECK (PrecioMensual >= 0),
    Activo          BIT           NOT NULL CONSTRAINT DF_Plan_Activo DEFAULT (1)
);

CREATE TABLE core.Restaurante (
    RestauranteId   INT IDENTITY(1,1) CONSTRAINT PK_Restaurante PRIMARY KEY,
    Nombre          NVARCHAR(100) NOT NULL,
    CedulaJuridica  VARCHAR(20)   NOT NULL CONSTRAINT UQ_Restaurante_Cedula UNIQUE,
    Correo          NVARCHAR(150) NOT NULL,
    Telefono        VARCHAR(20)   NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Restaurante_Activo DEFAULT (1),
    FechaRegistro   DATETIME2(0)  NOT NULL CONSTRAINT DF_Restaurante_Fecha DEFAULT (SYSDATETIME())
);

CREATE TABLE core.Suscripcion (
    SuscripcionId   INT IDENTITY(1,1) CONSTRAINT PK_Suscripcion PRIMARY KEY,
    RestauranteId   INT          NOT NULL CONSTRAINT FK_Suscripcion_Restaurante REFERENCES core.Restaurante(RestauranteId),
    PlanId          INT          NOT NULL CONSTRAINT FK_Suscripcion_Plan REFERENCES core.PlanSuscripcion(PlanId),
    FechaInicio     DATE         NOT NULL,
    FechaFin        DATE         NULL,
    Estado          VARCHAR(15)  NOT NULL CONSTRAINT DF_Suscripcion_Estado DEFAULT ('Activa'),
    CONSTRAINT CK_Suscripcion_Estado CHECK (Estado IN ('Activa','Suspendida','Cancelada')),
    CONSTRAINT CK_Suscripcion_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);

CREATE TABLE core.Sede (
    SedeId          INT IDENTITY(1,1) CONSTRAINT PK_Sede PRIMARY KEY,
    RestauranteId   INT           NOT NULL CONSTRAINT FK_Sede_Restaurante REFERENCES core.Restaurante(RestauranteId),
    Nombre          NVARCHAR(100) NOT NULL,
    Provincia       NVARCHAR(30)  NOT NULL,
    Canton          NVARCHAR(50)  NOT NULL,
    DireccionExacta NVARCHAR(250) NOT NULL,
    Telefono        VARCHAR(20)   NULL,
    HoraApertura    TIME(0)       NOT NULL,
    HoraCierre      TIME(0)       NOT NULL,
    OfreceExpress   BIT           NOT NULL CONSTRAINT DF_Sede_Express DEFAULT (1),
    Activa          BIT           NOT NULL CONSTRAINT DF_Sede_Activa DEFAULT (1),
    CONSTRAINT UQ_Sede_Restaurante_Nombre UNIQUE (RestauranteId, Nombre)
);

CREATE TABLE menu.Categoria (
    CategoriaId     INT IDENTITY(1,1) CONSTRAINT PK_Categoria PRIMARY KEY,
    RestauranteId   INT           NOT NULL CONSTRAINT FK_Categoria_Restaurante REFERENCES core.Restaurante(RestauranteId),
    Nombre          NVARCHAR(60)  NOT NULL,
    Orden           SMALLINT      NOT NULL CONSTRAINT DF_Categoria_Orden DEFAULT (0),
    CONSTRAINT UQ_Categoria_Restaurante_Nombre UNIQUE (RestauranteId, Nombre)
);

CREATE TABLE menu.Producto (
    ProductoId      INT IDENTITY(1,1) CONSTRAINT PK_Producto PRIMARY KEY,
    RestauranteId   INT           NOT NULL CONSTRAINT FK_Producto_Restaurante REFERENCES core.Restaurante(RestauranteId),
    CategoriaId     INT           NOT NULL CONSTRAINT FK_Producto_Categoria REFERENCES menu.Categoria(CategoriaId),
    Nombre          NVARCHAR(100) NOT NULL,
    Descripcion     NVARCHAR(400) NULL,
    PrecioBase      DECIMAL(12,2) NOT NULL CONSTRAINT CK_Producto_Precio CHECK (PrecioBase > 0),
    ImagenUrl       NVARCHAR(400) NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Producto_Activo DEFAULT (1)
);

CREATE TABLE menu.ProductoSede (
    SedeId          INT           NOT NULL CONSTRAINT FK_ProductoSede_Sede REFERENCES core.Sede(SedeId),
    ProductoId      INT           NOT NULL CONSTRAINT FK_ProductoSede_Producto REFERENCES menu.Producto(ProductoId),
    Disponible      BIT           NOT NULL CONSTRAINT DF_ProductoSede_Disp DEFAULT (1),
    PrecioSede      DECIMAL(12,2) NULL,
    CONSTRAINT PK_ProductoSede PRIMARY KEY (SedeId, ProductoId),
    CONSTRAINT CK_ProductoSede_Precio CHECK (PrecioSede IS NULL OR PrecioSede > 0)
);

CREATE TABLE ventas.Modalidad (
    ModalidadId       TINYINT      NOT NULL CONSTRAINT PK_Modalidad PRIMARY KEY,
    Nombre            NVARCHAR(30) NOT NULL CONSTRAINT UQ_Modalidad_Nombre UNIQUE,
    RequiereDireccion BIT          NOT NULL
);

CREATE TABLE ventas.EstadoPedido (
    EstadoId        TINYINT      NOT NULL CONSTRAINT PK_EstadoPedido PRIMARY KEY,
    Nombre          NVARCHAR(30) NOT NULL CONSTRAINT UQ_EstadoPedido_Nombre UNIQUE,
    EsFinal         BIT          NOT NULL
);

CREATE TABLE ventas.MetodoPago (
    MetodoPagoId    TINYINT      NOT NULL CONSTRAINT PK_MetodoPago PRIMARY KEY,
    Nombre          NVARCHAR(30) NOT NULL CONSTRAINT UQ_MetodoPago_Nombre UNIQUE
);

CREATE TABLE ventas.Cliente (
    ClienteId       INT IDENTITY(1,1) CONSTRAINT PK_Cliente PRIMARY KEY,
    Nombre          NVARCHAR(60)  NOT NULL,
    Apellidos       NVARCHAR(80)  NOT NULL,
    Correo          NVARCHAR(150) NOT NULL CONSTRAINT UQ_Cliente_Correo UNIQUE,
    Telefono        VARCHAR(20)   NULL,
    FechaRegistro   DATETIME2(0)  NOT NULL CONSTRAINT DF_Cliente_Fecha DEFAULT (SYSDATETIME())
);

CREATE TABLE ventas.DireccionCliente (
    DireccionId     INT IDENTITY(1,1) CONSTRAINT PK_DireccionCliente PRIMARY KEY,
    ClienteId       INT           NOT NULL CONSTRAINT FK_Direccion_Cliente REFERENCES ventas.Cliente(ClienteId),
    Alias           NVARCHAR(50)  NOT NULL,
    Provincia       NVARCHAR(30)  NOT NULL,
    Canton          NVARCHAR(50)  NOT NULL,
    Distrito        NVARCHAR(50)  NOT NULL,
    Detalle         NVARCHAR(250) NOT NULL,
    Latitud         DECIMAL(9,6)  NULL,
    Longitud        DECIMAL(9,6)  NULL,
    Activa          BIT           NOT NULL CONSTRAINT DF_Direccion_Activa DEFAULT (1)
);

CREATE TABLE seguridad.Rol (
    RolId           TINYINT      NOT NULL CONSTRAINT PK_Rol PRIMARY KEY,
    Nombre          NVARCHAR(30) NOT NULL CONSTRAINT UQ_Rol_Nombre UNIQUE,
    Descripcion     NVARCHAR(200) NULL
);

CREATE TABLE seguridad.Usuario (
    UsuarioId        INT IDENTITY(1,1) CONSTRAINT PK_Usuario PRIMARY KEY,
    Correo           NVARCHAR(150) NOT NULL CONSTRAINT UQ_Usuario_Correo UNIQUE,
    ContrasenaHash   VARBINARY(64) NOT NULL,
    Sal              VARBINARY(32) NOT NULL,
    RolId            TINYINT       NOT NULL CONSTRAINT FK_Usuario_Rol REFERENCES seguridad.Rol(RolId),
    RestauranteId    INT           NULL CONSTRAINT FK_Usuario_Restaurante REFERENCES core.Restaurante(RestauranteId),
    SedeId           INT           NULL CONSTRAINT FK_Usuario_Sede REFERENCES core.Sede(SedeId),
    ClienteId        INT           NULL CONSTRAINT FK_Usuario_Cliente REFERENCES ventas.Cliente(ClienteId),
    Activo           BIT           NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT (1),
    IntentosFallidos TINYINT       NOT NULL CONSTRAINT DF_Usuario_Intentos DEFAULT (0),
    UltimoAcceso     DATETIME2(0)  NULL,
    FechaCreacion    DATETIME2(0)  NOT NULL CONSTRAINT DF_Usuario_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Usuario_Ambito CHECK (
        (RolId = 1 AND RestauranteId IS NULL     AND SedeId IS NULL     AND ClienteId IS NULL)
     OR (RolId = 2 AND RestauranteId IS NOT NULL AND SedeId IS NULL     AND ClienteId IS NULL)
     OR (RolId = 3 AND RestauranteId IS NOT NULL AND SedeId IS NOT NULL AND ClienteId IS NULL)
     OR (RolId = 4 AND RestauranteId IS NULL     AND SedeId IS NULL     AND ClienteId IS NOT NULL)
    )
);

CREATE UNIQUE INDEX UX_Usuario_Cliente ON seguridad.Usuario(ClienteId) WHERE ClienteId IS NOT NULL;

CREATE TABLE ventas.Pedido (
    PedidoId        INT IDENTITY(1,1) CONSTRAINT PK_Pedido PRIMARY KEY,
    ClienteId       INT           NOT NULL CONSTRAINT FK_Pedido_Cliente   REFERENCES ventas.Cliente(ClienteId),
    SedeId          INT           NOT NULL CONSTRAINT FK_Pedido_Sede      REFERENCES core.Sede(SedeId),
    ModalidadId     TINYINT       NOT NULL CONSTRAINT FK_Pedido_Modalidad REFERENCES ventas.Modalidad(ModalidadId),
    EstadoId        TINYINT       NOT NULL CONSTRAINT FK_Pedido_Estado    REFERENCES ventas.EstadoPedido(EstadoId)
                                           CONSTRAINT DF_Pedido_Estado DEFAULT (1),
    DireccionId     INT           NULL     CONSTRAINT FK_Pedido_Direccion REFERENCES ventas.DireccionCliente(DireccionId),
    FechaPedido     DATETIME2(0)  NOT NULL CONSTRAINT DF_Pedido_Fecha DEFAULT (SYSDATETIME()),
    Subtotal        DECIMAL(12,2) NOT NULL CONSTRAINT DF_Pedido_Subtotal DEFAULT (0),
    Impuesto        DECIMAL(12,2) NOT NULL CONSTRAINT DF_Pedido_Impuesto DEFAULT (0),
    CostoEnvio      DECIMAL(12,2) NOT NULL CONSTRAINT DF_Pedido_Envio DEFAULT (0),
    Total           AS (Subtotal + Impuesto + CostoEnvio) PERSISTED,
    Notas           NVARCHAR(300) NULL,
    CONSTRAINT CK_Pedido_Montos CHECK (Subtotal >= 0 AND Impuesto >= 0 AND CostoEnvio >= 0)
);

CREATE TABLE ventas.DetallePedido (
    PedidoId        INT           NOT NULL CONSTRAINT FK_Detalle_Pedido   REFERENCES ventas.Pedido(PedidoId),
    Linea           SMALLINT      NOT NULL,
    ProductoId      INT           NOT NULL CONSTRAINT FK_Detalle_Producto REFERENCES menu.Producto(ProductoId),
    Cantidad        SMALLINT      NOT NULL CONSTRAINT CK_Detalle_Cantidad CHECK (Cantidad > 0),
    PrecioUnitario  DECIMAL(12,2) NOT NULL CONSTRAINT CK_Detalle_Precio CHECK (PrecioUnitario > 0),
    Subtotal        AS (Cantidad * PrecioUnitario) PERSISTED,
    Nota            NVARCHAR(150) NULL,
    CONSTRAINT PK_DetallePedido PRIMARY KEY (PedidoId, Linea)
);

CREATE TABLE ventas.HistorialEstadoPedido (
    HistorialId     BIGINT IDENTITY(1,1) CONSTRAINT PK_HistorialEstado PRIMARY KEY,
    PedidoId        INT           NOT NULL CONSTRAINT FK_Historial_Pedido  REFERENCES ventas.Pedido(PedidoId),
    EstadoId        TINYINT       NOT NULL CONSTRAINT FK_Historial_Estado  REFERENCES ventas.EstadoPedido(EstadoId),
    UsuarioId       INT           NULL     CONSTRAINT FK_Historial_Usuario REFERENCES seguridad.Usuario(UsuarioId),
    FechaCambio     DATETIME2(0)  NOT NULL CONSTRAINT DF_Historial_Fecha DEFAULT (SYSDATETIME()),
    Comentario      NVARCHAR(200) NULL
);

CREATE TABLE ventas.Pago (
    PagoId            INT IDENTITY(1,1) CONSTRAINT PK_Pago PRIMARY KEY,
    PedidoId          INT           NOT NULL CONSTRAINT FK_Pago_Pedido REFERENCES ventas.Pedido(PedidoId),
    MetodoPagoId      TINYINT       NOT NULL CONSTRAINT FK_Pago_Metodo REFERENCES ventas.MetodoPago(MetodoPagoId),
    Monto             DECIMAL(12,2) NOT NULL CONSTRAINT CK_Pago_Monto CHECK (Monto > 0),
    Estado            VARCHAR(15)   NOT NULL CONSTRAINT DF_Pago_Estado DEFAULT ('Pendiente'),
    ReferenciaExterna VARCHAR(100)  NULL,
    FechaPago         DATETIME2(0)  NOT NULL CONSTRAINT DF_Pago_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Pago_Estado CHECK (Estado IN ('Pendiente','Aprobado','Rechazado','Reembolsado'))
);

CREATE TABLE ventas.Entrega (
    EntregaId         INT IDENTITY(1,1) CONSTRAINT PK_Entrega PRIMARY KEY,
    PedidoId          INT           NOT NULL CONSTRAINT FK_Entrega_Pedido REFERENCES ventas.Pedido(PedidoId)
                                             CONSTRAINT UQ_Entrega_Pedido UNIQUE,
    ProveedorEntrega  NVARCHAR(60)  NOT NULL,
    CodigoSeguimiento VARCHAR(60)   NULL,
    Estado            VARCHAR(15)   NOT NULL CONSTRAINT DF_Entrega_Estado DEFAULT ('Asignada'),
    FechaSalida       DATETIME2(0)  NULL,
    FechaEntrega      DATETIME2(0)  NULL,
    CONSTRAINT CK_Entrega_Estado CHECK (Estado IN ('Asignada','EnCamino','Entregada','Fallida')),
    CONSTRAINT CK_Entrega_Fechas CHECK (FechaEntrega IS NULL OR FechaSalida IS NULL OR FechaEntrega >= FechaSalida)
);
GO

CREATE INDEX IX_Sede_Restaurante        ON core.Sede(RestauranteId);
CREATE INDEX IX_Suscripcion_Restaurante ON core.Suscripcion(RestauranteId, Estado);
CREATE INDEX IX_Producto_Restaurante    ON menu.Producto(RestauranteId, CategoriaId);
CREATE INDEX IX_ProductoSede_Producto   ON menu.ProductoSede(ProductoId);
CREATE INDEX IX_Direccion_Cliente       ON ventas.DireccionCliente(ClienteId);
CREATE INDEX IX_Pedido_Sede_Fecha       ON ventas.Pedido(SedeId, FechaPedido) INCLUDE (EstadoId, ModalidadId);
CREATE INDEX IX_Pedido_Cliente          ON ventas.Pedido(ClienteId, FechaPedido);
CREATE INDEX IX_Detalle_Producto        ON ventas.DetallePedido(ProductoId);
CREATE INDEX IX_Historial_Pedido        ON ventas.HistorialEstadoPedido(PedidoId, FechaCambio);
CREATE INDEX IX_Pago_Pedido             ON ventas.Pago(PedidoId);
GO

INSERT INTO seguridad.Rol (RolId, Nombre, Descripcion) VALUES
 (1, N'AdminPlataforma',  N'Administra la plataforma SaaS completa'),
 (2, N'AdminRestaurante', N'Administra sedes, menú y pedidos de su restaurante'),
 (3, N'EmpleadoSede',     N'Recibe y actualiza los pedidos de su sede'),
 (4, N'Cliente',          N'Realiza pedidos');

INSERT INTO ventas.Modalidad (ModalidadId, Nombre, RequiereDireccion) VALUES
 (1, N'Comer en el restaurante', 0),
 (2, N'Retiro en el local',      0),
 (3, N'Express',                 1);

INSERT INTO ventas.EstadoPedido (EstadoId, Nombre, EsFinal) VALUES
 (1, N'Pendiente',      0),
 (2, N'Confirmado',     0),
 (3, N'En preparación', 0),
 (4, N'Listo',          0),
 (5, N'En camino',      0),
 (6, N'Entregado',      1),
 (7, N'Cancelado',      1);

INSERT INTO ventas.MetodoPago (MetodoPagoId, Nombre) VALUES
 (1, N'Tarjeta'),
 (2, N'SINPE Móvil'),
 (3, N'Efectivo');

INSERT INTO core.PlanSuscripcion (Nombre, MaxSedes, PrecioMensual) VALUES
 (N'Básico',      1,  15000.00),
 (N'Crecimiento', 5,  45000.00),
 (N'Cadena',      50, 90000.00);
GO

USE master;
GO

IF SUSER_ID(N'login_api_pedidos') IS NULL
    CREATE LOGIN login_api_pedidos   WITH PASSWORD = N'Api#Pedidos2026!',   DEFAULT_DATABASE = PedidosRestaurantes, CHECK_POLICY = ON;
IF SUSER_ID(N'login_admin_pedidos') IS NULL
    CREATE LOGIN login_admin_pedidos WITH PASSWORD = N'Admin#Pedidos2026!', DEFAULT_DATABASE = PedidosRestaurantes, CHECK_POLICY = ON;
IF SUSER_ID(N'login_reportes_pedidos') IS NULL
    CREATE LOGIN login_reportes_pedidos WITH PASSWORD = N'Rep#Pedidos2026!', DEFAULT_DATABASE = PedidosRestaurantes, CHECK_POLICY = ON;
IF SUSER_ID(N'login_dev_pedidos') IS NULL
    CREATE LOGIN login_dev_pedidos   WITH PASSWORD = N'Dev#Pedidos2026!',   DEFAULT_DATABASE = PedidosRestaurantes, CHECK_POLICY = ON;
GO

USE PedidosRestaurantes;
GO

CREATE USER usr_api       FOR LOGIN login_api_pedidos      WITH DEFAULT_SCHEMA = ventas;
CREATE USER usr_admin     FOR LOGIN login_admin_pedidos    WITH DEFAULT_SCHEMA = core;
CREATE USER usr_reportes  FOR LOGIN login_reportes_pedidos WITH DEFAULT_SCHEMA = ventas;
CREATE USER usr_dev       FOR LOGIN login_dev_pedidos      WITH DEFAULT_SCHEMA = dbo;
GO

CREATE ROLE rol_api;
CREATE ROLE rol_administrador;
CREATE ROLE rol_reportes;
CREATE ROLE rol_desarrollador;
GO

GRANT EXECUTE ON SCHEMA::core      TO rol_api;
GRANT EXECUTE ON SCHEMA::menu      TO rol_api;
GRANT EXECUTE ON SCHEMA::ventas    TO rol_api;
GRANT EXECUTE ON SCHEMA::seguridad TO rol_api;

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::core      TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::menu      TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::ventas    TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::seguridad TO rol_administrador;

GRANT SELECT ON SCHEMA::core   TO rol_reportes;
GRANT SELECT ON SCHEMA::menu   TO rol_reportes;
GRANT SELECT ON SCHEMA::ventas TO rol_reportes;
DENY  SELECT ON SCHEMA::seguridad TO rol_reportes;

GRANT CREATE TABLE, CREATE PROCEDURE, CREATE FUNCTION, CREATE VIEW, SHOWPLAN TO rol_desarrollador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE, VIEW DEFINITION ON SCHEMA::core      TO rol_desarrollador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE, VIEW DEFINITION ON SCHEMA::menu      TO rol_desarrollador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE, VIEW DEFINITION ON SCHEMA::ventas    TO rol_desarrollador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE, VIEW DEFINITION ON SCHEMA::seguridad TO rol_desarrollador;
GO

ALTER ROLE rol_api           ADD MEMBER usr_api;
ALTER ROLE rol_administrador ADD MEMBER usr_admin;
ALTER ROLE rol_reportes      ADD MEMBER usr_reportes;
ALTER ROLE rol_desarrollador ADD MEMBER usr_dev;
GO

SELECT s.name AS Esquema, t.name AS Tabla
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;

SELECT r.name AS Rol, m.name AS Usuario
FROM sys.database_role_members rm
JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
WHERE r.name LIKE 'rol[_]%'
ORDER BY r.name;

SELECT pr.name AS Rol, pe.permission_name AS Permiso, pe.state_desc AS Estado,
       SCHEMA_NAME(pe.major_id) AS Esquema
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name LIKE 'rol[_]%'
ORDER BY pr.name, Esquema, Permiso;
GO