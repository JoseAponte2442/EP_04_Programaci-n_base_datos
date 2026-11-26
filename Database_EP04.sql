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

-- Tablas de auditoría (para demostrar los triggers)
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
--DATOS DE PRUEBA

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

-- Verificar que todo se cargó bien
SELECT * FROM Clientes;
SELECT * FROM Productos;
SELECT * FROM Ventas;
GO