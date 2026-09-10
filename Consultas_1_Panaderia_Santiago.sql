-- =========================================================
-- CONSULTAS DE PRUEBA - PANADERÍA SANTIAGO
-- PostgreSQL 14+
-- Ejecutar después de correr el DDL y el script de poblado completo.
-- =========================================================


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
