-- ==========================================
-- Trigger 1: Guarda en el historial automáticamente cuando cambia el precio de un producto
-- ==========================================
CREATE OR REPLACE FUNCTION fn_guardar_historial_precio_producto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.precio_venta <> OLD.precio_venta THEN
        INSERT INTO "historial_precio_producto" ("id_historial", "id_producto", "precio", "fecha_inicio")
        VALUES (
            (SELECT COALESCE(MAX(id_historial), 0) + 1 FROM "historial_precio_producto"),
            NEW.id_producto,
            NEW.precio_venta,
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_historial_precio_producto ON "producto";
CREATE TRIGGER trg_historial_precio_producto
AFTER UPDATE OF "precio_venta" ON "producto"
FOR EACH ROW EXECUTE FUNCTION fn_guardar_historial_precio_producto();

-- ==========================================
-- Trigger 2: Calcula el subtotal en el detalle de compra (cantidad * precio_unitario)
-- ==========================================
CREATE OR REPLACE FUNCTION fn_calcular_subtotal_compra()
RETURNS TRIGGER AS $$
BEGIN
    NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_calcular_subtotal_compra ON "detalle_compra";
CREATE TRIGGER trg_calcular_subtotal_compra
BEFORE INSERT OR UPDATE ON "detalle_compra"
FOR EACH ROW EXECUTE FUNCTION fn_calcular_subtotal_compra();

-- ==========================================
-- Trigger 3: Calcula y actualiza el total de la compra automáticamente
-- ==========================================
CREATE OR REPLACE FUNCTION fn_actualizar_total_compra()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE "compra"
    SET "total" = (SELECT COALESCE(SUM(subtotal), 0) FROM "detalle_compra" WHERE id_compra = NEW.id_compra)
    WHERE "id_compra" = NEW.id_compra;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_total_compra ON "detalle_compra";
CREATE TRIGGER trg_actualizar_total_compra
AFTER INSERT OR UPDATE OR DELETE ON "detalle_compra"
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_total_compra();

-- ==========================================
-- Trigger 4: Ingresa materia prima al inventario tras registrar una compra
-- ==========================================
CREATE OR REPLACE FUNCTION fn_ingreso_inventario_materia_prima()
RETURNS TRIGGER AS $$
DECLARE
    v_id_inventario bigint;
BEGIN
    SELECT id_inventario INTO v_id_inventario FROM "inventario_materia_prima" WHERE id_materia_prima = NEW.id_materia_prima;
    
    UPDATE "inventario_materia_prima" SET stock_actual = stock_actual + NEW.cantidad WHERE id_inventario = v_id_inventario;
    
    INSERT INTO "movimiento_materia_prima" ("id_movimiento", "id_inventario", "id_compra", "tipo", "cantidad")
    VALUES ((SELECT COALESCE(MAX(id_movimiento), 0) + 1 FROM "movimiento_materia_prima"), v_id_inventario, NEW.id_compra, 'INGRESO', NEW.cantidad);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ingreso_inventario_materia_prima ON "detalle_compra";
CREATE TRIGGER trg_ingreso_inventario_materia_prima
AFTER INSERT ON "detalle_compra"
FOR EACH ROW EXECUTE FUNCTION fn_ingreso_inventario_materia_prima();

-- ==========================================
-- Trigger 5: Aumenta el stock de productos terminados cuando se produce
-- ==========================================
CREATE OR REPLACE FUNCTION fn_ingreso_producto_terminado()
RETURNS TRIGGER AS $$
DECLARE
    v_id_inventario bigint;
BEGIN
    SELECT id_inventario INTO v_id_inventario FROM "inventario_producto_terminado" WHERE id_producto = NEW.id_producto;
    
    UPDATE "inventario_producto_terminado" SET stock_actual = stock_actual + NEW.cantidad_producida WHERE id_inventario = v_id_inventario;
    
    INSERT INTO "movimiento_producto_terminado" ("id_movimiento", "id_inventario", "id_produccion", "tipo", "cantidad")
    VALUES ((SELECT COALESCE(MAX(id_movimiento), 0) + 1 FROM "movimiento_producto_terminado"), v_id_inventario, NEW.id_produccion, 'PRODUCCION', NEW.cantidad_producida);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_ingreso_producto_terminado ON "detalle_produccion";
CREATE TRIGGER trg_ingreso_producto_terminado
AFTER INSERT ON "detalle_produccion"
FOR EACH ROW EXECUTE FUNCTION fn_ingreso_producto_terminado();

-- ==========================================
-- Trigger 6: Calcula el subtotal en el detalle de cada venta (cantidad * precio)
-- ==========================================
CREATE OR REPLACE FUNCTION fn_calcular_subtotal_venta()
RETURNS TRIGGER AS $$
BEGIN
    NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_calcular_subtotal_venta ON "detalle_venta";
CREATE TRIGGER trg_calcular_subtotal_venta
BEFORE INSERT OR UPDATE ON "detalle_venta"
FOR EACH ROW EXECUTE FUNCTION fn_calcular_subtotal_venta();

-- ==========================================
-- Trigger 7: Suma los subtotales para actualizar el total general de la venta
-- ==========================================
CREATE OR REPLACE FUNCTION fn_actualizar_total_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_id_venta bigint;
BEGIN
    IF TG_OP = 'DELETE' THEN v_id_venta = OLD.id_venta;
    ELSE v_id_venta = NEW.id_venta; END IF;

    UPDATE "venta"
    SET "total" = (SELECT COALESCE(SUM(subtotal), 0) FROM "detalle_venta" WHERE id_venta = v_id_venta)
    WHERE "id_venta" = v_id_venta;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_actualizar_total_venta ON "detalle_venta";
CREATE TRIGGER trg_actualizar_total_venta
AFTER INSERT OR UPDATE OR DELETE ON "detalle_venta"
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_total_venta();

-- ==========================================
-- Trigger 8: Descuenta el stock de productos terminados al realizar una venta
-- ==========================================
CREATE OR REPLACE FUNCTION fn_salida_inventario_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_id_inventario bigint;
BEGIN
    SELECT id_inventario INTO v_id_inventario FROM "inventario_producto_terminado" WHERE id_producto = NEW.id_producto;
    
    UPDATE "inventario_producto_terminado" SET stock_actual = stock_actual - NEW.cantidad WHERE id_inventario = v_id_inventario;
    
    INSERT INTO "movimiento_producto_terminado" ("id_movimiento", "id_inventario", "id_venta", "tipo", "cantidad")
    VALUES ((SELECT COALESCE(MAX(id_movimiento), 0) + 1 FROM "movimiento_producto_terminado"), v_id_inventario, NEW.id_venta, 'VENTA', NEW.cantidad);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_salida_inventario_venta ON "detalle_venta";
CREATE TRIGGER trg_salida_inventario_venta
AFTER INSERT ON "detalle_venta"
FOR EACH ROW EXECUTE FUNCTION fn_salida_inventario_venta();

-- ==========================================
-- Trigger 9: Descuenta inventario si un producto se arruina (Nota de pérdida)
-- ==========================================
CREATE OR REPLACE FUNCTION fn_salida_por_perdida()
RETURNS TRIGGER AS $$
DECLARE
    v_id_inventario bigint;
    v_id_producto bigint;
BEGIN
    SELECT id_producto INTO v_id_producto FROM "detalle_produccion" WHERE id_detalle_produccion = NEW.id_detalle_produccion;
    SELECT id_inventario INTO v_id_inventario FROM "inventario_producto_terminado" WHERE id_producto = v_id_producto;
    
    UPDATE "inventario_producto_terminado" SET stock_actual = stock_actual - NEW.cantidad WHERE id_inventario = v_id_inventario;
    
    INSERT INTO "movimiento_producto_terminado" ("id_movimiento", "id_inventario", "id_nota_perdida", "tipo", "cantidad")
    VALUES ((SELECT COALESCE(MAX(id_movimiento), 0) + 1 FROM "movimiento_producto_terminado"), v_id_inventario, NEW.id_nota_perdida, 'PERDIDA', NEW.cantidad);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_salida_por_perdida ON "nota_perdida_producto";
CREATE TRIGGER trg_salida_por_perdida
AFTER INSERT ON "nota_perdida_producto"
FOR EACH ROW EXECUTE FUNCTION fn_salida_por_perdida();

-- ==========================================
-- Trigger 10: Guarda en bitácora si se desactiva un usuario del sistema
-- ==========================================
CREATE OR REPLACE FUNCTION fn_auditoria_usuario()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.activo <> OLD.activo THEN
        INSERT INTO "bitacora" ("id_bitacora", "id_usuario", "accion", "tabla_afectada", "descripcion")
        VALUES (
            (SELECT COALESCE(MAX(id_bitacora), 0) + 1 FROM "bitacora"), 
            NEW.id_usuario, 
            'UPDATE ESTADO', 
            'usuario', 
            'El estado del usuario ' || NEW.nombre_usuario || ' cambió a ' || NEW.activo
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auditoria_usuario ON "usuario";
CREATE TRIGGER trg_auditoria_usuario
AFTER UPDATE ON "usuario"
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_usuario();
