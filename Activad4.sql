-- ACTIVIDAD 4: AUTENTICACIÓN, USUARIOS, ROLES Y SEGURIDAD 
-- Base de datos: DB_GestionComercial_EP04


--
USE master;
GO


--
-- 1. CREACIÓN DE INICIOS DE SESIÓN LOGINS
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_vendedor')
    CREATE LOGIN login_vendedor WITH PASSWORD = 'Vendedor#2026_Secure!', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_almacen')
    CREATE LOGIN login_almacen WITH PASSWORD = 'Almacen#2026_Secure!', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_auditor')
    CREATE LOGIN login_auditor WITH PASSWORD = 'Auditor#2026_Secure!', CHECK_POLICY = ON;
GO


--
USE DB_GestionComercial_EP04;
GO


IF OBJECT_ID('dbo.fn_CalcularTotalConIGV', 'FN') IS NULL
EXEC('
CREATE FUNCTION dbo.fn_CalcularTotalConIGV (@Precio MONEY, @Cantidad INT)
RETURNS MONEY AS
BEGIN
    DECLARE @Subtotal MONEY = @Precio * @Cantidad;
    DECLARE @Descuento MONEY = CASE WHEN @Cantidad >= 5 THEN @Subtotal * 0.10 WHEN @Cantidad >= 3 THEN @Subtotal * 0.05 ELSE 0 END;
    RETURN ROUND((@Subtotal - @Descuento) * 1.18, 2);
END;
');
GO

IF OBJECT_ID('dbo.fn_ReporteVentasPorCiudad', 'IF') IS NULL
EXEC('
CREATE FUNCTION dbo.fn_ReporteVentasPorCiudad (@Ciudad NVARCHAR(50))
RETURNS TABLE AS
RETURN (
    SELECT v.VentaID, c.Nombre + '' '' + c.Apellido AS Cliente, c.Ciudad, p.NombreProducto, v.Cantidad, p.Precio AS PrecioUnitario, v.FechaVenta
    FROM dbo.Ventas v
    INNER JOIN dbo.Clientes c ON v.ClienteID = c.ClienteID
    INNER JOIN dbo.Productos p ON v.ProductoID = p.ProductoID
    WHERE c.Ciudad = @Ciudad
);
');
GO

-- Limpieza previa para permitir la re-ejecución limpia del script
DROP USER IF EXISTS usr_vendedor;
DROP USER IF EXISTS usr_almacen;
DROP USER IF EXISTS usr_auditor;
DROP ROLE IF EXISTS rol_ventas;
DROP ROLE IF EXISTS rol_inventario;
DROP ROLE IF EXISTS rol_auditoria;
GO

--
-- 2. CREACIÓN DE ROLES PERSONALIZADOS DE BASE DE DATOS
CREATE ROLE rol_ventas;
CREATE ROLE rol_inventario;
CREATE ROLE rol_auditoria;
GO

--
-- 3. ASIGNACIÓN DE PERMISOS GRANULARES POR ROL
GRANT SELECT ON dbo.Clientes TO rol_ventas;
GRANT SELECT ON dbo.Productos TO rol_ventas;
GRANT SELECT ON dbo.Ventas TO rol_ventas;
GRANT INSERT ON dbo.Clientes TO rol_ventas;
GRANT INSERT ON dbo.Ventas TO rol_ventas;
GRANT EXECUTE ON dbo.fn_CalcularTotalConIGV TO rol_ventas;
GRANT SELECT ON dbo.fn_ReporteVentasPorCiudad TO rol_ventas;

GRANT SELECT, INSERT, UPDATE ON dbo.Productos TO rol_inventario;
DENY DELETE ON dbo.Productos TO rol_inventario;

GRANT SELECT ON dbo.AuditoriaProductos TO rol_auditoria;
GRANT SELECT ON dbo.AuditoriaPrecios TO rol_auditoria;
GRANT SELECT ON dbo.AuditoriaClientesEliminados TO rol_auditoria;
GRANT SELECT ON dbo.Clientes TO rol_auditoria;
GRANT SELECT ON dbo.Productos TO rol_auditoria;
GRANT SELECT ON dbo.Ventas TO rol_auditoria;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_auditoria;
GO

--
-- 4. CREACIÓN DE USUARIOS EN LA BASE DE DATOS Y ASIGNACIÓN DE ROLES
CREATE USER usr_vendedor FOR LOGIN login_vendedor;
CREATE USER usr_almacen FOR LOGIN login_almacen;
CREATE USER usr_auditor FOR LOGIN login_auditor;
GO

ALTER ROLE rol_ventas ADD MEMBER usr_vendedor;
ALTER ROLE rol_inventario ADD MEMBER usr_almacen;
ALTER ROLE rol_auditoria ADD MEMBER usr_auditor;
GO


--
-- 5. VALIDACIÓN Y PRUEBAS DE ACCESO MEDIANTE SUPLANTACIÓN 

-- PRUEBA A: Perfil Vendedor
EXECUTE AS USER = 'usr_vendedor';
    SELECT VentaID, dbo.fn_CalcularTotalConIGV(350.00, Cantidad) AS TotalCalculado 
    FROM dbo.Ventas;

    -- Bloqueado 
    UPDATE dbo.Productos SET Precio = 10.00 WHERE ProductoID = 1;
REVERT;
GO

-- PRUEBA B: Perfil Almacén 
EXECUTE AS USER = 'usr_almacen';
    UPDATE dbo.Productos SET Stock = Stock + 5 WHERE ProductoID = 1;

    -- Bloqueado
    SELECT * FROM dbo.Clientes;
REVERT;
GO

-- PRUEBA C: Perfil Auditor
EXECUTE AS USER = 'usr_auditor';
    SELECT * FROM dbo.AuditoriaPrecios;

    -- Bloqueado
    DELETE FROM dbo.AuditoriaPrecios;
REVERT;
GO