# EP_04_Programaci-n_base_datos

## Integrantes del equipo

| N° | Nombre completo                      | Correo institucional  | Aporte |
|----|--------------------------------------|-----------------------|--------|
| 1  | Imanol Ponce de León                 | 76221830@mail.isil.pe |  100%  |
| 2  | Jose Manuel Aponte Tanta             | 75619512@mail.isil.pe |  100%  |
| 3  | Andrés Francisco Pimentel Saldaña    | 73213777@mail.isil.pe |  100%    |
| 4  | Jhonn Paul Ccasani Enciso            | 44061898@mail.isil.pe |  0%    |
| 5  | Matias Manuel Solano Pinto           | - |  0%    |

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

DELETE FROM Clientes WHERE ClienteID = 5;

SELECT * FROM AuditoriaClientesEliminados;
```

* **`AuditoriaClientesEliminados`:** Se respaldó al cliente eliminado `Ricardo Gomez` (`ClienteID = 5`).
<img width="1111" height="539" alt="image" src="https://github.com/user-attachments/assets/ad263359-47e0-40b6-864d-ed4d4de778e1" />


# Actividad 2: Funciones Escalares y Funciones de Tipo Tabla
* Hecha por Andrés Pimentel
## 1. Descripción y Justificación

Implementación de funciones definidas por el usuario (UDF) en **Microsoft SQL Server (`DB_GestionComercial_EP04`)** para abstraer cálculos comerciales repetitivos y consultas parametrizadas de ventas. Encapsular estas operaciones en objetos del servidor evita duplicar fórmulas de descuento e impuestos en múltiples consultas, centraliza el mantenimiento ante cambios en las reglas de negocio y garantiza resultados consistentes en toda la base de datos.

---

## 2. Funciones Implementadas

| Función | Tipo | Parámetros | Retorno | Acción |
| :--- | :--- | :--- | :--- | :--- |
| `dbo.fn_CalcularTotalConIGV` | Escalar | `@Precio money`, `@Cantidad int` | `money` | Calcula el importe total de una venta aplicando descuento por volumen (5% desde 3 unidades y 10% desde 5 unidades) más el 18% de IGV. |
| `dbo.fn_ReporteVentasPorCiudad` | Tabla (*Inline*) | `@Ciudad nvarchar(50)` | `table` | Devuelve el detalle de ventas realizadas a clientes de una ciudad específica, integrando `Ventas`, `Clientes` y `Productos`. |

---

## 3. Código SQL y pruebas de consumo

### Función 01: escalar (`dbo.fn_CalcularTotalConIGV`)

```sql
use DB_GestionComercial_EP04;
go

--ACTIVIDAD 02

/* Función escalar */
create or alter function dbo.fn_CalcularTotalConIGV (
    @Precio money,
    @Cantidad int
)
returns money
as
begin
    declare @Subtotal money;
    declare @Descuento money;
    declare @TotalConIGV money;

    if @Precio is null or @Cantidad is null or @Precio < 0 or @Cantidad <= 0
        return 0;

    set @Subtotal = @Precio * @Cantidad;

    set @Descuento = case
        when @Cantidad >= 5 then @Subtotal * 0.10
        when @Cantidad >= 3 then @Subtotal * 0.05
        else 0
    end;

    set @TotalConIGV = round((@Subtotal - @Descuento) * 1.18, 2);

    return @TotalConIGV;
end;
go

-- 1. Consumo de la función escalar como expresión en SELECT y filtro en WHERE
select
    v.VentaID,
    p.NombreProducto,
    p.Precio,
    v.Cantidad,
    (p.Precio * v.Cantidad) as SubtotalBruto,
    dbo.fn_CalcularTotalConIGV(p.Precio, v.Cantidad) as TotalConIGV
from dbo.Ventas as v
INNER JOIN dbo.Productos as p on v.ProductoID = p.ProductoID
where dbo.fn_CalcularTotalConIGV(p.Precio, v.Cantidad) > 500
order by v.VentaID;
go
```

* `dbo.fn_CalcularTotalConIGV` : Se invocó en las cláusulas `SELECT` y `WHERE` para calcular el importe con IGV y filtrar ventas mayores a `S/500.00`. La consulta retorna 4 registros (`VentaID` 1, 3, 4 y 5), excluye la venta de 2 mouse inalámbricos (`S/177.00`) y aplica el 5% de descuento por volumen en la venta de 3 teclados mecánicos (`SubtotalBruto = S/540.00` → `TotalConIGV = S/605.34`).
<img width="860" height="479" alt="{D17FFBED-F5AC-4AD7-B3BC-18DF7C196604}" src="https://github.com/user-attachments/assets/297013e5-5c2b-4720-82d3-6efcdcc6094e" />


---

### Función 02: tipo tabla (`dbo.fn_ReporteVentasPorCiudad`)

```sql
/* Función tipo tabla */
create OR alter function dbo.fn_ReporteVentasPorCiudad (
    @Ciudad nvarchar(50)
)
returns table
as
return (
    select
        v.VentaID,
        c.Nombre + ' ' + c.Apellido as Cliente,
        c.Ciudad,
        p.NombreProducto,
        v.Cantidad,
        p.Precio as PrecioUnitario,
        (p.Precio * v.Cantidad) as SubtotalBruto,
        dbo.fn_CalcularTotalConIGV(p.Precio, v.Cantidad) as TotalConIGV,
        v.FechaVenta
    from dbo.Ventas as v
    inner join dbo.Clientes as c on v.ClienteID = c.ClienteID
    inner join dbo.Productos as p on v.ProductoID = p.ProductoID
    where c.Ciudad = @Ciudad
);
go

-- 2. Consumo de la función de tipo tabla en la cláusula FROM (como tabla parametrizada)
select *
from dbo.fn_ReporteVentasPorCiudad('Lima')
order BY FechaVenta;
go
```

* `dbo.fn_ReporteVentasPorCiudad` : Se consumió en la cláusula `FROM` enviando `'Lima'` como parámetro y reutilizando internamente `dbo.fn_CalcularTotalConIGV`. La consulta retorna las 3 ventas correspondientes a los clientes registrados en Lima (Carlos Mendoza y Mariana Torres), ordenadas por `FechaVenta`.
<img width="852" height="307" alt="{1F649A7A-25E8-40C8-BC3A-1C6EC0D8E4BE}" src="https://github.com/user-attachments/assets/d804b1fe-4a5b-47c5-a555-941bccdc2a2a" />


---

## 4. Comparación funcional y cuándo conviene usarlas

### Diferencias principales entre ambas funciones

* **Tipo de retorno:**
  * **Función escalar (`dbo.fn_CalcularTotalConIGV`):** Devuelve un único valor puntual de un tipo de dato escalar (`money`).
  * **Función de tipo tabla (`dbo.fn_ReporteVentasPorCiudad`):** Devuelve un conjunto de filas y columnas (`table`).

* **Forma de consumo en consultas:**
  * **Función escalar:** Se invoca como una expresión dentro de `SELECT`, `WHERE`, `HAVING`, `ORDER BY` o asignada a una variable (`SET`).
  * **Función de tipo tabla:** Se invoca en la cláusula `FROM` (o mediante `JOIN`), comportándose como una tabla o vista parametrizada.

* **Estructura e impacto en rendimiento:**
  * **Función escalar:** Utiliza un bloque `BEGIN ... END` con `RETURN @valor`. Si se aplica dentro de un `WHERE` sobre tablas muy grandes, se evalúa fila por fila y puede restar eficiencia al filtro.
  * **Función de tipo tabla:** Al ser de tipo *inline* (`RETURNS TABLE AS RETURN`), SQL Server integra su consulta directamente en el plan de ejecución y aprovecha los índices de las tablas subyacentes.

### ¿Cuándo resulta pertinente usar cada una?

* **Función escalar:** Conviene utilizarla cuando se necesita calcular, validar o formatear un dato puntual a partir de parámetros de entrada (por ejemplo, aplicar descuentos por volumen, calcular el IGV o concatenar textos) para reutilizar la misma fórmula en distintos reportes sin repetir código.
* **Función de tipo tabla:** Conviene utilizarla cuando se necesita encapsular una consulta multitabla que devuelva varios registros y columnas filtrados por un parámetro dinámico (por ejemplo, reportes de ventas por ciudad o historial por cliente), funcionando como una alternativa parametrizable a una vista.
