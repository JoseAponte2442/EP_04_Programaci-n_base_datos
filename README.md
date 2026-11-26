# EP_04_Programaci-n_base_datos

## Integrantes del equipo

| N° | Nombre completo                      | Correo institucional  | Aporte |
|----|--------------------------------------|-----------------------|--------|
| 1  | Imanol Ponce de León                 | 76221830@mail.isil.pe |  100%  |
| 2  | Jose Manuel Aponte Tanta             | 75619512@mail.isil.pe |  100%  |
| 3  | Andrés Francisco Pimentel Saldaña    | 73213777@mail.isil.pe |  0%    |
| 4  | Jhonn Paul Ccasani Enciso            | 44061898@mail.isil.pe |  0%    |


# Actividad 1: Automatización mediante Desencadenantes (Triggers) en SQL Server

## 1. Contexto y Problema
La organización requiere administrar sus clientes, productos y operaciones comerciales mediante una base de datos relacional en **Microsoft SQL Server** (`DB_GestionComercial_EP04`). Ante modificaciones críticas en los datos (`INSERT`, `UPDATE`, `DELETE`), el servidor debe responder automáticamente con acciones verificables de control de inventario y auditoría, sin depender de intervenciones manuales.

---

## 2. Justificación Técnica del Objeto
Se implementaron **desencadenantes (triggers)** por las siguientes razones:
* **Ejecución automática ante eventos DML:** Se disparan de forma inmediata y transparente cuando ocurre una inserción, actualización o eliminación sobre una tabla específica.
* **Acceso a tablas virtuales del sistema (`inserted` y `deleted`):** Permiten capturar en memoria los valores nuevos (`inserted`) y los valores previos o eliminados (`deleted`) durante la transacción para registrar evidencias verificables en tablas de auditoría.
* **Integridad y trazabilidad:** Garantizan que ninguna operación de venta deje de descontar inventario y que toda modificación de precio o eliminación de cliente quede auditada en el servidor.

---

## 3. Arquitectura de Desencadenantes Implementados

| Trigger | Tabla Objetivo | Evento | Tablas Virtuales | Acción Automatizada |
| :--- | :--- | :--- | :--- | :--- |
| `trg_DescontarStock` | `Ventas` | `AFTER INSERT` | `inserted` | Descuenta automáticamente la cantidad vendida (`inserted.Cantidad`) del campo `Stock` en la tabla `Productos`. |
| `trg_AuditarCambioPrecio` | `Productos` | `AFTER UPDATE` | `deleted`, `inserted` | Compara el precio anterior (`deleted.Precio`) frente al nuevo (`inserted.Precio`) y guarda el historial en `AuditoriaPrecios`. |
| `trg_AuditarClienteEliminado` | `Clientes` | `AFTER DELETE` | `deleted` | Respalda los datos del cliente eliminado en `AuditoriaClientesEliminados` junto con la fecha y hora exacta. |

---

## 4. Script SQL Completo

### 4.1. Creación de Tablas y Datos Iniciales
```sql
CREATE DATABASE DB_GestionComercial_EP04;
GO

USE DB_GestionComercial_EP04;
GO

-- Tablas operativas
CREATE TABLE Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(50),
    Apellido NVARCHAR(50),
    Ciudad NVARCHAR(50)
);

CREATE TABLE Productos (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    NombreProducto NVARCHAR(50),
    Precio MONEY,
    Stock INT
);

CREATE TABLE Ventas (
    VentaID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT FOREIGN KEY REFERENCES Clientes(ClienteID),
    ProductoID INT FOREIGN KEY REFERENCES Productos(ProductoID),
    Cantidad INT,
    FechaVenta DATETIME
);

-- Tablas de auditoría
CREATE TABLE AuditoriaPrecios (
    AuditoriaID INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID INT,
    PrecioAnterior MONEY,
    PrecioNuevo MONEY,
    FechaCambio DATETIME
);

CREATE TABLE AuditoriaClientesEliminados (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT,
    NombreCompleto NVARCHAR(100),
    FechaEliminacion DATETIME
);
GO

-- Carga inicial de datos
INSERT INTO Clientes (Nombre, Apellido, Ciudad)
VALUES 
    ('Carlos', 'Mendoza', 'Lima'),
    ('Lucia', 'Fernandez', 'Arequipa'),
    ('Jorge', 'Paredes', 'Trujillo'),
    ('Mariana', 'Torres', 'Lima'),
    ('Ricardo', 'Gomez', 'Cusco');

INSERT INTO Productos (NombreProducto, Precio, Stock)
VALUES 
    ('Laptop HP', 2500.00, 15),
    ('Monitor Samsung', 650.00, 25),
    ('Teclado Mecanico', 180.00, 40),
    ('Mouse Inalambrico', 75.00, 50),
    ('Impresora Epson', 820.00, 10);

INSERT INTO Ventas (ClienteID, ProductoID, Cantidad, FechaVenta)
VALUES 
    (1, 1, 1, '2026-11-10'),
    (1, 4, 2, '2026-11-12'),
    (2, 2, 1, '2026-11-15'),
    (3, 3, 3, '2026-11-18'),
    (4, 5, 1, '2026-11-20');
GO
```

### 4.2. Creación de los Desencadenantes
```sql
USE DB_GestionComercial_EP04;
GO

-- 1. Trigger AFTER INSERT (Uso de INSERTED)
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

-- 2. Trigger AFTER UPDATE (Uso de DELETED e INSERTED)
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

    PRINT 'TRIGGER UPDATE: Se
