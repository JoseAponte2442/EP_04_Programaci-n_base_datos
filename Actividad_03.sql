USE DB_GestionComercial_EP04;
GO

-- ============================================================================
-- ENFOQUE 01: Implementación y consumo del cursor (Recorrido fila por fila)
-- ============================================================================

DECLARE @ProductoID INT;
DECLARE @NombreProducto NVARCHAR(100);
DECLARE @Precio MONEY;
DECLARE @Stock INT;
DECLARE @EstadoInventario NVARCHAR(60);

DECLARE cur_EvaluacionStock CURSOR FAST_FORWARD FOR
SELECT
    ProductoID,
    NombreProducto,
    Precio,
    Stock
FROM dbo.Productos
ORDER BY ProductoID;

OPEN cur_EvaluacionStock;

FETCH NEXT FROM cur_EvaluacionStock
INTO @ProductoID, @NombreProducto, @Precio, @Stock;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Stock <= 10
        SET @EstadoInventario = 'ALERTA: Stock crítico - Reabastecer';
    ELSE IF @Stock <= 25
        SET @EstadoInventario = 'ATENCIÓN: Stock moderado';
    ELSE
        SET @EstadoInventario = 'ÓPTIMO: Stock suficiente';

    PRINT CONCAT(
        'ID: ', @ProductoID,
        ' | Producto: ', @NombreProducto,
        ' | Precio: S/', CAST(@Precio AS VARCHAR(20)),
        ' | Stock: ', @Stock,
        ' -> ', @EstadoInventario
    );

    FETCH NEXT FROM cur_EvaluacionStock
    INTO @ProductoID, @NombreProducto, @Precio, @Stock;
END;

CLOSE cur_EvaluacionStock;
DEALLOCATE cur_EvaluacionStock;
GO


-- ============================================================================
-- ENFOQUE 02: Alternativa comparada (Operación basada en conjuntos)
-- ============================================================================

SELECT
    p.ProductoID,
    p.NombreProducto,
    p.Precio,
    p.Stock,
    CASE
        WHEN p.Stock <= 10 THEN 'ALERTA: Stock crítico - Reabastecer'
        WHEN p.Stock <= 25 THEN 'ATENCIÓN: Stock moderado'
        ELSE 'ÓPTIMO: Stock suficiente'
    END AS EstadoInventario
FROM dbo.Productos AS p
ORDER BY p.ProductoID;
GO
