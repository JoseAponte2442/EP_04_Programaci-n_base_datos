USE DB_GestionComercial_EP04;
GO
--TRIGGER 1: AFTER INSERT (Usa la tabla virtual INSERTED)
-- Descripción: Cuando se inserta una venta en Ventas, descuenta automáticamente la cantidad vendida del Stock en Productos.

CREATE TRIGGER trg_DescontarStock
ON Ventas
AFTER INSERT
AS
BEGIN
    UPDATE Productos
    SET Stock = Productos.Stock - inserted.Cantidad
    FROM Productos
    INNER JOIN inserted ON Productos.ProductoID = inserted.ProductoID;

    PRINT 'TRIGGER INSERT: Se descontó el stock del producto vendido.';
END;
GO


-- TRIGGER 2: AFTER UPDATE (Usa DELETED e INSERTED)
-- Descripción: Cuando se actualiza el precio de un producto, guarda el precio anterior (deleted) y el precio nuevo (inserted) en la tabla AuditoriaPrecios.

CREATE TRIGGER trg_AuditarCambioPrecio
ON Productos
AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditoriaPrecios (ProductoID, PrecioAnterior, PrecioNuevo, FechaCambio)
    SELECT 
        d.ProductoID,
        d.Precio,
        i.Precio,
        GETDATE()
    FROM deleted d
    INNER JOIN inserted i ON d.ProductoID = i.ProductoID
    WHERE d.Precio <> i.Precio;

    PRINT 'TRIGGER UPDATE: Se registró el cambio de precio en AuditoriaPrecios.';
END;
GO

-- TRIGGER 3: AFTER DELETE (Usa la tabla virtual DELETED)
-- Descripción: Cuando se elimina un cliente de la tabla Clientes, guarda sus datos eliminados en AuditoriaClientesEliminados.
CREATE TRIGGER trg_AuditarClienteEliminado
ON Clientes
AFTER DELETE
AS
BEGIN
    INSERT INTO AuditoriaClientesEliminados (ClienteID, NombreCompleto, FechaEliminacion)
    SELECT 
        ClienteID,
        Nombre + ' ' + Apellido,
        GETDATE()
    FROM deleted;

    PRINT 'TRIGGER DELETE: Se registró el cliente eliminado en AuditoriaClientesEliminados.';
END;
GO

-- PRUEBA 1 (INSERT): Registramos una venta de 2 Laptops HP (ProductoID = 1)
-- Cambio detectado: El stock inicial de Laptop HP (15) debe bajar a 13.
INSERT INTO Ventas (ClienteID, ProductoID, Cantidad, FechaVenta)
VALUES (2, 1, 2, GETDATE());
GO

-- PRUEBA 2 (UPDATE): Subimos el precio del Monitor Samsung (ProductoID = 2) de 650.00 a 720.00
-- Cambio detectado: Se guarda 650.00 (deleted) y 720.00 (inserted) en AuditoriaPrecios.
UPDATE Productos
SET Precio = 720.00
WHERE ProductoID = 2;
GO

-- PRUEBA 3 (DELETE): Eliminamos al cliente 5 (Ricardo Gomez, que no tiene ventas registradas)
-- Cambio detectado: Se borra de Clientes y queda registrado en AuditoriaClientesEliminados.
DELETE FROM Clientes
WHERE ClienteID = 5;
GO

-- Verificación de evidencia en tablas
SELECT * FROM Productos;
SELECT * FROM AuditoriaPrecios;
SELECT * FROM Clientes;
SELECT * FROM AuditoriaClientesEliminados;
GO