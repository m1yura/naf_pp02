-- =====================================================
-- Файл: write_off_material.sql
-- Назначение: Списание материалов со склада на объект (М-29)
-- =====================================================

\c construction_company;

CREATE OR REPLACE FUNCTION sp_write_off_material(
    p_warehouse_id INTEGER,
    p_material_id INTEGER,
    p_quantity DECIMAL,
    p_request_id INTEGER,
    p_employee_id INTEGER
) RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    new_balance DECIMAL
) LANGUAGE plpgsql AS $$
DECLARE
    v_available DECIMAL;
    v_material_name VARCHAR;
    v_warehouse_name VARCHAR;
BEGIN
    -- Получаем доступный остаток
    SELECT
        ws.quantity - ws.reserved_quantity,
        m.name,
        w.name
    INTO
        v_available,
        v_material_name,
        v_warehouse_name
    FROM warehouse_stock ws
    JOIN material m ON ws.material_id = m.id
    JOIN warehouse w ON ws.warehouse_id = w.id
    WHERE ws.warehouse_id = p_warehouse_id
      AND ws.material_id = p_material_id;

    -- Проверка наличия
    IF v_available < p_quantity THEN
        RETURN QUERY SELECT
            false,
            format('Ошибка: недостаточно материала "%s" на складе "%s". Доступно: %s, требуется: %s',
                   v_material_name, v_warehouse_name, v_available, p_quantity),
            0::DECIMAL;
        RETURN;
    END IF;

    -- Списание
    UPDATE warehouse_stock
    SET quantity = quantity - p_quantity,
        last_movement_date = CURRENT_TIMESTAMP
    WHERE warehouse_id = p_warehouse_id
      AND material_id = p_material_id;

    -- Обновление заявки
    UPDATE material_request_item
    SET quantity_supplied = quantity_supplied + p_quantity
    WHERE request_id = p_request_id
      AND material_id = p_material_id;

    -- Проверка статуса заявки
    UPDATE material_request mr
    SET status = CASE
                    WHEN NOT EXISTS (
                        SELECT 1 FROM material_request_item mri
                        WHERE mri.request_id = mr.id
                        AND mri.quantity_required > mri.quantity_supplied
                    ) THEN 'completed'
                    ELSE mr.status
                 END
    WHERE mr.id = p_request_id;

    -- Возврат результата
    RETURN QUERY SELECT
        true,
        format('Успешно списано %s %s материала "%s" со склада "%s"',
               p_quantity, m.unit, m.name, w.name),
        (ws.quantity - ws.reserved_quantity)
    FROM warehouse_stock ws
    JOIN material m ON ws.material_id = m.id
    JOIN warehouse w ON ws.warehouse_id = w.id
    WHERE ws.warehouse_id = p_warehouse_id
      AND ws.material_id = p_material_id;
END;
$$;

-- Пример использования
SELECT * FROM sp_write_off_material(
    2,    -- склад (приобъектный ЖК Северное)
    1,    -- материал (Бетон М200)
    8.0,  -- количество
    1,    -- заявка ЗМ-2025-0421
    2     -- сотрудник (прораб Морозов)
);