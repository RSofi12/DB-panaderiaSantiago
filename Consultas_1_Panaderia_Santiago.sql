-- =========================================================
-- CONSULTAS DE PRUEBA - PANADERÍA SANTIAGO

-- Ejecutar después de correr el DDL y el script de poblado completo.
-- =========================================================

-- consultas 1
-- 1. Listar todos los usuarios activos junto con el nombre de su rol.
-- Prueba la relación Usuario -> Rol (RBAC).
SELECT u.nombre_completo, u.nombre_usuario, r.nombre AS rol
FROM usuario u
JOIN rol r ON u.id_rol = r.id_rol
WHERE u.activo = true;


-- 2. Mostrar los 12 productos con su categoría y precio de venta actual.
-- Prueba la relación Producto -> CategoriaProducto.
SELECT p.nombre AS producto, c.nombre AS categoria, p.precio_venta
FROM producto p
JOIN categoria_producto c ON p.id_categoria = c.id_categoria
ORDER BY c.nombre, p.nombre;


-- 3. Ver el stock actual de todas las materias primas, señalando
-- cuáles están por debajo de su stock mínimo (alerta de reposición).
-- Cubre el requisito de alcance 1.7.4 (alertas de bajo stock).
SELECT nombre, unidad_medida, stock_minimo, stock_actual,
       CASE WHEN stock_actual < stock_minimo THEN 'BAJO STOCK' ELSE 'OK' END AS estado
FROM materia_prima mp
JOIN inventario_materia_prima im ON mp.id_materia_prima = im.id_materia_prima
ORDER BY estado DESC;


-- 4. Total vendido (ventas directas + pedidos entregados) por día.
-- Prueba la agregación temporal sobre la tabla Venta (reporte de ventas diarias, 1.7.7).
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS cantidad_ventas, SUM(total) AS total_vendido
FROM venta
GROUP BY DATE(fecha_hora)
ORDER BY dia;


-- 5. Ranking de los 5 productos más vendidos por cantidad total
-- (sumando ventas directas y ventas generadas por pedidos entregados).
-- Cubre el reporte "productos con mayor demanda" (1.7.7).
SELECT p.nombre, SUM(dv.cantidad) AS unidades_vendidas
FROM detalle_venta dv
JOIN producto p ON dv.id_producto = p.id_producto
GROUP BY p.nombre
ORDER BY unidades_vendidas DESC
LIMIT 5;


-- 6. Listar los pedidos que aún no han sido entregados, con el nombre
-- del cliente y de quién los está atendiendo.
-- Prueba Pedido -> Cliente y Pedido -> Usuario, filtrando por estado.
SELECT pe.id_pedido, c.nombre AS cliente, u.nombre_completo AS atendido_por,
       pe.estado, pe.fecha_entrega
FROM pedido pe
JOIN cliente c ON pe.id_cliente = c.id_cliente
JOIN usuario u ON pe.id_usuario = u.id_usuario
WHERE pe.estado <> 'entregado' AND pe.estado <> 'cancelado'
ORDER BY pe.fecha_entrega;


-- 7. Calcular cuánto se perdió en bolivianos por mermas de producto
-- terminado (NotaPerdidaProducto), agrupado por producto.
-- Es el reporte que pidió la docente: producido - vendido - perdido.
SELECT p.nombre, SUM(np.cantidad) AS unidades_perdidas,
       SUM(np.cantidad * np.costo_unitario) AS perdida_en_bs
FROM nota_perdida_producto np
JOIN detalle_produccion dp ON np.id_detalle_produccion = dp.id_detalle_produccion
JOIN producto p ON dp.id_producto = p.id_producto
GROUP BY p.nombre
ORDER BY perdida_en_bs DESC;


-- 8. Ver el historial completo de precios de compra de la harina,
-- ordenado del más reciente al más antiguo.
-- Prueba HistorialPrecioMateriaPrima y el criterio "último precio = costo vigente".
SELECT mp.nombre, hp.precio, hp.fecha_inicio
FROM historial_precio_materia_prima hp
JOIN materia_prima mp ON hp.id_materia_prima = mp.id_materia_prima
WHERE mp.nombre = 'Harina'
ORDER BY hp.fecha_inicio DESC;


-- 9. Total de ingresos (ventas) vs. total de egresos (compras, gastos
-- e inversiones) para tener una idea rápida del resultado económico.
-- Cubre el reporte de "ingresos y resultados económicos" (1.7.7).
SELECT
  (SELECT SUM(total) FROM venta) AS total_ingresos,
  (SELECT SUM(total) FROM compra) AS total_compras,
  (SELECT SUM(monto) FROM movimiento_economico) AS total_gastos_inversiones,
  (SELECT SUM(total) FROM venta)
    - (SELECT SUM(total) FROM compra)
    - (SELECT SUM(monto) FROM movimiento_economico) AS resultado_aproximado;


-- 10. Trazabilidad completa de un pedido: cliente, productos solicitados,
-- y si ya generó una venta (y con qué número de comprobante).
-- Prueba la relación opcional Pedido <-> Venta (0..1 -- 0..1).
SELECT pe.id_pedido, c.nombre AS cliente, p.nombre AS producto,
       dp.cantidad, dp.subtotal, v.numero_comprobante
FROM pedido pe
JOIN cliente c ON pe.id_cliente = c.id_cliente
JOIN detalle_pedido dp ON pe.id_pedido = dp.id_pedido
JOIN producto p ON dp.id_producto = p.id_producto
LEFT JOIN venta v ON v.id_pedido = pe.id_pedido
WHERE pe.id_pedido = 2
ORDER BY dp.id_detalle_pedido;


-- Consultas simples 2
-- ==========================================
-- 1. Productos activos ordenados por nombre
SELECT id_producto, nombre, precio_venta
FROM producto
WHERE activo = true
ORDER BY nombre;

-- 2. Pedidos con estado 'pendiente'
SELECT id_pedido, id_cliente, fecha_registro, total
FROM pedido
WHERE estado = 'pendiente';

-- 3. Clientes ordenados alfabéticamente
SELECT id_cliente, nombre, telefono
FROM cliente
ORDER BY nombre;

-- 4. Cantidad de ventas por método de pago
SELECT metodo_pago, COUNT(*) AS cantidad_ventas
FROM venta
GROUP BY metodo_pago;

--5. Materias primas con stock mínimo mayor a 5
SELECT id_materia_prima, nombre, unidad_medida, stock_minimo
FROM materia_prima
WHERE stock_minimo > 5
ORDER BY stock_minimo DESC;

-- 6. Productos con precio de venta mayor a 1
SELECT id_producto, nombre, precio_venta
FROM producto
WHERE precio_venta > 1
ORDER BY precio_venta DESC;

-- 7. Usuarios activos
SELECT id_usuario, nombre_usuario, nombre_completo
FROM usuario
WHERE activo = true;

-- 8. Total acumulado de todas las ventas
SELECT SUM(total) AS total_ventas, COUNT(*) AS cantidad_ventas
FROM venta;

-- 9. Compras con total mayor a 500
SELECT id_compra, id_proveedor, fecha_hora, total
FROM compra
WHERE total > 500
ORDER BY total DESC;

-- 10. Movimientos económicos de tipo 'gasto'
SELECT id_movimiento, concepto, monto, fecha_hora
FROM movimiento_economico
WHERE tipo = 'gasto'
ORDER BY fecha_hora;


-- =======================================
-- CONSULTAS MULTIPLES
-- =======================================
-- 1. Ventas con el nombre del usuario que las registró
SELECT v.id_venta, v.numero_comprobante, v.fecha_hora, v.total, u.nombre_completo
FROM venta v
JOIN usuario u ON u.id_usuario = v.id_usuario
ORDER BY v.fecha_hora;


-- 2. Detalle de venta con el nombre del producto vendido
SELECT dv.id_venta, p.nombre AS producto, dv.cantidad, dv.precio_unitario, dv.subtotal
FROM detalle_venta dv
JOIN producto p ON p.id_producto = dv.id_producto
ORDER BY dv.id_venta;


-- 3. Pedidos con el nombre del cliente
SELECT pe.id_pedido, c.nombre AS cliente, pe.fecha_registro, pe.estado, pe.total
FROM pedido pe
JOIN cliente c ON c.id_cliente = pe.id_cliente
ORDER BY pe.fecha_registro;


-- 4. Compras con el nombre del proveedor
SELECT co.id_compra, pr.nombre AS proveedor, co.fecha_hora, co.total
FROM compra co
JOIN proveedor pr ON pr.id_proveedor = co.id_proveedor
ORDER BY co.fecha_hora;


-- 5. Detalle de compra con el nombre de la materia prima
SELECT dc.id_compra, mp.nombre AS materia_prima, dc.cantidad, dc.precio_unitario, dc.subtotal
FROM detalle_compra dc
JOIN materia_prima mp ON mp.id_materia_prima = dc.id_materia_prima
ORDER BY dc.id_compra;

-- 6. Productos con el nombre de su categoría
SELECT p.id_producto, p.nombre AS producto, cp.nombre AS categoria, p.precio_venta
FROM producto p
JOIN categoria_producto cp ON cp.id_categoria = p.id_categoria
ORDER BY cp.nombre, p.nombre;


-- 7. Detalle de producción con el nombre del producto producido
SELECT dp.id_produccion, p.nombre AS producto, dp.cantidad_producida, dp.costo_unitario
FROM detalle_produccion dp
JOIN producto p ON p.id_producto = dp.id_producto
ORDER BY dp.id_produccion;

-- 8. Usuarios con el nombre de su rol
SELECT u.id_usuario, u.nombre_completo, r.nombre AS rol, u.activo
FROM usuario u
JOIN rol r ON r.id_rol = u.id_rol
ORDER BY r.nombre;


-- 9. Stock actual de producto terminado con el nombre del producto
SELECT ipt.id_inventario, p.nombre AS producto, ipt.stock_actual
FROM inventario_producto_terminado ipt
JOIN producto p ON p.id_producto = ipt.id_producto
ORDER BY p.nombre;

-- 10. Movimientos con el nombre del usuario que los registró
SELECT me.id_movimiento, u.nombre_completo, me.tipo, me.concepto, me.monto,          me.fecha_hora
FROM movimiento_economico me
JOIN usuario u ON u.id_usuario = me.id_usuario
ORDER BY me.fecha_hora;




-- SUBCONSULTAS 
-- =======================================

-- 1. Contar cuántos permisos tiene asignados cada rol.
SELECT  r.id_rol, r.nombre,
    (  SELECT COUNT(*) 
        FROM rol_permiso rp 
        WHERE rp.id_rol = r.id_rol
    ) AS total_permisos
FROM rol r;

-- 2. Seleccionar todos los datos de los usuarios que tengan asignado el rol de 'Administrador' o 'Propietario'.
SELECT * 
FROM usuario 
WHERE id_rol IN (
    SELECT id_rol 
    FROM rol 
    WHERE nombre IN ('Administrador', 'Propietario')
);

-- 3. Obtener la información del rol que posee el mayor identificador (id_rol) en la tabla.
SELECT * 
FROM rol 
WHERE id_rol = (
    SELECT MAX(id_rol) 
    FROM rol
);


-- 4. Utilizar una tabla derivada que cuente los permisos de cada rol para filtrar y mostrar solo los roles con más de 2 permisos asignados.
SELECT id_rol, total_permisos
FROM (
    SELECT id_rol, COUNT(id_permiso) AS total_permisos
    FROM rol_permiso
    GROUP BY id_rol
) AS resumen_roles
WHERE total_permisos > 2;


-- 5. Obtener la lista de productos cuyo precio de venta sea superior al precio promedio de todos los productos de la panadería.
SELECT * 
FROM producto 
WHERE precio_venta > (
    SELECT AVG(precio_venta) 
    FROM producto
);

-- 6. Contar cuántos productos tiene asignados cada categoría 
SELECT 
    c.id_categoria,
    c.nombre,
    (
        SELECT COUNT(*) 
        FROM producto p 
        WHERE p.id_categoria = c.id_categoria
    ) AS total_productos
FROM categoria_producto c;


-- 7. Productos que nunca se han vendido
SELECT * 
FROM producto 
WHERE id_producto NOT IN (
    SELECT DISTINCT id_producto 
    FROM detalle_venta
);

-- Resultado: Ninguno

-- 8. Obtener las ventas realizadas mediante pago QR
SELECT * 
FROM detalle_venta dv
WHERE EXISTS (
    SELECT 1 
    FROM venta v 
    WHERE v.id_venta = dv.id_venta 
      AND v.metodo_pago = 'qr'
);


-- 9. Obtener la información del producto que tiene el precio más alto de la panadería
SELECT * FROM producto 
WHERE precio_venta = (
    SELECT MAX(precio_venta) 
    FROM producto);


-- 10. Contar usuarios asignados a cada rol
SELECT r.id_rol, r.nombre,
    (
        SELECT COUNT(*) 
        FROM usuario u 
        WHERE u.id_rol = r.id_rol
    ) AS cantidad_usuarios
FROM rol r;
