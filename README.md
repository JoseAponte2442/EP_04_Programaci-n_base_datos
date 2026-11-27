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
| `trg_RegistroProducto` | `Productos` | `AFTER INSERT` | Registra los nuevos ingresos en `Productos` con  `inserted`. |
| `trg_AuditarCambioPrecio` | `Productos` | `AFTER UPDATE` | Registra en `AuditoriaPrecios` el precio previo (`deleted`) y el nuevo (`inserted`). |
| `trg_AuditarClienteEliminado` | `Clientes` | `AFTER DELETE` | Respalda en `AuditoriaClientesEliminados` los datos capturados en `deleted`. |

## 3. Código SQL

```sql
USE DB_GestionComercial_EP04;
GO

-- 1. AFTER INSERT (Uso de INSERTED)
CREATE OR ALTER TRIGGER dbo.trg_RegistroProducto
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
```
<img width="1453" height="789" alt="image" src="https://github.com/user-attachments/assets/c83270d5-2ca2-4c00-93ec-c6056785fd22" />


```sql
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

> <img width="1912" height="664" alt="image" src="https://github.com/user-attachments/assets/5c860894-1a42-43cd-8f0d-c3ef43726c26" />
<img width="1919" height="690" alt="image" src="https://github.com/user-attachments/assets/66e497d0-0e13-48e1-84f0-797baa79211c" />
<img width="1919" height="601" alt="image" src="https://github.com/user-attachments/assets/b7ff438f-a7db-4d94-9997-7362476cd7c2" />

<img width="1911" height="910" alt="image" src="https://github.com/user-attachments/assets/25fca8e3-02de-4438-bd01-cbd117af97e9" />
<img width="1910" height="916" alt="image" src="https://github.com/user-attachments/assets/d1363f4d-951a-4ac4-8811-dd8cc07c24f9" />
