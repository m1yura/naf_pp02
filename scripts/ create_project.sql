-- =====================================================
-- Файл: create_project.sql
-- Назначение: Добавление нового строительного объекта
-- Использование: psql -d construction_company -f create_project.sql
-- =====================================================

\c construction_company;

-- Параметры (замените на реальные значения)
\set obj_code 'OBJ-2026-001'
\set obj_name 'ЖК "Весенний" корпус 3'
\set obj_address 'г. Москва, ул. Летняя, 15'
\set customer_id 1
\set planned_start '2026-03-01'
\set planned_end '2027-08-30'
\set contract_amount 450000000
\set responsible_id 1

DO $$
DECLARE
    v_object_id INTEGER;
BEGIN
    -- Вставка объекта
    INSERT INTO construction_object (
        code, name, address, customer_id,
        planned_start_date, planned_end_date,
        total_contract_amount, responsible_engineer_id,
        project_status
    ) VALUES (
        'OBJ-2026-001',
        'ЖК "Весенний" корпус 3',
        'г. Москва, ул. Летняя, 15',
        1,
        '2026-03-01',
        '2027-08-30',
        450000000,
        1,
        'design'
    ) RETURNING id INTO v_object_id;

    -- Создание приобъектного склада
    INSERT INTO warehouse (name, type, object_id, address, manager_id)
    VALUES ('Склад ЖК Весенний', 'on_site', v_object_id, 'г. Москва, ул. Летняя, 15', 4);

    RAISE NOTICE 'Объект % успешно создан с ID: %', 'OBJ-2026-001', v_object_id;
END $$;

-- Проверка результата
SELECT id, code, name, address, project_status, created_at
FROM construction_object
WHERE code = 'OBJ-2026-001';