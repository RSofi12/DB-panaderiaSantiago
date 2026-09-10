-- =========================================================
-- BASE DE DATOS - SISTEMA DE INFORMACIÓN WEB
-- PANADERÍA SANTIAGO
-- PostgreSQL 14+
-- Versión final con correcciones de la docente
-- =========================================================


-- =========================================================
-- MÓDULO: USUARIOS Y SEGURIDAD
-- =========================================================

CREATE TABLE "rol" (
  "id_rol" bigint PRIMARY KEY,
  "nombre" varchar(50) NOT NULL,
  "descripcion" text
);

CREATE TABLE "permiso" (
  "id_permiso" bigint PRIMARY KEY,
  "nombre" varchar(50) NOT NULL,
  "descripcion" text
);

CREATE TABLE "rol_permiso" (
  "id_rol" bigint NOT NULL,
  "id_permiso" bigint NOT NULL,
  PRIMARY KEY ("id_rol", "id_permiso")
);

CREATE TABLE "usuario" (
  "id_usuario" bigint PRIMARY KEY,
  "id_rol" bigint,
  "nombre_usuario" varchar(50) UNIQUE NOT NULL,
  "hash_contrasena" varchar(255) NOT NULL,
  "nombre_completo" varchar(150) NOT NULL,
  "email" varchar(150),
  "activo" boolean NOT NULL DEFAULT true
);

CREATE TABLE "bitacora" (
  "id_bitacora" bigint PRIMARY KEY,
  "id_usuario" bigint NOT NULL,
  "accion" varchar(50) NOT NULL,
  "tabla_afectada" varchar(50),
  "descripcion" text,
  "fecha_hora" timestamp NOT NULL DEFAULT (now())
);


-- =========================================================
-- MÓDULO: PRODUCTOS
-- =========================================================

CREATE TABLE "categoria_producto" (
  "id_categoria" bigint PRIMARY KEY,
  "nombre" varchar(50) NOT NULL,
  "descripcion" text
);

CREATE TABLE "producto" (
  "id_producto" bigint PRIMARY KEY,
  "id_categoria" bigint,
  "nombre" varchar(100) NOT NULL,
  "descripcion" text,
  "costo_produccion" decimal(10,2) NOT NULL DEFAULT 0,
  "porcentaje_ganancia" decimal(5,2) NOT NULL DEFAULT 0,
  "precio_sugerido" decimal(10,2) NOT NULL DEFAULT 0,
  "precio_venta" decimal(10,2) NOT NULL DEFAULT 0,
  "fecha_registro" timestamp NOT NULL DEFAULT (now()),
  "activo" boolean NOT NULL DEFAULT true
);

CREATE TABLE "producto_materia_prima" (
  "id_producto" bigint NOT NULL,
  "id_materia_prima" bigint NOT NULL,
  "cantidad_requerida" decimal(10,3) NOT NULL,
  "unidad_medida" varchar(20) NOT NULL,
  PRIMARY KEY ("id_producto", "id_materia_prima")
);

CREATE TABLE "historial_precio_producto" (
  "id_historial" bigint PRIMARY KEY,
  "id_producto" bigint NOT NULL,
  "precio" decimal(10,2) NOT NULL,
  "fecha_inicio" timestamp NOT NULL DEFAULT (now())
);


-- =========================================================
-- MÓDULO: PRODUCCIÓN Y COMERCIALIZACIÓN
-- =========================================================

CREATE TABLE "cliente" (
  "id_cliente" bigint PRIMARY KEY,
  "nombre" varchar(150) NOT NULL,
  "telefono" varchar(20),
  "direccion" varchar(200)
);

CREATE TABLE "pedido" (
  "id_pedido" bigint PRIMARY KEY,
  "id_cliente" bigint NOT NULL,
  "id_usuario" bigint NOT NULL,
  "fecha_registro" timestamp NOT NULL DEFAULT (now()),
  "fecha_entrega" timestamp,
  "estado" varchar(20) NOT NULL DEFAULT 'pendiente',
  "metodo_pago" varchar(20),
  "total" decimal(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE "detalle_pedido" (
  "id_detalle_pedido" bigint PRIMARY KEY,
  "id_pedido" bigint NOT NULL,
  "id_producto" bigint NOT NULL,
  "cantidad" int NOT NULL,
  "precio_unitario" decimal(10,2) NOT NULL,
  "subtotal" decimal(10,2) NOT NULL
);

CREATE TABLE "venta" (
  "id_venta" bigint PRIMARY KEY,
  "id_pedido" bigint UNIQUE,
  "id_usuario" bigint NOT NULL,
  "numero_comprobante" bigint UNIQUE NOT NULL,
  "fecha_hora" timestamp NOT NULL DEFAULT (now()),
  "metodo_pago" varchar(20) NOT NULL,
  "id_transaccion_stripe" varchar(100),
  "total" decimal(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE "detalle_venta" (
  "id_detalle_venta" bigint PRIMARY KEY,
  "id_venta" bigint NOT NULL,
  "id_producto" bigint NOT NULL,
  "cantidad" int NOT NULL,
  "precio_unitario" decimal(10,2) NOT NULL,
  "subtotal" decimal(10,2) NOT NULL
);

CREATE TABLE "produccion" (
  "id_produccion" bigint PRIMARY KEY,
  "id_usuario" bigint NOT NULL,
  "fecha" date NOT NULL,
  "jornada" varchar(20)
);

CREATE TABLE "detalle_produccion" (
  "id_detalle_produccion" bigint PRIMARY KEY,
  "id_produccion" bigint NOT NULL,
  "id_producto" bigint NOT NULL,
  "cantidad_producida" int NOT NULL,
  "costo_unitario" decimal(10,2) NOT NULL
);

CREATE TABLE "nota_perdida_producto" (
  "id_nota_perdida" bigint PRIMARY KEY,
  "id_detalle_produccion" bigint NOT NULL,
  "id_usuario" bigint NOT NULL,
  "cantidad" int NOT NULL,
  "costo_unitario" decimal(10,2) NOT NULL,
  "fecha_salida" timestamp NOT NULL DEFAULT (now())
);


-- =========================================================
-- MÓDULO: INVENTARIO DE MATERIA PRIMA
-- =========================================================

CREATE TABLE "materia_prima" (
  "id_materia_prima" bigint PRIMARY KEY,
  "nombre" varchar(100) NOT NULL,
  "unidad_medida" varchar(20) NOT NULL,
  "stock_minimo" decimal(10,3) NOT NULL DEFAULT 0,
  "fecha_registro" timestamp NOT NULL DEFAULT (now()),
  "activo" boolean NOT NULL DEFAULT true
);

CREATE TABLE "historial_precio_materia_prima" (
  "id_historial" bigint PRIMARY KEY,
  "id_materia_prima" bigint NOT NULL,
  "precio" decimal(10,2) NOT NULL,
  "fecha_inicio" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "inventario_materia_prima" (
  "id_inventario" bigint PRIMARY KEY,
  "id_materia_prima" bigint UNIQUE NOT NULL,
  "stock_actual" decimal(10,3) NOT NULL DEFAULT 0
);

CREATE TABLE "movimiento_materia_prima" (
  "id_movimiento" bigint PRIMARY KEY,
  "id_inventario" bigint NOT NULL,
  "id_compra" bigint,
  "id_produccion" bigint,
  "fecha_hora" timestamp NOT NULL DEFAULT (now()),
  "tipo" varchar(10) NOT NULL,
  "cantidad" decimal(10,3) NOT NULL
);


-- =========================================================
-- MÓDULO: INVENTARIO DE PRODUCTOS TERMINADOS
-- =========================================================

CREATE TABLE "inventario_producto_terminado" (
  "id_inventario" bigint PRIMARY KEY,
  "id_producto" bigint UNIQUE NOT NULL,
  "stock_actual" int NOT NULL DEFAULT 0
);

CREATE TABLE "movimiento_producto_terminado" (
  "id_movimiento" bigint PRIMARY KEY,
  "id_inventario" bigint NOT NULL,
  "id_produccion" bigint,
  "id_venta" bigint,
  "id_pedido" bigint,
  "id_nota_perdida" bigint,
  "fecha_hora" timestamp NOT NULL DEFAULT (now()),
  "tipo" varchar(10) NOT NULL,
  "cantidad" int NOT NULL
);


-- =========================================================
-- MÓDULO: COMPRAS, PROVEEDORES Y GASTOS
-- =========================================================

CREATE TABLE "proveedor" (
  "id_proveedor" bigint PRIMARY KEY,
  "nombre" varchar(150) NOT NULL,
  "telefono" varchar(20),
  "direccion" varchar(200),
  "fecha_registro" timestamp NOT NULL DEFAULT (now()),
  "activo" boolean NOT NULL DEFAULT true
);

CREATE TABLE "compra" (
  "id_compra" bigint PRIMARY KEY,
  "id_proveedor" bigint NOT NULL,
  "id_usuario" bigint NOT NULL,
  "fecha_hora" timestamp NOT NULL DEFAULT (now()),
  "total" decimal(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE "detalle_compra" (
  "id_detalle_compra" bigint PRIMARY KEY,
  "id_compra" bigint NOT NULL,
  "id_materia_prima" bigint NOT NULL,
  "cantidad" decimal(10,3) NOT NULL,
  "precio_unitario" decimal(10,2) NOT NULL,
  "subtotal" decimal(10,2) NOT NULL
);

CREATE TABLE "movimiento_economico" (
  "id_movimiento" bigint PRIMARY KEY,
  "id_usuario" bigint NOT NULL,
  "tipo" varchar(20) NOT NULL,
  "concepto" varchar(100) NOT NULL,
  "descripcion" text,
  "monto" decimal(10,2) NOT NULL,
  "fecha_hora" timestamp NOT NULL DEFAULT (now())
);


-- =========================================================
-- LLAVES FORÁNEAS - USUARIOS Y SEGURIDAD
-- =========================================================

ALTER TABLE "rol_permiso" ADD FOREIGN KEY ("id_rol") REFERENCES
"rol" ("id_rol") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "rol_permiso" ADD FOREIGN KEY ("id_permiso") REFERENCES
"permiso" ("id_permiso") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "usuario" ADD FOREIGN KEY ("id_rol") REFERENCES
"rol" ("id_rol") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bitacora" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - PRODUCTOS
-- =========================================================

ALTER TABLE "producto" ADD FOREIGN KEY ("id_categoria") REFERENCES
"categoria_producto" ("id_categoria") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "producto_materia_prima" ADD FOREIGN KEY ("id_producto") REFERENCES
"producto" ("id_producto") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "producto_materia_prima" ADD FOREIGN KEY ("id_materia_prima") REFERENCES
"materia_prima" ("id_materia_prima") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "historial_precio_producto" ADD FOREIGN KEY ("id_producto") REFERENCES
"producto" ("id_producto") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - PEDIDOS Y VENTAS
-- =========================================================

ALTER TABLE "pedido" ADD FOREIGN KEY ("id_cliente") REFERENCES
"cliente" ("id_cliente") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "pedido" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_pedido" ADD FOREIGN KEY ("id_pedido") REFERENCES
"pedido" ("id_pedido") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_pedido" ADD FOREIGN KEY ("id_producto") REFERENCES
"producto" ("id_producto") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "venta" ADD FOREIGN KEY ("id_pedido") REFERENCES
"pedido" ("id_pedido") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "venta" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_venta" ADD FOREIGN KEY ("id_venta") REFERENCES
"venta" ("id_venta") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_venta" ADD FOREIGN KEY ("id_producto") REFERENCES
"producto" ("id_producto") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - PRODUCCIÓN
-- =========================================================

ALTER TABLE "produccion" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_produccion" ADD FOREIGN KEY ("id_produccion") REFERENCES
"produccion" ("id_produccion") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_produccion" ADD FOREIGN KEY ("id_producto") REFERENCES
"producto" ("id_producto") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - NOTA DE PÉRDIDA DE PRODUCTO
-- =========================================================

ALTER TABLE "nota_perdida_producto" ADD FOREIGN KEY ("id_detalle_produccion")
REFERENCES "detalle_produccion" ("id_detalle_produccion") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "nota_perdida_producto" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - INVENTARIO MATERIA PRIMA
-- =========================================================

ALTER TABLE "historial_precio_materia_prima" ADD FOREIGN KEY ("id_materia_prima")
REFERENCES "materia_prima" ("id_materia_prima") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "inventario_materia_prima" ADD FOREIGN KEY ("id_materia_prima")
REFERENCES "materia_prima" ("id_materia_prima") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_materia_prima" ADD FOREIGN KEY ("id_inventario")
REFERENCES "inventario_materia_prima" ("id_inventario") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_materia_prima" ADD FOREIGN KEY ("id_compra")
REFERENCES "compra" ("id_compra") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_materia_prima" ADD FOREIGN KEY ("id_produccion")
REFERENCES "produccion" ("id_produccion") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - INVENTARIO PRODUCTO TERMINADO
-- =========================================================

ALTER TABLE "inventario_producto_terminado" ADD FOREIGN KEY ("id_producto")
REFERENCES "producto" ("id_producto") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_producto_terminado" ADD FOREIGN KEY ("id_inventario")
REFERENCES "inventario_producto_terminado" ("id_inventario") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_producto_terminado" ADD FOREIGN KEY ("id_produccion")
REFERENCES "produccion" ("id_produccion") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_producto_terminado" ADD FOREIGN KEY ("id_venta")
REFERENCES "venta" ("id_venta") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_producto_terminado" ADD FOREIGN KEY ("id_pedido")
REFERENCES "pedido" ("id_pedido") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_producto_terminado" ADD FOREIGN KEY ("id_nota_perdida")
REFERENCES "nota_perdida_producto" ("id_nota_perdida") DEFERRABLE INITIALLY IMMEDIATE;


-- =========================================================
-- LLAVES FORÁNEAS - COMPRAS, PROVEEDORES Y GASTOS
-- =========================================================

ALTER TABLE "compra" ADD FOREIGN KEY ("id_proveedor") REFERENCES
"proveedor" ("id_proveedor") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "compra" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_compra" ADD FOREIGN KEY ("id_compra") REFERENCES
"compra" ("id_compra") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "detalle_compra" ADD FOREIGN KEY ("id_materia_prima") REFERENCES
"materia_prima" ("id_materia_prima") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "movimiento_economico" ADD FOREIGN KEY ("id_usuario") REFERENCES
"usuario" ("id_usuario") DEFERRABLE INITIALLY IMMEDIATE;
