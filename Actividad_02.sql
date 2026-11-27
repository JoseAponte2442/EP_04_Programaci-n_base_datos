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
    INNER JOIN dbo.Productos as p on v.ProductoID = p.ProductoID
    where c.Ciudad = @Ciudad
);
go


-- PRUEBAS Y DEMOSTRACIÓN DE CONSUMO

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

-- 2. Consumo de la función de tipo tabla en la cláusula FROM (como tabla parametrizada)
select *
from dbo.fn_ReporteVentasPorCiudad('Lima')
order BY FechaVenta;
go
