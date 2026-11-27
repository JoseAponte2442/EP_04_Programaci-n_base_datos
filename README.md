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

	/* Trigger 01 para registrar los datos insertados en la tabla productos*/
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

INSERT INTO dbo.Productos (NombreProducto, Precio, Stock)
VALUES ('Audífonos Sony', 350.00, 20);

SELECT * FROM dbo.Productos;
SELECT * FROM dbo.AuditoriaProductos;


```
* **`Productos`:** Se registra todo ingreso de productos nuevos.

<img width="1453" height="789" alt="image" src="https://github.com/user-attachments/assets/c83270d5-2ca2-4c00-93ec-c6056785fd22" />


```sql
	/* Trigger 02 para registrar los cambios de precio*/
CREATE OR ALTER TRIGGER dbo.trg_AuditarCambioPrecio
ON dbo.Productos AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.AuditoriaPrecios (ProductoID, NombreProducto, PrecioAnterior, PrecioNuevo, FechaCambio)
    SELECT d.ProductoID, i.NombreProducto,d.Precio, i.Precio, GETDATE()
    FROM inserted AS i JOIN deleted as d ON d.ProductoID = i.ProductoID
    where i.Precio <> d.Precio
END;
GO

UPDATE dbo.Productos
SET Precio = 2900.00
WHERE ProductoID = 1;

SELECT * FROM dbo.AuditoriaPrecios;
```
* **`AuditoriaPrecios`:** Se registró el cambio de precio del `ProductoID = 1` ( nuevo precio → `2900.00`).

<img width="1200" height="543" alt="image" src="https://github.com/user-attachments/assets/80e2a13f-5552-4d07-8df8-2656ff4a70f9" />

```sql

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
```

* **`AuditoriaClientesEliminados`:** Se respaldó al cliente eliminado `Ricardo Gomez` (`ClienteID = 5`).
<img width="1111" height="539" alt="image" src="https://github.com/user-attachments/assets/ad263359-47e0-40b6-864d-ed4d4de778e1" />
