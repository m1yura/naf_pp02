-- =====================================================
-- Файл: create_contract.sql
-- Назначение: Регистрация нового договора (с заказчиком или субподрядчиком)
-- =====================================================

\c construction_company;

-- Параметры договора
WITH contract_data AS (
    SELECT
        'ДГ-2026-' || LPAD(COALESCE(MAX(SUBSTRING(contract_number FROM '\d+$'))::INT, 0) + 1::TEXT, 3, '0') as new_number,
        CURRENT_DATE as doc_date,
        1 as obj_id,           -- объект ЖК Северное сияние
        1 as customer_id,      -- заказчик ООО "ИнвестСтрой"
        'general_contract' as c_type,
        12500000 as summ,
        CURRENT_DATE + 7 as start_d,
        '2026-12-31' as end_d
    FROM contract
    WHERE contract_number LIKE 'ДГ-2026-%'
)
INSERT INTO contract (
    contract_number,
    contract_date,
    object_id,
    counterparty_id,
    contract_type,
    amount,
    start_date,
    end_date,
    status
)
SELECT
    new_number,
    doc_date,
    obj_id,
    customer_id,
    c_type,
    summ,
    start_d,
    end_d,
    'draft'
FROM contract_data
RETURNING id, contract_number, amount, status;

-- Добавление дополнительного соглашения (пример)
INSERT INTO contract (
    contract_number,
    contract_date,
    object_id,
    counterparty_id,
    contract_type,
    amount,
    start_date,
    end_date,
    status
) VALUES (
    'ДС-2026-001',
    CURRENT_DATE,
    1,
    3,           -- субподрядчик ООО "Монолит-Сервис"
    'subcontract',
    3450000,
    CURRENT_DATE,
    '2026-06-30',
    'draft'
) RETURNING id, contract_number, amount;