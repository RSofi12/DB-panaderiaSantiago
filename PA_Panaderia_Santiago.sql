-- PROCEDIMIENTOS ALMACENADOS PARA PANADERIA SANTIAGO

-- PA 1: REGISTRAR USUARIO
-- Crea un nuevo usuario del sistema.
-- Valida que el rol exista y que el nombre de usuario no esté repetido.
-- También registra la creación en la bitácora.
-- ============================================================
CREATE OR REPLACE PROCEDURE pa_registrar_usuario(
    IN p_id_rol BIGINT,
    IN p_nombre_usuario VARCHAR(50),
    IN p_hash_contrasena VARCHAR(255),
    IN p_nombre_completo VARCHAR(150),
    IN p_email VARCHAR(150),
    IN p_id_usuario_responsable BIGINT,
    INOUT p_id_usuario BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_usuario BIGINT;
    v_id_bitacora BIGINT;
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM rol
        WHERE id_rol = p_id_rol
    ) THEN
        RAISE EXCEPTION 'No existe el rol con id %', p_id_rol;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM usuario
        WHERE LOWER(nombre_usuario) = LOWER(p_nombre_usuario)
    ) THEN
        RAISE EXCEPTION 'El nombre de usuario ya existe';
    END IF;

    SELECT COALESCE(MAX(id_usuario), 0) + 1
    INTO v_id_usuario
    FROM usuario;

    INSERT INTO usuario(
        id_usuario,
        id_rol,
        nombre_usuario,
        hash_contrasena,
        nombre_completo,
        email,
        activo
    )
    VALUES (
        v_id_usuario,
        p_id_rol,
        p_nombre_usuario,
        p_hash_contrasena,
        p_nombre_completo,
        p_email,
        TRUE
    );

    SELECT COALESCE(MAX(id_bitacora), 0) + 1
    INTO v_id_bitacora
    FROM bitacora;

    INSERT INTO bitacora(
        id_bitacora,
        id_usuario,
        accion,
        tabla_afectada,
        descripcion,
        fecha_hora
    )
    VALUES (
        v_id_bitacora,
        p_id_usuario_responsable,
        'CREATE',
        'usuario',
        'Se creó el usuario ' || p_nombre_usuario,
        NOW()
    );

    p_id_usuario := v_id_usuario;

    RAISE NOTICE 'Usuario creado correctamente. ID=%', v_id_usuario;

END;
$$;


-- PA 2: ACTUALIZAR PRECIO DE VENTA DE PRODUCTO
-- Modifica el precio de venta actual de un producto.
-- Guarda el nuevo precio en el historial de precios.
-- Registra el cambio en bitácora.
-- ============================================================
CREATE OR REPLACE PROCEDURE pa_actualizar_precio_venta_producto(
    IN p_id_producto BIGINT,
    IN p_nuevo_precio NUMERIC(10,2),
    IN p_id_usuario BIGINT,
    INOUT p_id_historial BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_precio_anterior NUMERIC(10,2);
    v_id_historial BIGINT;
    v_id_bitacora BIGINT;
BEGIN

    IF p_nuevo_precio <= 0 THEN
        RAISE EXCEPTION 'El nuevo precio debe ser mayor a 0';
    END IF;

    SELECT precio_venta
    INTO v_precio_anterior
    FROM producto
    WHERE id_producto = p_id_producto;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El producto no existe';
    END IF;

    UPDATE producto
    SET precio_venta = p_nuevo_precio
    WHERE id_producto = p_id_producto;

    SELECT COALESCE(MAX(id_historial), 0) + 1
    INTO v_id_historial
    FROM historial_precio_producto;

    INSERT INTO historial_precio_producto(
        id_historial,
        id_producto,
        precio,
        fecha_inicio
    )
    VALUES (
        v_id_historial,
        p_id_producto,
        p_nuevo_precio,
        NOW()
    );

    SELECT COALESCE(MAX(id_bitacora), 0) + 1
    INTO v_id_bitacora
    FROM bitacora;

    INSERT INTO bitacora(
        id_bitacora,
        id_usuario,
        accion,
        tabla_afectada,
        descripcion,
        fecha_hora
    )
    VALUES (
        v_id_bitacora,
        p_id_usuario,
        'UPDATE',
        'producto',
        'Precio actualizado de Bs ' ||
        v_precio_anterior ||
        ' a Bs ' ||
        p_nuevo_precio,
        NOW()
    );

    p_id_historial := v_id_historial;

    RAISE NOTICE 'Precio actualizado correctamente';

END;
$$;


-- ============================================================
-- PA 3: RECALCULAR COSTO Y PRECIO SUGERIDO
-- Calcula el costo de producción usando:
-- cantidad requerida de materia prima x último precio registrado.
-- Después calcula el precio sugerido aplicando el porcentaje de ganancia.
-- NO modifica el precio de venta real.
-- ============================================================
CREATE OR REPLACE PROCEDURE pa_recalcular_costos_producto(
    IN p_id_producto BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    r_producto RECORD;
    v_costo NUMERIC(12,4);
BEGIN

    FOR r_producto IN
        SELECT
            id_producto,
            nombre,
            porcentaje_ganancia
        FROM producto
        WHERE
            p_id_producto IS NULL
            OR id_producto = p_id_producto
    LOOP

        SELECT COALESCE(
            SUM(
                pmp.cantidad_requerida *
                (
                    SELECT hp.precio
                    FROM historial_precio_materia_prima hp
                    WHERE hp.id_materia_prima = pmp.id_materia_prima
                    ORDER BY hp.fecha_inicio DESC, hp.id_historial DESC
                    LIMIT 1
                )
            ),
            0
        )
        INTO v_costo
        FROM producto_materia_prima pmp
        WHERE pmp.id_producto = r_producto.id_producto;

        UPDATE producto
        SET
            costo_produccion = ROUND(v_costo, 2),
            precio_sugerido = ROUND(
                v_costo *
                (1 + porcentaje_ganancia / 100.0),
                2
            )
        WHERE id_producto = r_producto.id_producto;

        RAISE NOTICE
            'Producto % recalculado. Costo=% Precio sugerido=%',
            r_producto.nombre,
            ROUND(v_costo,2),
            ROUND(
                v_costo *
                (1 + r_producto.porcentaje_ganancia / 100.0),
                2
            );

    END LOOP;

END;
$$;


-- ============================================================
-- PA 4: REGISTRAR COMPRA
-- Registra una compra completa.
-- Inserta:
--  - compra
--  - detalle_compra
--  - historial de precios de materia prima
--  - entrada al inventario
--  - movimiento de materia prima
-- También recalcula el costo de los productos.
-- ============================================================
CREATE OR REPLACE PROCEDURE pa_registrar_compra(
    IN p_id_proveedor BIGINT,
    IN p_id_usuario BIGINT,
    IN p_detalles JSONB,
    INOUT p_id_compra BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    r JSONB;
    v_id_compra BIGINT;
    v_id_detalle BIGINT;
    v_id_historial BIGINT;
    v_id_movimiento BIGINT;
    v_id_inventario BIGINT;

    v_id_materia BIGINT;
    v_cantidad NUMERIC(10,3);
    v_precio NUMERIC(10,2);
    v_subtotal NUMERIC(10,2);
    v_total NUMERIC(10,2) := 0;
BEGIN

    SELECT COALESCE(MAX(id_compra),0)+1
    INTO v_id_compra
    FROM compra;

    FOR r IN
        SELECT value
        FROM jsonb_array_elements(p_detalles)
    LOOP

        v_id_materia :=
            (r->>'id_materia_prima')::BIGINT;

        v_cantidad :=
            (r->>'cantidad')::NUMERIC;

        v_precio :=
            (r->>'precio_unitario')::NUMERIC;

        v_total :=
            v_total + ROUND(v_cantidad * v_precio,2);

    END LOOP;

    INSERT INTO compra(
        id_compra,
        id_proveedor,
        id_usuario,
        fecha_hora,
        total
    )
    VALUES (
        v_id_compra,
        p_id_proveedor,
        p_id_usuario,
        NOW(),
        v_total
    );

    SELECT COALESCE(MAX(id_detalle_compra),0)+1
    INTO v_id_detalle
    FROM detalle_compra;

    SELECT COALESCE(MAX(id_historial),0)+1
    INTO v_id_historial
    FROM historial_precio_materia_prima;

    SELECT COALESCE(MAX(id_movimiento),0)+1
    INTO v_id_movimiento
    FROM movimiento_materia_prima;

    FOR r IN
        SELECT value
        FROM jsonb_array_elements(p_detalles)
    LOOP

        v_id_materia :=
            (r->>'id_materia_prima')::BIGINT;

        v_cantidad :=
            (r->>'cantidad')::NUMERIC;

        v_precio :=
            (r->>'precio_unitario')::NUMERIC;

        v_subtotal :=
            ROUND(v_cantidad * v_precio,2);

        INSERT INTO detalle_compra(
            id_detalle_compra,
            id_compra,
            id_materia_prima,
            cantidad,
            precio_unitario,
            subtotal
        )
        VALUES (
            v_id_detalle,
            v_id_compra,
            v_id_materia,
            v_cantidad,
            v_precio,
            v_subtotal
        );

        INSERT INTO historial_precio_materia_prima(
            id_historial,
            id_materia_prima,
            precio,
            fecha_inicio
        )
        VALUES (
            v_id_historial,
            v_id_materia,
            v_precio,
            NOW()
        );

        SELECT id_inventario
        INTO v_id_inventario
        FROM inventario_materia_prima
        WHERE id_materia_prima = v_id_materia;

        UPDATE inventario_materia_prima
        SET stock_actual =
            stock_actual + v_cantidad
        WHERE id_inventario =
            v_id_inventario;

        INSERT INTO movimiento_materia_prima(
            id_movimiento,
            id_inventario,
            id_compra,
            id_produccion,
            fecha_hora,
            tipo,
            cantidad
        )
        VALUES (
            v_id_movimiento,
            v_id_inventario,
            v_id_compra,
            NULL,
            NOW(),
            'entrada',
            v_cantidad
        );

        v_id_detalle := v_id_detalle + 1;
        v_id_historial := v_id_historial + 1;
        v_id_movimiento := v_id_movimiento + 1;

    END LOOP;

    CALL pa_recalcular_costos_producto(NULL);

    p_id_compra := v_id_compra;

    RAISE NOTICE
        'Compra registrada. ID=% Total=%',
        v_id_compra,
        v_total;

END;
$$;

-- ============================================================
-- PA 5: REGISTRAR PRODUCCIÓN
-- Registra una producción.
-- Descuenta automáticamente las materias primas usadas.
-- Incrementa el inventario de productos terminados.
-- Registra los movimientos de inventario.
-- ============================================================
CREATE OR REPLACE PROCEDURE pa_registrar_produccion(
    IN p_id_usuario BIGINT,
    IN p_fecha DATE,
    IN p_jornada VARCHAR(20),
    IN p_detalles JSONB,
    INOUT p_id_produccion BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    r JSONB;
    r_receta RECORD;

    v_id_produccion BIGINT;
    v_id_detalle BIGINT;
    v_id_mov_mp BIGINT;
    v_id_mov_pt BIGINT;

    v_id_producto BIGINT;
    v_cantidad INT;
    v_costo NUMERIC(10,2);

    v_consumo NUMERIC(10,3);
    v_id_inv_mp BIGINT;
    v_id_inv_pt BIGINT;
BEGIN

    SELECT COALESCE(MAX(id_produccion),0)+1
    INTO v_id_produccion
    FROM produccion;

    INSERT INTO produccion(
        id_produccion,
        id_usuario,
        fecha,
        jornada
    )
    VALUES (
        v_id_produccion,
        p_id_usuario,
        p_fecha,
        p_jornada
    );

    SELECT COALESCE(MAX(id_detalle_produccion),0)+1
    INTO v_id_detalle
    FROM detalle_produccion;

    SELECT COALESCE(MAX(id_movimiento),0)+1
    INTO v_id_mov_mp
    FROM movimiento_materia_prima;

    SELECT COALESCE(MAX(id_movimiento),0)+1
    INTO v_id_mov_pt
    FROM movimiento_producto_terminado;

    FOR r IN
        SELECT value
        FROM jsonb_array_elements(p_detalles)
    LOOP

        v_id_producto := (r->>'id_producto')::BIGINT;

        v_cantidad :=
            (r->>'cantidad')::INT;

        SELECT costo_produccion
        INTO v_costo
        FROM producto
        WHERE id_producto = v_id_producto;

        INSERT INTO detalle_produccion(
            id_detalle_produccion,
            id_produccion,
            id_producto,
            cantidad_producida,
            costo_unitario
        )
        VALUES (
            v_id_detalle,
            v_id_produccion,
            v_id_producto,
            v_cantidad,
            v_costo
        );

        FOR r_receta IN

            SELECT
                id_materia_prima,
                cantidad_requerida
            FROM producto_materia_prima
            WHERE id_producto = v_id_producto

        LOOP

            v_consumo :=
                ROUND(
                    r_receta.cantidad_requerida *
                    v_cantidad,
                    3
                );

            SELECT id_inventario
            INTO v_id_inv_mp
            FROM inventario_materia_prima
            WHERE id_materia_prima =
                r_receta.id_materia_prima;

            UPDATE inventario_materia_prima
            SET stock_actual =
                stock_actual - v_consumo
            WHERE id_inventario =
                v_id_inv_mp;

            INSERT INTO movimiento_materia_prima(
                id_movimiento,
                id_inventario,
                id_compra,
                id_produccion,
                fecha_hora,
                tipo,
                cantidad
            )
            VALUES (
                v_id_mov_mp,
                v_id_inv_mp,
                NULL,
                v_id_produccion,
                NOW(),
                'salida',
                v_consumo
            );

            v_id_mov_mp := v_id_mov_mp + 1;

        END LOOP;

        SELECT id_inventario
        INTO v_id_inv_pt
        FROM inventario_producto_terminado
        WHERE id_producto = v_id_producto;

        UPDATE inventario_producto_terminado
        SET stock_actual =
            stock_actual + v_cantidad
        WHERE id_inventario = v_id_inv_pt;

        INSERT INTO movimiento_producto_terminado(
            id_movimiento,
            id_inventario,
            id_produccion,
            id_venta,
            id_pedido,
            id_nota_perdida,
            fecha_hora,
            tipo,
            cantidad
        )
        VALUES (
            v_id_mov_pt,
            v_id_inv_pt,
            v_id_produccion,
            NULL,
            NULL,
            NULL,
            NOW(),
            'entrada',
            v_cantidad
        );

        v_id_detalle := v_id_detalle + 1;
        v_id_mov_pt := v_id_mov_pt + 1;

    END LOOP;

    p_id_produccion := v_id_produccion;

    RAISE NOTICE
        'Producción registrada. ID=%',
        v_id_produccion;

END;
$$;
