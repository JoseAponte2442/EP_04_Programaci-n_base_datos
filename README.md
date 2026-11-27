# EP_04_Programaci-n_base_datos

## Integrantes del equipo

| N° | Nombre completo                      | Correo institucional  | Aporte |
|----|--------------------------------------|-----------------------|--------|
| 1  | Imanol Ponce de León                 | 76221830@mail.isil.pe |  100%  |
| 2  | Jose Manuel Aponte Tanta             | 75619512@mail.isil.pe |  100%  |
| 3  | Andrés Francisco Pimentel Saldaña    | 73213777@mail.isil.pe |  100%    |
| 4  | Jhonn Paul Ccasani Enciso            | 44061898@mail.isil.pe |  0%    |
| 5  | Matias Manuel Solano Pinto           | 74363124@mail.isil.com |  100%    |

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


# Actividad 3: Cursor y Evaluación Crítica de Alternativas
- Hecha por Imanol Ponce de León
## 1. Descripción y Justificación

Implementación y consumo de un cursor en **Microsoft SQL Server (`DB_GestionComercial_EP04`)** para evaluar el comportamiento del procesamiento fila por fila (*row-by-row*) sobre el inventario de productos, contrastándolo frente a una operación declarativa basada en conjuntos (*set-based*). Este análisis permite determinar técnicamente cuándo resulta innecesario el recorrido secuencial y por qué el motor relacional privilegia las consultas sobre conjuntos completos.

---

## 2. Objetos y Enfoques Comparados

| Enfoque | Objeto / Instrucción | Mecanismo de Ejecución | Salida Generada | Acción |
| :--- | :--- | :--- | :--- | :--- |
| **Cursor** | `cur_EvaluacionStock` (`CURSOR FAST_FORWARD`) | Recorrido secuencial fila por fila mediante `OPEN`, `FETCH NEXT`, `WHILE @@FETCH_STATUS = 0`, `CLOSE` y `DEALLOCATE`. | Mensajes individuales en consola (`PRINT`). | Evalúa el `Stock` actual de cada registro de `dbo.Productos` y clasifica si requiere reposición urgente o mantiene nivel óptimo. |
| **Basado en Conjuntos** | Consulta `SELECT` con expresión `CASE` | Lectura declarativa en bloque sobre toda la tabla `dbo.Productos`. | Conjunto de resultados tabular reutilizable. | Aplica exactamente la misma regla de clasificación de inventario en una sola operación relacional sin ciclos ni variables intermedias. |

---

## 3. Código SQL y pruebas de ejecución

### Enfoque 01: Implementación y consumo del cursor (`cur_EvaluacionStock`)

```sql
use DB_GestionComercial_EP04;
go

-- ACTIVIDAD 03

/* Implementación y consumo de cursor */
declare @ProductoID int;
declare @NombreProducto nvarchar(100);
declare @Precio money;
declare @Stock int;
declare @EstadoInventario nvarchar(60);

declare cur_EvaluacionStock cursor fast_forward for
select
    ProductoID,
    NombreProducto,
    Precio,
    Stock
from dbo.Productos
order by ProductoID;

open cur_EvaluacionStock;

fetch next from cur_EvaluacionStock
into @ProductoID, @NombreProducto, @Precio, @Stock;

while @@fetch_status = 0
begin
    if @Stock <= 10
        set @EstadoInventario = 'ALERTA: Stock crítico - Reabastecer';
    else if @Stock <= 25
        set @EstadoInventario = 'ATENCIÓN: Stock moderado';
    else
        set @EstadoInventario = 'ÓPTIMO: Stock suficiente';

    print concat(
        'ID: ', @ProductoID,
        ' | Producto: ', @NombreProducto,
        ' | Precio: S/', cast(@Precio as varchar(20)),
        ' | Stock: ', @Stock,
        ' -> ', @EstadoInventario
    );

    fetch next from cur_EvaluacionStock
    into @ProductoID, @NombreProducto, @Precio, @Stock;
end;

close cur_EvaluacionStock;
deallocate cur_EvaluacionStock;
go
```

- `cur_EvaluacionStock` : Se declaró con la opción `FAST_FORWARD` (solo avance y solo lectura) para reducir la sobrecarga en memoria mientras recorre `dbo.Productos`. En cada iteración del bucle `WHILE @@FETCH_STATUS = 0`, el cursor carga los valores de la fila actual en variables escalares, evalúa el nivel de stock mediante condicionales `IF ... ELSE` e imprime el diagnóstico individual en la pestaña de mensajes de SSMS, liberando finalmente los recursos con `CLOSE` y `DEALLOCATE`.



---

### Enfoque 02: Alternativa basada en conjuntos (`SELECT` + `CASE`)

```sql
/* Alternativa comparada: consulta basada en conjuntos */
select
    p.ProductoID,
    p.NombreProducto,
    p.Precio,
    p.Stock,
    case
        when p.Stock <= 10 then 'ALERTA: Stock crítico - Reabastecer'
        when p.Stock <= 25 then 'ATENCIÓN: Stock moderado'
        else 'ÓPTIMO: Stock suficiente'
    end as EstadoInventario
from dbo.Productos as p
order by p.ProductoID;
go
```

- **Consulta basada en conjuntos** : Resuelve la misma clasificación de inventario de forma declarativa en una única sentencia `SELECT`. El optimizador de SQL Server procesa todas las filas en bloque y retorna una tabla estructurada lista para ser consumida por reportes, vistas o aplicaciones cliente sin necesidad de administrar ciclos ni memoria temporal manualmente.



---

## 4. Comparación técnica y conclusión sustentada

### Ventajas, desventajas e implicancias de ambos enfoques

- **Gestión de memoria y recursos del servidor:**
  - **Cursor (`cur_EvaluacionStock`):** Reserva espacio en memoria y en `tempdb` para sostener el conjunto activo desde `OPEN` hasta `DEALLOCATE`. Si una excepción interrumpe el bloque antes de liberar el cursor, los recursos permanecen retenidos en la sesión.
  - **Operación basada en conjuntos:** No requiere estructuras iterativas ni liberación manual de memoria; el motor administra el plan de ejecución de forma automática y eficiente.

- **Rendimiento y concurrencia:**
  - **Cursor:** Ejecuta lógica fila por fila (*RBAR - Row-By-Agonizing-Row*), incrementando el consumo de CPU por cada instrucción `FETCH NEXT` y prolongando el tiempo de bloqueo sobre los registros leídos, lo que puede generar contención si existen ventas concurrentes.
  - **Operación basada en conjuntos:** Realiza una lectura optimizada en bloque aprovechando índices y paralelismo, reduciendo drásticamente la latencia y el tiempo de bloqueo.

- **Flexibilidad operativa:**
  - **Cursor:** Permite ejecutar acciones procedimentales individuales por cada fila (como invocar un procedimiento almacenado distinto por registro o disparar tareas secuenciales donde cada iteración depende del resultado anterior).
  - **Operación basada en conjuntos:** Está orientada a transformar, filtrar o clasificar conjuntos completos de datos en una sola operación atómica.

### Conclusión técnicamente sustentada

Para este caso de negocio en **`DB_GestionComercial_EP04`**, **no resulta recomendable utilizar un cursor** en producción cuando el objetivo es consultar, clasificar o reportar el estado del inventario o las ventas. SQL Server es un sistema gestor de bases de datos relacional diseñado bajo teoría de conjuntos, por lo que la consulta declarativa con `CASE` ofrece mejor rendimiento, menor consumo de `tempdb`, menor contención de bloqueos y una salida tabular directamente integrable con otras consultas.

El uso de cursores debe reservarse exclusivamente para escenarios procedimentales muy específicos —como tareas administrativas de mantenimiento por base de datos o ejecución secuencial de procedimientos almacenados por registro— donde resulte inviable expresar la lógica mediante una operación basada en conjuntos.





# Actividad 4: Autenticación, Usuarios, Roles y Seguridad
- Hecha por Matias Manuel Solano Pino

## 1. Descripción, Justificación y Tipo de Autenticación

Implementación de un esquema de control de acceso basado en roles (RBAC) en **Microsoft SQL Server (`DB_GestionComercial_EP04`)** para restringir las operaciones según las responsabilidades de cada perfil de la organización, aplicando el **principio de mínimo privilegio**.

### Tipo de autenticación seleccionada: Autenticación de SQL Server (Modo Mixto)
- **Justificación técnica:** En una organización comercial donde los usuarios operan desde distintos módulos de aplicación o terminales (caja/ventas, almacén/catálogo y auditoría), la **Autenticación de SQL Server** permite gestionar inicios de sesión (`LOGIN`) independientes del dominio de Windows, facilitando la portabilidad entre servidores, el control centralizado de políticas de contraseñas y la trazabilidad directa por rol dentro del motor de base de datos.

---

## 2. Perfiles de Acceso Definidos

* **Perfil 1 — Ventas (`rol_ventas`):**
  * **Credenciales:** Login `login_vendedor` → Usuario `usr_vendedor`.
  * **Permisos:** Lectura (`SELECT`) en `Clientes`, `Productos`, `Ventas` y funciones (`fn_CalcularTotalConIGV`, `fn_ReporteVentasPorCiudad`); inserción (`INSERT`) en `Clientes` y `Ventas`.
  * **Restricción:** No puede alterar precios (`UPDATE`) ni eliminar información comercial (`DELETE`).

* **Perfil 2 — Almacén (`rol_inventario`):**
  * **Credenciales:** Login `login_almacen` → Usuario `usr_almacen`.
  * **Permisos:** Lectura, inserción y actualización (`SELECT`, `INSERT`, `UPDATE`) únicamente sobre `Productos` (disparando los triggers de auditoría).
  * **Restricción:** Bloqueo explícito de borrado (`DENY DELETE`) en `Productos` y sin visibilidad sobre datos de `Clientes` o `Ventas`.

* **Perfil 3 — Auditoría (`rol_auditoria`):**
  * **Credenciales:** Login `login_auditor` → Usuario `usr_auditor`.
  * **Permisos:** Lectura (`SELECT`) en las tres tablas de auditoría (`AuditoriaProductos`, `AuditoriaPrecios`, `AuditoriaClientesEliminados`) y tablas operativas (`Clientes`, `Productos`, `Ventas`).
  * **Restricción:** Bloqueo total de escritura (`DENY INSERT, UPDATE, DELETE` en el esquema `dbo`) para preservar la integridad de la evidencia.

---

## 3. Código SQL y Pruebas de Validación

### Configuración de Logins, Roles, Usuarios y Permisos

```sql
USE master;
GO

-- 1. Creación de inicios de sesión (Logins) a nivel de servidor
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_vendedor')
    CREATE LOGIN login_vendedor WITH PASSWORD = 'Vendedor#2026_Secure!', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_almacen')
    CREATE LOGIN login_almacen WITH PASSWORD = 'Almacen#2026_Secure!', CHECK_POLICY = ON;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_auditor')
    CREATE LOGIN login_auditor WITH PASSWORD = 'Auditor#2026_Secure!', CHECK_POLICY = ON;
GO

USE DB_GestionComercial_EP04;
GO

-- 2. Creación de roles personalizados de base de datos
CREATE ROLE rol_ventas;
CREATE ROLE rol_inventario;
CREATE ROLE rol_auditoria;
GO

-- 3. Asignación de permisos granulares por rol
-- Rol Ventas
GRANT SELECT ON dbo.Clientes TO rol_ventas;
GRANT SELECT ON dbo.Productos TO rol_ventas;
GRANT SELECT ON dbo.Ventas TO rol_ventas;
GRANT INSERT ON dbo.Clientes TO rol_ventas;
GRANT INSERT ON dbo.Ventas TO rol_ventas;
GRANT EXECUTE ON dbo.fn_CalcularTotalConIGV TO rol_ventas;
GRANT SELECT ON dbo.fn_ReporteVentasPorCiudad TO rol_ventas;

-- Rol Inventario
GRANT SELECT, INSERT, UPDATE ON dbo.Productos TO rol_inventario;
DENY DELETE ON dbo.Productos TO rol_inventario;

-- Rol Auditoría
GRANT SELECT ON dbo.AuditoriaProductos TO rol_auditoria;
GRANT SELECT ON dbo.AuditoriaPrecios TO rol_auditoria;
GRANT SELECT ON dbo.AuditoriaClientesEliminados TO rol_auditoria;
GRANT SELECT ON dbo.Clientes TO rol_auditoria;
GRANT SELECT ON dbo.Productos TO rol_auditoria;
GRANT SELECT ON dbo.Ventas TO rol_auditoria;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_auditoria;
GO

-- 4. Creación de usuarios y asignación a sus roles
CREATE USER usr_vendedor FOR LOGIN login_vendedor;
CREATE USER usr_almacen FOR LOGIN login_almacen;
CREATE USER usr_auditor FOR LOGIN login_auditor;
GO

ALTER ROLE rol_ventas ADD MEMBER usr_vendedor;
ALTER ROLE rol_inventario ADD MEMBER usr_almacen;
ALTER ROLE rol_auditoria ADD MEMBER usr_auditor;
GO
```

- **Creación de objetos de seguridad:** Se configuraron los 3 inicios de sesión en `master`, los 3 roles en `DB_GestionComercial_EP04` y la asignación granular de permisos.

<img width="1197" height="521" alt="image" src="https://github.com/user-attachments/assets/dde65312-d5ad-4d95-ae65-e289d044b558" />

---

### Validación de Accesos mediante `EXECUTE AS USER`

```sql
USE DB_GestionComercial_EP04;
GO

-- PRUEBA 1: Perfil Vendedor (usr_vendedor)
EXECUTE AS USER = 'usr_vendedor';
    -- Permitido: consultar ventas usando la función escalar
    SELECT VentaID, dbo.fn_CalcularTotalConIGV(350.00, Cantidad) AS TotalCalculado 
    FROM dbo.Ventas;

    -- Denegado: intentar cambiar el precio de un producto (Msg 229)
    UPDATE dbo.Productos SET Precio = 10.00 WHERE ProductoID = 1;
REVERT;
GO

-- PRUEBA 2: Perfil Almacén (usr_almacen)
EXECUTE AS USER = 'usr_almacen';
    -- Permitido: actualizar stock de un producto
    UPDATE dbo.Productos SET Stock = Stock + 5 WHERE ProductoID = 1;

    -- Denegado: intentar consultar datos de clientes (Msg 229)
    SELECT * FROM dbo.Clientes;
REVERT;
GO

-- PRUEBA 3: Perfil Auditor (usr_auditor)
EXECUTE AS USER = 'usr_auditor';
    -- Permitido: revisar registros de auditoría
    SELECT * FROM dbo.AuditoriaPrecios;

    -- Denegado: intentar eliminar registros de auditoría (Msg 229)
    DELETE FROM dbo.AuditoriaPrecios;
REVERT;
GO
```

- **`usr_vendedor` (`rol_ventas`):** Ejecutó correctamente la consulta sobre `Ventas` consumiendo `dbo.fn_CalcularTotalConIGV` (retornando los 5 registros calculados), pero SQL Server bloqueó con error `Msg 229 (UPDATE permission was denied)` el intento de alterar precios en `Productos`.
- **`usr_almacen` (`rol_inventario`):** Actualizó el inventario en `Productos` sin restricciones, pero recibió bloqueo `Msg 229 (SELECT permission was denied)` al intentar consultar información personal en `Clientes`.
- **`usr_auditor` (`rol_auditoria`):** Pudo auditar las tablas de historial (`AuditoriaPrecios`), pero el motor denegó con `Msg 229 (DELETE permission was denied)` cualquier intento de borrar evidencia de auditoría.

<img width="1367" height="617" alt="image" src="https://github.com/user-attachments/assets/2b4d6704-7a5d-4400-82ef-bcd702114559" />

<img width="1380" height="666" alt="image" src="https://github.com/user-attachments/assets/3a82d4bd-3e20-41de-8940-a6121bd681be" />

---

## 4. Propósito de la Administración de Claves y Certificados en SQL Server

Dentro de la estrategia integral de seguridad de SQL Server (Sesión 13), los permisos de usuarios y roles protegen el **acceso lógico**, mientras que las **claves y certificados** protegen la **confidencialidad e integridad de los datos almacenados y en tránsito** mediante criptografía:

- **Jerarquía de cifrado de SQL Server:**
  - **Service Master Key (SMK):** Clave raíz generada automáticamente a nivel de instancia; protege las claves maestras de cada base de datos.
  - **Database Master Key (DMK):** Clave simétrica creada dentro de `DB_GestionComercial_EP04` (`CREATE MASTER KEY ENCRYPTION BY PASSWORD = ...`) que protege los certificados y claves asimétricas locales de la base de datos.
