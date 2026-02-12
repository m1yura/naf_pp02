-- =====================================================
-- Файл: create_ks2_act.sql
-- Назначение: Формирование акта выполненных работ (КС-2)
-- =====================================================

\c construction_company;

DO $$
DECLARE
    v_act_id INTEGER;
    v_act_number VARCHAR(50);
    v_current_month INTEGER := EXTRACT(MONTH FROM CURRENT_DATE);
    v_current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    -- Генерация номера акта
    SELECT 'КС2-' || TO_CHAR(CURRENT_DATE, 'YYYYMM') || '-' ||
           LPAD(COALESCE(MAX(SUBSTRING(act_number FROM '\d+$'))::INT, 0) + 1::TEXT, 2, '0')
    INTO v_act_number
    FROM ks2_act
    WHERE act_number LIKE 'КС2-' || TO_CHAR(CURRENT_DATE, 'YYYYMM') || '%';

    -- Создание акта
    INSERT INTO ks2_act (
        act_number,
        act_date,
        contract_id,
        object_id,
        period_month,
        period_year,
        work_description,
        amount,
        vat_rate,
        vat_amount,
        total_amount,
        status,
        created_by_id
    ) VALUES (
        v_act_number,
        CURRENT_DATE,
        1,                          -- contract_id (ДГ-2025-045)
        1,                          -- object_id (ЖК Северное сияние)
        v_current_month,
        v_current_year,
        'Монтаж вентиляции 5-7 этажи',
        678000,
        20,
        135600,
        813600,
        'draft',
        2                           -- created_by_id (прораб Морозов)
    ) RETURNING id INTO v_act_id;

    RAISE NOTICE 'Акт КС-2 % успешно создан. Сумма: % руб.', v_act_number, 813600;
END $$;

-- Просмотр последних актов
SELECT
    act_number,
    act_date,
    co.name as object_name,
    work_description,
    total_amount,
    status
FROM ks2_act ka
JOIN construction_object co ON ka.object_id = co.id
ORDER BY id DESC
LIMIT 5;-- =====================================================
-- Файл: create_ks2_act.sql
-- Назначение: Формирование акта выполненных работ (КС-2)
-- =====================================================

\c construction_company;

DO $$
DECLARE
    v_act_id INTEGER;
    v_act_number VARCHAR(50);
    v_current_month INTEGER := EXTRACT(MONTH FROM CURRENT_DATE);
    v_current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    -- Генерация номера акта
    SELECT 'КС2-' || TO_CHAR(CURRENT_DATE, 'YYYYMM') || '-' ||
           LPAD(COALESCE(MAX(SUBSTRING(act_number FROM '\d+$'))::INT, 0) + 1::TEXT, 2, '0')
    INTO v_act_number
    FROM ks2_act
    WHERE act_number LIKE 'КС2-' || TO_CHAR(CURRENT_DATE, 'YYYYMM') || '%';

    -- Создание акта
    INSERT INTO ks2_act (
        act_number,
        act_date,
        contract_id,
        object_id,
        period_month,
        period_year,
        work_description,
        amount,
        vat_rate,
        vat_amount,
        total_amount,
        status,
        created_by_id
    ) VALUES (
        v_act_number,
        CURRENT_DATE,
        1,                          -- contract_id (ДГ-2025-045)
        1,                          -- object_id (ЖК Северное сияние)
        v_current_month,
        v_current_year,
        'Монтаж вентиляции 5-7 этажи',
        678000,
        20,
        135600,
        813600,
        'draft',
        2                           -- created_by_id (прораб Морозов)
    ) RETURNING id INTO v_act_id;

    RAISE NOTICE 'Акт КС-2 % успешно создан. Сумма: % руб.', v_act_number, 813600;
END $$;

-- Просмотр последних актов
SELECT
    act_number,
    act_date,
    co.name as object_name,
    work_description,
    total_amount,
    status
FROM ks2_act ka
JOIN construction_object co ON ka.object_id = co.id
ORDER BY id DESC
LIMIT 5;