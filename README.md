# EP_04_Programaci-n_base_datos

## Integrantes del equipo

| N° | Nombre completo                      | Correo institucional  | Aporte |
|----|--------------------------------------|-----------------------|--------|
| 1  | Imanol Ponce de León                 | 76221830@mail.isil.pe |  100%  |
| 2  | Jose Manuel Aponte Tanta             | 75619512@mail.isil.pe |  100%  |
| 3  | Andrés Francisco Pimentel Saldaña    | 73213777@mail.isil.pe |  0%    |
| 4  | Jhonn Paul Ccasani Enciso            | 44061898@mail.isil.pe |  0%    |

# Actividad 1: Automatización mediante Desencadenantes (Triggers)

## 1. Descripción y Justificación
Implementación de desencadenantes (`triggers`) en **Microsoft SQL Server** (`DB_GestionComercial_EP04`) para automatizar el control de inventario y la auditoría de cambios ante operaciones `INSERT`, `UPDATE` y `DELETE`. Se utilizan estos objetos porque responden de forma automática e inmediata a nivel de servidor aprovechando las tablas virtuales **`inserted`** y **`deleted`**.

## 2. Triggers Implementados

| Trigger | Tabla | Evento | Acción |
| :--- | :--- | :--- | :--- |
| `trg_DescontarStock` | `Ventas` | `AFTER INSERT` | Descuenta del `Stock` en `Productos` la cantidad registrada en `inserted`. |
| `trg_AuditarCambioPrecio` | `Productos` | `AFTER UPDATE` | Registra en `AuditoriaPrecios` el precio previo (`deleted`) y el nuevo (`inserted`). |
| `trg_AuditarClienteEliminado` | `Clientes` | `AFTER DELETE` | Respalda en `AuditoriaClientesEliminados` los datos capturados en `deleted`. |

## 3. Código SQL

```sql
USE DB_GestionComercial_EP04;
GO

-- 1. AFTER INSERT (Uso de INSERTED)
CREATE TRIGGER trg_DescontarStock
ON Ventas AFTER INSERT
AS
BEGIN
    UPDATE Productos
    SET Stock = Productos.Stock - inserted.Cantidad
    FROM Productos
    INNER JOIN inserted ON Productos.ProductoID = inserted.ProductoID;
    PRINT 'TRIGGER INSERT: Se descontó el stock del producto vendido.';
END;
GO

-- 2. AFTER UPDATE (Uso de DELETED e INSERTED)
CREATE TRIGGER trg_AuditarCambioPrecio
ON Productos AFTER UPDATE
AS
BEGIN
    INSERT INTO AuditoriaPrecios (ProductoID, PrecioAnterior, PrecioNuevo, FechaCambio)
    SELECT d.ProductoID, d.Precio, i.Precio, GETDATE()
    FROM deleted d
    INNER JOIN inserted i ON d.ProductoID = i.ProductoID
    WHERE d.Precio <> i.Precio;
    PRINT 'TRIGGER UPDATE: Se registró el cambio de precio en AuditoriaPrecios.';
END;
GO

-- 3. AFTER DELETE (Uso de DELETED)
CREATE TRIGGER trg_AuditarClienteEliminado
ON Clientes AFTER DELETE
AS
BEGIN
    INSERT INTO AuditoriaClientesEliminados (ClienteID, NombreCompleto, FechaEliminacion)
    SELECT ClienteID, Nombre + ' ' + Apellido, GETDATE()
    FROM deleted;
    PRINT 'TRIGGER DELETE: Se registró el cliente eliminado en AuditoriaClientesEliminados.';
END;
GO
```

## 4. Pruebas y Resultados
```sql
INSERT INTO Ventas (ClienteID, ProductoID, Cantidad, FechaVenta) VALUES (2, 1, 2, GETDATE());
UPDATE Productos SET Precio = 720.00 WHERE ProductoID = 2;
DELETE FROM Clientes WHERE ClienteID = 5;
```

* **`Productos`:** El stock de `Laptop HP` bajó automáticamente de `15` a **`13`**.
* **`AuditoriaPrecios`:** Se registró el cambio de precio del `ProductoID = 2` (`650.00` → `720.00`).
* **`AuditoriaClientesEliminados`:** Se respaldó al cliente eliminado `Ricardo Gomez` (`ClienteID = 5`).

> *(Adjuntar aquí captura de resultados de SSMS)*
