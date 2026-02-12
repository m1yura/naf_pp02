-- =====================================================
-- Файл: add_material_request.sql
-- Назначение: Создание заявки на материалы от прораба
-- =====================================================

\c construction_company;

DO $$
DECLARE
    v_request_id INTEGER;
    v_request_number VARCHAR(50);
BEGIN
    -- Генерация номера заявки
    SELECT 'ЗМ-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(COALESCE(MAX(SUBSTRING(request_number FROM '\d+$'))::INT, 0) + 1::TEXT, 3, '0')
    INTO v_request_number
    FROM material_request
    WHERE request_number LIKE 'ЗМ-' || TO_CHAR(NOW(), 'YYYYMMDD') || '%';

    -- Создание заявки
    INSERT INTO material_request (
        request_number,
        object_id,
        requester_id,
        created_date,
        required_date,
        status,
        priority,
        notes
    ) VALUES (
        v_request_number,
        1,                          -- object_id (ЖК Северное сияние)
        2,                          -- requester_id (прораб Морозов)
        CURRENT_DATE,
        CURRENT_DATE + 5,          -- required через 5 дней
        'draft',
        'high',
        'Срочная заявка для бетонирования перекрытий'
    ) RETURNING id INTO v_request_id;

    -- Добавление позиций в заявку
    INSERT INTO material_request_item (request_id, material_id, quantity_required, unit, purpose) VALUES
    (v_request_id, 1, 25.0, 'м3', 'Бетонирование перекрытия 5 этажа'),
    (v_request_id, 2, 2.5, 'т', 'Армирование перекрытия'),
    (v_request_id, 4, 80.0, 'меш', 'Заделка швов');

    RAISE NOTICE 'Заявка % успешно создана с ID: %', v_request_number, v_request_id;
END $$;

-- Показать созданную заявку
SELECT
    mr.request_number,
    mr.created_date,
    mr.required_date,
    mr.status,
    mr.priority,
    e.full_name AS requester,
    co.name AS object_name,
    COUNT(mri.id) AS items_count,
    SUM(mri.quantity_required) AS total_quantity
FROM material_request mr
JOIN employee e ON mr.requester_id = e.id
JOIN construction_object co ON mr.object_id = co.id
JOIN material_request_item mri ON mr.id = mri.request_id
GROUP BY mr.id, mr.request_number, mr.created_date, mr.required_date, mr.status, mr.priority, e.full_name, co.name
ORDER BY mr.id DESC
LIMIT 1;