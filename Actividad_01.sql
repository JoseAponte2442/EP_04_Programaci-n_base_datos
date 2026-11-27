USE DB_GestionComercial_EP04;
GO

	/* Trigger 01 para registrar los datos insertados en la tabla productos*/
CREATE OR ALTER TRIGGER dbo.EP_04_trg_AfterInsert
ON dbo.Productos
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditoriaProductos (ProductoID, NombreProducto, Accion)
    SELECT i.ProductoID, i.NombreProducto, 'INSERT'
    FROM inserted AS i;
END;
GO
	/* Validación 01*/

INSERT INTO dbo.Productos (NombreProducto, Precio, Stock)
VALUES ('Audífonos Sony', 350.00, 20);

SELECT * FROM dbo.Productos;
SELECT * FROM dbo.AuditoriaProductos;


GO


	/* Trigger 02 para registrar los cambios de precio*/
CREATE OR ALTER TRIGGER trg_AuditarCambioPrecio
ON Productos AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditoriaPrecios (ProductoID, NombreProducto, PrecioAnterior, PrecioNuevo, FechaCambio)
    SELECT d.ProductoID, i.NombreProducto,d.Precio, i.Precio, GETDATE()
    FROM inserted AS i JOIN deleted as d ON d.ProductoID = i.ProductoID
    where i.Precio <> d.Precio
END;
GO
/* Validación 02*/
UPDATE dbo.Productos
SET Precio = 2900.00
WHERE ProductoID = 1;

SELECT * FROM dbo.AuditoriaPrecios;

	/* Trigger 03 para guardar a los clientes eliminados*/

CREATE OR ALTER TRIGGER trg_AuditarClienteEliminado
ON Clientes AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO AuditoriaClientesEliminados (ClienteID, NombreCompleto, FechaEliminacion)
    SELECT ClienteID, Nombre + ' ' + Apellido, GETDATE()
    FROM deleted;
END;
GO
/* Validación 03*/
DELETE FROM Clientes WHERE ClienteID = 5;

SELECT * FROM AuditoriaClientesEliminados;
