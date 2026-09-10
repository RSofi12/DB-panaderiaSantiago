-- =========================================================
-- SCRIPT DE POBLADO - SISTEMA DE INFORMACIÓN WEB
-- PANADERÍA SANTIAGO
-- PostgreSQL 14+
--
-- Fuente del esquema: Base_Datos_Panaderia_Santiago_FINAL.sql
-- Fuente del alcance funcional: Perfil Proyecto SI-1 grupo 3.md, sección 1.7
-- Simulación: 4 jornadas de operación (2026-09-06, 07, 08 y 09),
--             2 eventos de compra (05-sep y reposición 09-sep),
--             14 pedidos con distintos estados.
--
-- NOTA IMPORTANTE: los valores de "hash_contrasena" son cadenas de ejemplo
-- (formato similar a bcrypt), NO son hashes reales. En producción, Django
-- genera el hash real con make_password() antes de insertar en la tabla
-- "usuario" (ver Perfil §1.7.1 - Módulo de Usuarios y Seguridad).
--
-- Ejecutar este script después de correr el DDL que crea las tablas y FK.
-- =========================================================


-- =========================================================
-- 1. MÓDULO: USUARIOS Y SEGURIDAD
-- Fuente: Perfil Proyecto SI-1 grupo 3.md §1.7.1 y §2.5 (Gente/Usuario)
-- =========================================================

INSERT INTO "rol" ("id_rol","nombre","descripcion") VALUES
(1,'Administrador','Acceso total al sistema: gestión de usuarios, roles, permisos y configuración general'),
(2,'Propietario','Supervisión general del negocio, control financiero y acceso a reportes consolidados'),
(3,'Personal de Ventas','Registro de ventas, pedidos y atención al cliente en el mostrador'),
(4,'Personal de Producción','Registro de producción diaria y consulta de materias primas disponibles');

INSERT INTO "permiso" ("id_permiso","nombre","descripcion") VALUES
(1,'gestionar_usuarios','Crear, editar, activar o inactivar usuarios del sistema'),
(2,'gestionar_productos','Registrar, editar y consultar productos y categorías'),
(3,'registrar_ventas','Registrar ventas directas por unidad'),
(4,'registrar_pedidos','Registrar y actualizar el estado de pedidos'),
(5,'registrar_produccion','Registrar cantidades producidas por jornada'),
(6,'gestionar_inventario','Consultar y ajustar existencias de materia prima y producto terminado'),
(7,'registrar_compras','Registrar compras a proveedores'),
(8,'gestionar_proveedores','Registrar y editar datos de proveedores'),
(9,'registrar_gastos','Registrar gastos e inversiones del negocio'),
(10,'generar_reportes','Consultar y generar reportes administrativos y operativos'),
(11,'consultar_bitacora','Consultar el historial de acciones registradas en el sistema');

INSERT INTO "rol_permiso" ("id_rol","id_permiso") VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,10),(1,11), -- Administrador: todos
(2,2),(2,3),(2,4),(2,6),(2,7),(2,8),(2,9),(2,10),(2,11),             -- Propietario: todo excepto gestionar usuarios
(3,3),(3,4),(3,6),(3,10),                                            -- Ventas: ventas, pedidos, consulta inventario, reportes de venta
(4,5),(4,6);                                                         -- Producción: producción y consulta de inventario

-- Usuarios: Carlos Santiago Vargas (Propietario) y Miguel Ángel Rojas (Producción)
-- corresponden a los entrevistados reales en el Perfil (Entrevista #1 y #2).
INSERT INTO "usuario" ("id_usuario","id_rol","nombre_usuario","hash_contrasena","nombre_completo","email","activo") VALUES
(1,1,'admin','$2b$12$demoHashAdmin0000000000000000000000000000000000000','Soporte Técnico del Sistema','admin@panaderiasantiago.com',true),
(2,2,'csantiago','$2b$12$demoHashPropietario000000000000000000000000000000','Carlos Santiago Vargas','csantiago@panaderiasantiago.com',true),
(3,3,'mgonzales','$2b$12$demoHashVentas100000000000000000000000000000000000','María Elena Gonzales Pérez','mgonzales@panaderiasantiago.com',true),
(4,3,'jrivera','$2b$12$demoHashVentas200000000000000000000000000000000000','Juana Rivera Quiroga','jrivera@panaderiasantiago.com',true),
(5,4,'mrojas','$2b$12$demoHashProduccion10000000000000000000000000000000','Miguel Ángel Rojas','mrojas@panaderiasantiago.com',true),
(6,4,'ptorrez','$2b$12$demoHashProduccion20000000000000000000000000000000','Pedro Torrez Salvatierra','ptorrez@panaderiasantiago.com',true);


-- =========================================================
-- 2. MÓDULO: PRODUCTOS
-- Fuente: Perfil §1.7.2 y lista de panes de Introducción/Antecedentes
-- 7 categorías agrupando los 12 panes mencionados en el perfil.
-- =========================================================

INSERT INTO "categoria_producto" ("id_categoria","nombre","descripcion") VALUES
(1,'Panes Tradicionales','Panes clásicos de consumo diario (marraqueta, casero, tortilla)'),
(2,'Panes Regionales','Variedades típicas de la región cruceña (arani, chama)'),
(3,'Panes Integrales','Panes elaborados con harina integral'),
(4,'Panes Dulces','Panes con un toque dulce o azucarado'),
(5,'Panes Rellenos','Panes con relleno, como el gusanito'),
(6,'Panecillos Pequeños','Panes de tamaño reducido (mollete, galleta)'),
(7,'Panes de Leche','Panes elaborados con mayor proporción de leche');

-- costo_produccion y precio_venta en Bs. precio_sugerido = precio_venta inicial
-- (aún no hay cambio de precio de materia prima que dispare un recálculo).
INSERT INTO "producto" ("id_producto","id_categoria","nombre","descripcion","costo_produccion","porcentaje_ganancia","precio_sugerido","precio_venta","fecha_registro","activo") VALUES
(1, 1,'Marraqueta','Pan tradicional cruceño de corteza crujiente',0.40,50.00,0.60,0.60,'2026-08-01 08:00:00',true),
(2, 1,'Casero','Pan casero de miga suave',0.45,55.00,0.70,0.70,'2026-08-01 08:00:00',true),
(3, 1,'Tortilla','Pan tipo tortilla de mayor tamaño',1.20,45.00,1.75,1.75,'2026-08-01 08:00:00',true),
(4, 2,'Arani','Pan regional de sabor característico',0.50,60.00,0.80,0.80,'2026-08-01 08:00:00',true),
(5, 2,'Chama','Pan regional dulce suave',0.55,60.00,0.90,0.90,'2026-08-01 08:00:00',true),
(6, 3,'Integral','Pan elaborado con harina integral',0.60,50.00,0.90,0.90,'2026-08-01 08:00:00',true),
(7, 4,'Pan Dulce','Pan con azúcar, huevo y mantequilla',0.70,55.00,1.10,1.10,'2026-08-01 08:00:00',true),
(8, 4,'Pan con Azúcar','Pan espolvoreado con azúcar',0.65,55.00,1.00,1.00,'2026-08-01 08:00:00',true),
(9, 5,'Gusanito','Pan relleno tipo gusanito',1.00,50.00,1.50,1.50,'2026-08-01 08:00:00',true),
(10,6,'Pan Mollete','Panecillo pequeño suave',0.40,50.00,0.60,0.60,'2026-08-01 08:00:00',true),
(11,6,'Pan Galleta','Panecillo pequeño crocante',0.35,45.00,0.50,0.50,'2026-08-01 08:00:00',true),
(12,7,'Pan de Leche','Pan suave con alto contenido de leche',0.80,55.00,1.25,1.25,'2026-08-01 08:00:00',true);

-- Recetas (BOM / MRP): cantidad de materia prima requerida por unidad de producto.
-- Fuente: Antecedentes (harina, azúcar, levadura, sal, huevos, leche, mantequilla)
-- + Perfil §1.7.4 (descuento automático de materia prima según lo producido).
-- materia_prima: 1=harina 2=azúcar 3=levadura 4=sal 5=huevos 6=leche 7=mantequilla
INSERT INTO "producto_materia_prima" ("id_producto","id_materia_prima","cantidad_requerida","unidad_medida") VALUES
(1,1,0.060,'kg'),(1,3,0.002,'kg'),(1,4,0.001,'kg'),
(2,1,0.070,'kg'),(2,3,0.002,'kg'),(2,4,0.001,'kg'),
(3,1,0.150,'kg'),(3,3,0.003,'kg'),(3,4,0.002,'kg'),(3,6,0.020,'litro'),
(4,1,0.080,'kg'),(4,3,0.002,'kg'),(4,2,0.010,'kg'),
(5,1,0.080,'kg'),(5,3,0.002,'kg'),(5,2,0.015,'kg'),
(6,1,0.070,'kg'),(6,3,0.002,'kg'),(6,4,0.001,'kg'),
(7,1,0.060,'kg'),(7,2,0.020,'kg'),(7,5,0.050,'unidad'),(7,7,0.010,'kg'),
(8,1,0.060,'kg'),(8,2,0.025,'kg'),
(9,1,0.090,'kg'),(9,2,0.020,'kg'),(9,7,0.015,'kg'),
(10,1,0.050,'kg'),(10,2,0.010,'kg'),(10,6,0.010,'litro'),
(11,1,0.040,'kg'),(11,2,0.010,'kg'),
(12,1,0.060,'kg'),(12,6,0.030,'litro'),(12,2,0.015,'kg'),(12,7,0.010,'kg');

INSERT INTO "historial_precio_producto" ("id_historial","id_producto","precio","fecha_inicio") VALUES
(1,1,0.60,'2026-08-01 08:00:00'),(2,2,0.70,'2026-08-01 08:00:00'),(3,3,1.75,'2026-08-01 08:00:00'),
(4,4,0.80,'2026-08-01 08:00:00'),(5,5,0.90,'2026-08-01 08:00:00'),(6,6,0.90,'2026-08-01 08:00:00'),
(7,7,1.10,'2026-08-01 08:00:00'),(8,8,1.00,'2026-08-01 08:00:00'),(9,9,1.50,'2026-08-01 08:00:00'),
(10,10,0.60,'2026-08-01 08:00:00'),(11,11,0.50,'2026-08-01 08:00:00'),(12,12,1.25,'2026-08-01 08:00:00');


-- =========================================================
-- 3. CLIENTES (para pedidos)
-- Fuente: Perfil §1.7.3 (registro de pedidos con datos del cliente)
-- =========================================================

INSERT INTO "cliente" ("id_cliente","nombre","telefono","direccion") VALUES
(1,'Rosa Fernández Choque','70011122','Av. Banzer, 3er anillo'),
(2,'Hotel Cortez','33421100','Av. Cristo Redentor, 3er anillo'),
(3,'Juan Pablo Áñez Rocha','70055443','Calle Beni, casi 2do anillo'),
(4,'Colegio San Ignacio','33450099','Av. Alemana, 4to anillo'),
(5,'Marcela Suárez Vaca','70099887','Barrio Urbari, 2do anillo'),
(6,'Restaurante El Aljibe','33500221','Av. San Martín, 2do anillo');


-- =========================================================
-- 4. MÓDULO: INVENTARIO DE MATERIA PRIMA
-- Fuente: Perfil §1.7.4 y Antecedentes (harina, azúcar, levadura, sal,
--         huevos, leche, mantequilla)
-- =========================================================

INSERT INTO "materia_prima" ("id_materia_prima","nombre","unidad_medida","stock_minimo","fecha_registro","activo") VALUES
(1,'Harina','kg',20.000,'2026-08-01 08:00:00',true),
(2,'Azúcar','kg',10.000,'2026-08-01 08:00:00',true),
(3,'Levadura','kg',2.000,'2026-08-01 08:00:00',true),
(4,'Sal','kg',3.000,'2026-08-01 08:00:00',true),
(5,'Huevos','unidad',100.000,'2026-08-01 08:00:00',true),
(6,'Leche','litro',15.000,'2026-08-01 08:00:00',true),
(7,'Mantequilla','kg',5.000,'2026-08-01 08:00:00',true);

INSERT INTO "historial_precio_materia_prima" ("id_historial","id_materia_prima","precio","fecha_inicio") VALUES
(1,1,4.50,'2026-08-01 08:00:00'),
(2,2,6.00,'2026-08-01 08:00:00'),
(3,3,45.00,'2026-08-01 08:00:00'),
(4,4,3.00,'2026-08-01 08:00:00'),
(5,5,0.90,'2026-08-01 08:00:00'),
(6,6,7.50,'2026-08-01 08:00:00'),
(7,7,35.00,'2026-08-01 08:00:00');


-- =========================================================
-- 5. MÓDULO: COMPRAS, PROVEEDORES Y GASTOS (compra inicial, 05-sep)
-- Fuente: Perfil §1.7.6
-- =========================================================

INSERT INTO "proveedor" ("id_proveedor","nombre","telefono","direccion","fecha_registro","activo") VALUES
(1,'Molinos del Oriente S.R.L.','33210099','Parque Industrial, Santa Cruz','2026-07-15 10:00:00',true),
(2,'Distribuidora Lácteos Santa Cruz','33220188','Av. Grigotá, 6to anillo','2026-07-15 10:00:00',true),
(3,'Insumos y Levaduras Bolivia','33230277','Av. Piraí, 4to anillo','2026-07-15 10:00:00',true);

INSERT INTO "compra" ("id_compra","id_proveedor","id_usuario","fecha_hora","total") VALUES
(1,1,2,'2026-09-05 09:00:00',1260.00), -- harina, sal, azúcar
(2,2,2,'2026-09-05 10:30:00',1245.00), -- leche, mantequilla, huevos
(3,3,2,'2026-09-05 11:15:00',450.00);  -- levadura

INSERT INTO "detalle_compra" ("id_detalle_compra","id_compra","id_materia_prima","cantidad","precio_unitario","subtotal") VALUES
(1,1,1,200.000,4.50,900.00),  -- harina
(2,1,4,20.000,3.00,60.00),    -- sal
(3,1,2,50.000,6.00,300.00),   -- azúcar
(4,2,6,60.000,7.50,450.00),   -- leche
(5,2,7,15.000,35.00,525.00),  -- mantequilla
(6,2,5,300.000,0.90,270.00),  -- huevos
(7,3,3,10.000,45.00,450.00);  -- levadura

-- Movimientos de entrada al inventario de materia prima generados por cada compra
INSERT INTO "movimiento_materia_prima" ("id_movimiento","id_inventario","id_compra","id_produccion","fecha_hora","tipo","cantidad") VALUES
(1,1,1,NULL,'2026-09-05 09:00:00','entrada',200.000),
(2,4,1,NULL,'2026-09-05 09:00:00','entrada',20.000),
(3,2,1,NULL,'2026-09-05 09:00:00','entrada',50.000),
(4,6,2,NULL,'2026-09-05 10:30:00','entrada',60.000),
(5,7,2,NULL,'2026-09-05 10:30:00','entrada',15.000),
(6,5,2,NULL,'2026-09-05 10:30:00','entrada',300.000),
(7,3,3,NULL,'2026-09-05 11:15:00','entrada',10.000);

-- Gastos e inversiones que NO corresponden a compra de materia prima
INSERT INTO "movimiento_economico" ("id_movimiento","id_usuario","tipo","concepto","descripcion","monto","fecha_hora") VALUES
(1,2,'gasto','Alquiler del local','Pago mensual de alquiler del establecimiento',1500.00,'2026-09-06 08:00:00'),
(2,2,'inversion','Compra de horno industrial','Nuevo horno para incrementar capacidad de producción',8000.00,'2026-09-06 09:00:00'),
(3,2,'gasto','Energía eléctrica','Pago de factura de luz del mes',350.00,'2026-09-07 08:00:00'),
(4,2,'gasto','Agua potable','Pago de factura de agua del mes',120.00,'2026-09-07 08:15:00'),
(5,2,'gasto','Mantenimiento de horno','Servicio técnico preventivo de hornos existentes',200.00,'2026-09-08 08:00:00');


-- =========================================================
-- 6. MÓDULO: PRODUCCIÓN Y COMERCIALIZACIÓN - PRODUCCIÓN (días 1-3)
-- Fuente: Perfil §1.7.3 (registro de producción por jornada)
-- =========================================================

INSERT INTO "produccion" ("id_produccion","id_usuario","fecha","jornada") VALUES
(1,5,'2026-09-06','única'),
(2,5,'2026-09-07','única'),
(3,6,'2026-09-08','única');

-- Cantidades producidas por producto y por día (constantes en el ejemplo):
-- Marraqueta 200, Casero 100, Tortilla 30, Arani 80, Chama 60, Integral 50,
-- Pan Dulce 60, Pan con Azúcar 50, Gusanito 40, Mollete 70, Galleta 90, Pan de Leche 40
INSERT INTO "detalle_produccion" ("id_detalle_produccion","id_produccion","id_producto","cantidad_producida","costo_unitario") VALUES
-- Día 1 (2026-09-06)
(1,1,1,200,0.40),(2,1,2,100,0.45),(3,1,3,30,1.20),(4,1,4,80,0.50),
(5,1,5,60,0.55),(6,1,6,50,0.60),(7,1,7,60,0.70),(8,1,8,50,0.65),
(9,1,9,40,1.00),(10,1,10,70,0.40),(11,1,11,90,0.35),(12,1,12,40,0.80),
-- Día 2 (2026-09-07)
(13,2,1,200,0.40),(14,2,2,100,0.45),(15,2,3,30,1.20),(16,2,4,80,0.50),
(17,2,5,60,0.55),(18,2,6,50,0.60),(19,2,7,60,0.70),(20,2,8,50,0.65),
(21,2,9,40,1.00),(22,2,10,70,0.40),(23,2,11,90,0.35),(24,2,12,40,0.80),
-- Día 3 (2026-09-08)
(25,3,1,200,0.40),(26,3,2,100,0.45),(27,3,3,30,1.20),(28,3,4,80,0.50),
(29,3,5,60,0.55),(30,3,6,50,0.60),(31,3,7,60,0.70),(32,3,8,50,0.65),
(33,3,9,40,1.00),(34,3,10,70,0.40),(35,3,11,90,0.35),(36,3,12,40,0.80);

-- Mermas de producción (días 1 y 2)
INSERT INTO "nota_perdida_producto" ("id_nota_perdida","id_detalle_produccion","id_usuario","cantidad","costo_unitario","fecha_salida") VALUES
(1,13,5,5,0.40,'2026-09-07 20:00:00'), -- 5 Marraquetas dañadas el día 2
(2,7,5,3,0.70,'2026-09-06 20:00:00');  -- 3 Panes Dulces dañados el día 1

-- Movimientos de salida de materia prima por consumo de producción (días 1-3)
INSERT INTO "movimiento_materia_prima" ("id_movimiento","id_inventario","id_compra","id_produccion","fecha_hora","tipo","cantidad") VALUES
(8, 1,NULL,1,'2026-09-06 20:00:00','salida',57.900),
(9, 2,NULL,1,'2026-09-06 20:00:00','salida',7.150),
(10,3,NULL,1,'2026-09-06 20:00:00','salida',1.070),
(11,4,NULL,1,'2026-09-06 20:00:00','salida',0.410),
(12,5,NULL,1,'2026-09-06 20:00:00','salida',3.000),
(13,6,NULL,1,'2026-09-06 20:00:00','salida',2.500),
(14,7,NULL,1,'2026-09-06 20:00:00','salida',1.600),
(15,1,NULL,2,'2026-09-07 20:00:00','salida',57.900),
(16,2,NULL,2,'2026-09-07 20:00:00','salida',7.150),
(17,3,NULL,2,'2026-09-07 20:00:00','salida',1.070),
(18,4,NULL,2,'2026-09-07 20:00:00','salida',0.410),
(19,5,NULL,2,'2026-09-07 20:00:00','salida',3.000),
(20,6,NULL,2,'2026-09-07 20:00:00','salida',2.500),
(21,7,NULL,2,'2026-09-07 20:00:00','salida',1.600),
(22,1,NULL,3,'2026-09-08 20:00:00','salida',57.900),
(23,2,NULL,3,'2026-09-08 20:00:00','salida',7.150),
(24,3,NULL,3,'2026-09-08 20:00:00','salida',1.070),
(25,4,NULL,3,'2026-09-08 20:00:00','salida',0.410),
(26,5,NULL,3,'2026-09-08 20:00:00','salida',3.000),
(27,6,NULL,3,'2026-09-08 20:00:00','salida',2.500),
(28,7,NULL,3,'2026-09-08 20:00:00','salida',1.600);


-- =========================================================
-- 7. MÓDULO: INVENTARIO DE PRODUCTOS TERMINADOS - entradas por producción (días 1-3)
-- Fuente: Perfil §1.7.5
-- =========================================================

-- Movimientos de entrada por producción (36 = 12 productos x 3 días)
INSERT INTO "movimiento_producto_terminado" ("id_movimiento","id_inventario","id_produccion","id_venta","id_pedido","id_nota_perdida","fecha_hora","tipo","cantidad") VALUES
-- Día 1
(1, 1,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',200),(2, 2,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',100),
(3, 3,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',30), (4, 4,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',80),
(5, 5,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',60), (6, 6,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',50),
(7, 7,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',60), (8, 8,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',50),
(9, 9,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',40), (10,10,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',70),
(11,11,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',90),(12,12,1,NULL,NULL,NULL,'2026-09-06 06:00:00','entrada',40),
-- Día 2
(13,1,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',200),(14,2,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',100),
(15,3,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',30), (16,4,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',80),
(17,5,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',60), (18,6,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',50),
(19,7,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',60), (20,8,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',50),
(21,9,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',40), (22,10,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',70),
(23,11,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',90),(24,12,2,NULL,NULL,NULL,'2026-09-07 06:00:00','entrada',40),
-- Día 3
(25,1,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',200),(26,2,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',100),
(27,3,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',30), (28,4,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',80),
(29,5,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',60), (30,6,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',50),
(31,7,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',60), (32,8,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',50),
(33,9,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',40), (34,10,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',70),
(35,11,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',90),(36,12,3,NULL,NULL,NULL,'2026-09-08 06:00:00','entrada',40);


-- =========================================================
-- 8. MÓDULO: PRODUCCIÓN Y COMERCIALIZACIÓN - PEDIDOS (días 1-3: #1 a #10)
-- Fuente: Perfil §1.7.3 y §2.4 (estados: pendiente, en_preparacion, listo,
--         entregado, cancelado)
-- =========================================================

INSERT INTO "pedido" ("id_pedido","id_cliente","id_usuario","fecha_registro","fecha_entrega","estado","metodo_pago","total") VALUES
(1, 1,3,'2026-09-06 08:00:00','2026-09-06 18:00:00','entregado','efectivo',23.50),
(2, 2,4,'2026-09-06 09:30:00','2026-09-07 07:00:00','entregado','qr',95.00),
(3, 3,3,'2026-09-06 15:00:00','2026-09-08 09:00:00','en_preparacion','efectivo',35.00),
(4, 4,4,'2026-09-06 16:20:00','2026-09-09 07:00:00','pendiente','qr',110.00),
(5, 5,3,'2026-09-07 10:00:00','2026-09-07 19:00:00','entregado','efectivo',30.00),
(6, 6,4,'2026-09-07 11:15:00','2026-09-08 08:00:00','listo','qr',51.00),
(7, 1,3,'2026-09-07 14:45:00','2026-09-08 17:00:00','en_preparacion','efectivo',18.00),
(8, 3,4,'2026-09-08 08:30:00','2026-09-08 20:00:00','pendiente','qr',18.75),
(9, 5,3,'2026-09-08 09:45:00','2026-09-08 12:00:00','entregado','efectivo',29.00),
(10,2,4,'2026-09-08 10:10:00','2026-09-09 07:00:00','cancelado',NULL,35.00);

INSERT INTO "detalle_pedido" ("id_detalle_pedido","id_pedido","id_producto","cantidad","precio_unitario","subtotal") VALUES
(1, 1,12,10,1.25,12.50),(2, 1,7,10,1.10,11.00),           -- P1: Pan de Leche, Pan Dulce
(3, 2,1,100,0.60,60.00),(4, 2,2,50,0.70,35.00),           -- P2: Marraqueta, Casero
(5, 3,3,20,1.75,35.00),                                    -- P3: Tortilla
(6, 4,10,100,0.60,60.00),(7, 4,11,100,0.50,50.00),        -- P4: Mollete, Galleta
(8, 5,8,15,1.00,15.00),(9, 5,9,10,1.50,15.00),            -- P5: Pan con Azúcar, Gusanito
(10,6,5,30,0.90,27.00),(11,6,4,30,0.80,24.00),            -- P6: Chama, Arani
(12,7,6,20,0.90,18.00),                                    -- P7: Integral
(13,8,12,15,1.25,18.75),                                   -- P8: Pan de Leche
(14,9,1,30,0.60,18.00),(15,9,7,10,1.10,11.00),            -- P9: Marraqueta, Pan Dulce
(16,10,2,50,0.70,35.00);                                   -- P10: Casero (cancelado)


-- =========================================================
-- 9. MÓDULO: PRODUCCIÓN Y COMERCIALIZACIÓN - VENTAS (días 1-3: #1 a #13)
-- Fuente: Perfil §1.7.3
-- =========================================================

INSERT INTO "venta" ("id_venta","id_pedido","id_usuario","numero_comprobante","fecha_hora","metodo_pago","id_transaccion_stripe","total") VALUES
(1, NULL,3,100001,'2026-09-06 09:15:00','efectivo',NULL,17.00),
(2, NULL,4,100002,'2026-09-06 12:40:00','qr','pi_3P8xQR000002',11.10),
(3, NULL,3,100003,'2026-09-06 17:50:00','efectivo',NULL,18.40),
(4, NULL,4,100004,'2026-09-07 09:20:00','qr','pi_3P8xQR000004',20.25),
(5, NULL,3,100005,'2026-09-07 13:10:00','efectivo',NULL,19.80),
(6, NULL,4,100006,'2026-09-07 18:05:00','qr','pi_3P8xQR000006',22.00),
(7, NULL,3,100007,'2026-09-08 09:05:00','efectivo',NULL,17.80),
(8, NULL,4,100008,'2026-09-08 12:30:00','qr','pi_3P8xQR000008',14.50),
(9, NULL,3,100009,'2026-09-08 17:40:00','efectivo',NULL,13.90),
(10,1,   3,100010,'2026-09-06 18:00:00','efectivo',NULL,23.50),
(11,2,   4,100011,'2026-09-07 07:00:00','qr','pi_3P8xQR000011',95.00),
(12,5,   3,100012,'2026-09-07 19:00:00','efectivo',NULL,30.00),
(13,9,   3,100013,'2026-09-08 12:00:00','efectivo',NULL,29.00);

INSERT INTO "detalle_venta" ("id_detalle_venta","id_venta","id_producto","cantidad","precio_unitario","subtotal") VALUES
(1, 1,1,20,0.60,12.00),(2, 1,11,10,0.50,5.00),
(3, 2,2,8,0.70,5.60),  (4, 2,7,5,1.10,5.50),
(5, 3,4,10,0.80,8.00), (6, 3,6,6,0.90,5.40),  (7, 3,12,4,1.25,5.00),
(8, 4,1,25,0.60,15.00),(9, 4,3,3,1.75,5.25),
(10,5,5,12,0.90,10.80),(11,5,10,15,0.60,9.00),
(12,6,9,8,1.50,12.00), (13,6,8,10,1.00,10.00),
(14,7,1,18,0.60,10.80),(15,7,2,10,0.70,7.00),
(16,8,11,20,0.50,10.00),(17,8,6,5,0.90,4.50),
(18,9,12,6,1.25,7.50), (19,9,4,8,0.80,6.40),
(20,10,12,10,1.25,12.50),(21,10,7,10,1.10,11.00),   -- proviene del Pedido 1
(22,11,1,100,0.60,60.00),(23,11,2,50,0.70,35.00),   -- proviene del Pedido 2
(24,12,8,15,1.00,15.00),(25,12,9,10,1.50,15.00),    -- proviene del Pedido 5
(26,13,1,30,0.60,18.00),(27,13,7,10,1.10,11.00);    -- proviene del Pedido 9

-- Movimientos de salida del inventario de producto terminado generados por cada venta
INSERT INTO "movimiento_producto_terminado" ("id_movimiento","id_inventario","id_produccion","id_venta","id_pedido","id_nota_perdida","fecha_hora","tipo","cantidad") VALUES
(37,1, NULL,1, NULL,NULL,'2026-09-06 09:15:00','salida',20),
(38,11,NULL,1, NULL,NULL,'2026-09-06 09:15:00','salida',10),
(39,2, NULL,2, NULL,NULL,'2026-09-06 12:40:00','salida',8),
(40,7, NULL,2, NULL,NULL,'2026-09-06 12:40:00','salida',5),
(41,4, NULL,3, NULL,NULL,'2026-09-06 17:50:00','salida',10),
(42,6, NULL,3, NULL,NULL,'2026-09-06 17:50:00','salida',6),
(43,12,NULL,3, NULL,NULL,'2026-09-06 17:50:00','salida',4),
(44,1, NULL,4, NULL,NULL,'2026-09-07 09:20:00','salida',25),
(45,3, NULL,4, NULL,NULL,'2026-09-07 09:20:00','salida',3),
(46,5, NULL,5, NULL,NULL,'2026-09-07 13:10:00','salida',12),
(47,10,NULL,5, NULL,NULL,'2026-09-07 13:10:00','salida',15),
(48,9, NULL,6, NULL,NULL,'2026-09-07 18:05:00','salida',8),
(49,8, NULL,6, NULL,NULL,'2026-09-07 18:05:00','salida',10),
(50,1, NULL,7, NULL,NULL,'2026-09-08 09:05:00','salida',18),
(51,2, NULL,7, NULL,NULL,'2026-09-08 09:05:00','salida',10),
(52,11,NULL,8, NULL,NULL,'2026-09-08 12:30:00','salida',20),
(53,6, NULL,8, NULL,NULL,'2026-09-08 12:30:00','salida',5),
(54,12,NULL,9, NULL,NULL,'2026-09-08 17:40:00','salida',6),
(55,4, NULL,9, NULL,NULL,'2026-09-08 17:40:00','salida',8),
(56,12,NULL,10,1,   NULL,'2026-09-06 18:00:00','salida',10),
(57,7, NULL,10,1,   NULL,'2026-09-06 18:00:00','salida',10),
(58,1, NULL,11,2,   NULL,'2026-09-07 07:00:00','salida',100),
(59,2, NULL,11,2,   NULL,'2026-09-07 07:00:00','salida',50),
(60,8, NULL,12,5,   NULL,'2026-09-07 19:00:00','salida',15),
(61,9, NULL,12,5,   NULL,'2026-09-07 19:00:00','salida',10),
(62,1, NULL,13,9,   NULL,'2026-09-08 12:00:00','salida',30),
(63,7, NULL,13,9,   NULL,'2026-09-08 12:00:00','salida',10);

-- Movimientos de salida por merma (nota de pérdida de producto, días 1-2)
INSERT INTO "movimiento_producto_terminado" ("id_movimiento","id_inventario","id_produccion","id_venta","id_pedido","id_nota_perdida","fecha_hora","tipo","cantidad") VALUES
(64,1,NULL,NULL,NULL,1,'2026-09-07 20:00:00','salida',5),
(65,7,NULL,NULL,NULL,2,'2026-09-06 20:00:00','salida',3);


-- =========================================================
-- 10. DÍA 4 (2026-09-09): REPOSICIÓN DE HARINA
-- El stock de harina tras el día 3 (26.300 kg) no alcanza para una
-- jornada completa (requiere 57.900 kg); se repone al mismo proveedor
-- y precio, sin variación cambiaria.
-- =========================================================

INSERT INTO "compra" ("id_compra","id_proveedor","id_usuario","fecha_hora","total") VALUES
(4,1,2,'2026-09-09 07:00:00',225.00);

INSERT INTO "detalle_compra" ("id_detalle_compra","id_compra","id_materia_prima","cantidad","precio_unitario","subtotal") VALUES
(8,4,1,50.000,4.50,225.00);

INSERT INTO "movimiento_materia_prima" ("id_movimiento","id_inventario","id_compra","id_produccion","fecha_hora","tipo","cantidad") VALUES
(29,1,4,NULL,'2026-09-09 07:00:00','entrada',50.000);


-- =========================================================
-- 11. DÍA 4: JORNADA DE PRODUCCIÓN
-- Misma composición de productos que los días anteriores, garantizando
-- pan fresco disponible durante toda la jornada.
-- =========================================================

INSERT INTO "produccion" ("id_produccion","id_usuario","fecha","jornada") VALUES
(4,6,'2026-09-09','única');

INSERT INTO "detalle_produccion" ("id_detalle_produccion","id_produccion","id_producto","cantidad_producida","costo_unitario") VALUES
(37,4,1,200,0.40),(38,4,2,100,0.45),(39,4,3,30,1.20),(40,4,4,80,0.50),
(41,4,5,60,0.55),(42,4,6,50,0.60),(43,4,7,60,0.70),(44,4,8,50,0.65),
(45,4,9,40,1.00),(46,4,10,70,0.40),(47,4,11,90,0.35),(48,4,12,40,0.80);

-- Consumo de materia prima de la jornada (idéntico al de días anteriores)
INSERT INTO "movimiento_materia_prima" ("id_movimiento","id_inventario","id_compra","id_produccion","fecha_hora","tipo","cantidad") VALUES
(30,1,NULL,4,'2026-09-09 20:00:00','salida',57.900),
(31,2,NULL,4,'2026-09-09 20:00:00','salida',7.150),
(32,3,NULL,4,'2026-09-09 20:00:00','salida',1.070),
(33,4,NULL,4,'2026-09-09 20:00:00','salida',0.410),
(34,5,NULL,4,'2026-09-09 20:00:00','salida',3.000),
(35,6,NULL,4,'2026-09-09 20:00:00','salida',2.500),
(36,7,NULL,4,'2026-09-09 20:00:00','salida',1.600);

-- Entradas al inventario de producto terminado generadas por esta producción
INSERT INTO "movimiento_producto_terminado" ("id_movimiento","id_inventario","id_produccion","id_venta","id_pedido","id_nota_perdida","fecha_hora","tipo","cantidad") VALUES
(66,1, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',200),
(67,2, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',100),
(68,3, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',30),
(69,4, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',80),
(70,5, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',60),
(71,6, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',50),
(72,7, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',60),
(73,8, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',50),
(74,9, 4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',40),
(75,10,4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',70),
(76,11,4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',90),
(77,12,4,NULL,NULL,NULL,'2026-09-09 06:00:00','entrada',40);


-- =========================================================
-- 12. DÍA 4: PEDIDOS #11 A #14
-- =========================================================

INSERT INTO "pedido" ("id_pedido","id_cliente","id_usuario","fecha_registro","fecha_entrega","estado","metodo_pago","total") VALUES
(11,6,3,'2026-09-09 08:15:00','2026-09-09 18:00:00','entregado','qr',32.00),
(12,4,4,'2026-09-09 09:00:00','2026-09-10 07:00:00','pendiente','qr',88.00),
(13,1,3,'2026-09-09 11:30:00','2026-09-09 17:00:00','entregado','efectivo',31.50),
(14,2,4,'2026-09-09 14:00:00','2026-09-10 07:00:00','en_preparacion','qr',114.00);

INSERT INTO "detalle_pedido" ("id_detalle_pedido","id_pedido","id_producto","cantidad","precio_unitario","subtotal") VALUES
(17,11,1,30,0.60,18.00),(18,11,2,20,0.70,14.00),      -- P11: Marraqueta, Casero
(19,12,10,80,0.60,48.00),(20,12,11,80,0.50,40.00),    -- P12: Mollete, Galleta
(21,13,7,15,1.10,16.50),(22,13,9,10,1.50,15.00),      -- P13: Pan Dulce, Gusanito
(23,14,1,120,0.60,72.00),(24,14,2,60,0.70,42.00);     -- P14: Marraqueta, Casero


-- =========================================================
-- 13. DÍA 4: VENTAS GENERADAS POR LA ENTREGA DE LOS PEDIDOS #11 Y #13
-- =========================================================

INSERT INTO "venta" ("id_venta","id_pedido","id_usuario","numero_comprobante","fecha_hora","metodo_pago","id_transaccion_stripe","total") VALUES
(14,11,3,100014,'2026-09-09 18:00:00','qr','pi_3P8xQR000014',32.00),
(15,13,3,100015,'2026-09-09 17:00:00','efectivo',NULL,31.50);

INSERT INTO "detalle_venta" ("id_detalle_venta","id_venta","id_producto","cantidad","precio_unitario","subtotal") VALUES
(28,14,1,30,0.60,18.00),(29,14,2,20,0.70,14.00),   -- proviene del Pedido 11
(30,15,7,15,1.10,16.50),(31,15,9,10,1.50,15.00);   -- proviene del Pedido 13

-- Movimientos de salida de producto terminado generados por estas ventas
INSERT INTO "movimiento_producto_terminado" ("id_movimiento","id_inventario","id_produccion","id_venta","id_pedido","id_nota_perdida","fecha_hora","tipo","cantidad") VALUES
(78,1,NULL,14,11,NULL,'2026-09-09 18:00:00','salida',30),
(79,2,NULL,14,11,NULL,'2026-09-09 18:00:00','salida',20),
(80,7,NULL,15,13,NULL,'2026-09-09 17:00:00','salida',15),
(81,9,NULL,15,13,NULL,'2026-09-09 17:00:00','salida',10);
-- Los pedidos #12 y #14 quedan pendiente/en_preparacion: no generan venta
-- ni movimiento de inventario todavía.


-- =========================================================
-- 14. DÍA 4: PÉRDIDA LEVE (2 unidades de Casero)
-- =========================================================

INSERT INTO "nota_perdida_producto" ("id_nota_perdida","id_detalle_produccion","id_usuario","cantidad","costo_unitario","fecha_salida") VALUES
(3,38,6,2,0.45,'2026-09-09 20:30:00');

INSERT INTO "movimiento_producto_terminado" ("id_movimiento","id_inventario","id_produccion","id_venta","id_pedido","id_nota_perdida","fecha_hora","tipo","cantidad") VALUES
(82,2,NULL,NULL,NULL,3,'2026-09-09 20:30:00','salida',2);


-- =========================================================
-- 15. STOCK FINAL (materia prima y producto terminado) TRAS LOS 4 DÍAS
-- =========================================================

INSERT INTO "inventario_materia_prima" ("id_inventario","id_materia_prima","stock_actual") VALUES
(1,1,18.400),  -- harina: 200(compra)+50(reposición)-57.9x4(consumo)
(2,2,21.400),  -- azúcar: 50-7.15x4
(3,3,5.720),   -- levadura: 10-1.07x4
(4,4,18.360),  -- sal: 20-0.41x4
(5,5,288.000), -- huevos: 300-3x4
(6,6,50.000),  -- leche: 60-2.5x4
(7,7,8.600);   -- mantequilla: 15-1.6x4

INSERT INTO "inventario_producto_terminado" ("id_inventario","id_producto","stock_actual") VALUES
(1, 1,572),  -- Marraqueta: 800 producidas - 198(ventas/pedidos días1-3) - 30(P11)
(2, 2,310),  -- Casero: 400 - 68 - 20 - 2(merma)
(3, 3,117),  -- Tortilla: 120 - 3
(4, 4,302),  -- Arani: 320 - 18
(5, 5,228),  -- Chama: 240 - 12
(6, 6,189),  -- Integral: 200 - 11
(7, 7,197),  -- Pan Dulce: 240 - 28 - 15
(8, 8,175),  -- Pan con Azúcar: 200 - 25
(9, 9,132),  -- Gusanito: 160 - 18 - 10
(10,10,265), -- Pan Mollete: 280 - 15
(11,11,330), -- Pan Galleta: 360 - 30
(12,12,140); -- Pan de Leche: 160 - 20


-- =========================================================
-- 16. MÓDULO: BITÁCORA (días 1 a 4)
-- Fuente: Perfil §1.7.8 (registro automático de acciones, usuario y fecha/hora)
-- =========================================================

INSERT INTO "bitacora" ("id_bitacora","id_usuario","accion","tabla_afectada","descripcion","fecha_hora") VALUES
(1, 1,'CREATE','usuario','Creación de usuarios iniciales del sistema','2026-08-01 08:00:00'),
(2, 1,'CREATE','producto','Registro de los 12 productos y 7 categorías iniciales','2026-08-01 08:10:00'),
(3, 2,'CREATE','compra','Registro de compra de harina, sal y azúcar a Molinos del Oriente','2026-09-05 09:00:00'),
(4, 2,'CREATE','compra','Registro de compra de leche, mantequilla y huevos','2026-09-05 10:30:00'),
(5, 2,'CREATE','compra','Registro de compra de levadura','2026-09-05 11:15:00'),
(6, 5,'CREATE','produccion','Registro de producción de la jornada del 06-09-2026','2026-09-06 06:00:00'),
(7, 3,'CREATE','venta','Registro de venta directa en mostrador','2026-09-06 09:15:00'),
(8, 3,'UPDATE','pedido','Entrega del Pedido #1 y generación de venta asociada','2026-09-06 18:00:00'),
(9, 5,'CREATE','produccion','Registro de producción de la jornada del 07-09-2026','2026-09-07 06:00:00'),
(10,4,'UPDATE','pedido','Entrega del Pedido #2 (Hotel Cortez) y generación de venta asociada','2026-09-07 07:00:00'),
(11,5,'CREATE','nota_perdida_producto','Registro de merma de 5 Marraquetas dañadas','2026-09-07 20:00:00'),
(12,6,'CREATE','produccion','Registro de producción de la jornada del 08-09-2026','2026-09-08 06:00:00'),
(13,4,'UPDATE','pedido','Cancelación del Pedido #10 (Hotel Cortez)','2026-09-08 10:10:00'),
(14,2,'CREATE','movimiento_economico','Registro de gasto de mantenimiento de horno','2026-09-08 08:00:00'),
(15,2,'CREATE','compra','Registro de compra de reposición de harina','2026-09-09 07:00:00'),
(16,6,'CREATE','produccion','Registro de producción de la jornada del 09-09-2026','2026-09-09 06:00:00'),
(17,3,'CREATE','pedido','Registro del Pedido #11 (Restaurante El Aljibe)','2026-09-09 08:15:00'),
(18,4,'CREATE','pedido','Registro del Pedido #12 (Colegio San Ignacio)','2026-09-09 09:00:00'),
(19,3,'CREATE','pedido','Registro del Pedido #13 (Rosa Fernández Choque)','2026-09-09 11:30:00'),
(20,4,'CREATE','pedido','Registro del Pedido #14 (Hotel Cortez)','2026-09-09 14:00:00'),
(21,3,'UPDATE','pedido','Entrega del Pedido #11 y generación de venta asociada','2026-09-09 18:00:00'),
(22,3,'UPDATE','pedido','Entrega del Pedido #13 y generación de venta asociada','2026-09-09 17:00:00'),
(23,6,'CREATE','nota_perdida_producto','Registro de merma leve de 2 unidades de Casero','2026-09-09 20:30:00');
