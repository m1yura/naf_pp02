-- =====================================================
-- Файл: add_client.sql
-- Назначение: Добавление нового контрагента (заказчика/подрядчика/поставщика)
-- Параметры: название, ИНН, тип, контакты
-- =====================================================

\c construction_company;

-- Параметры вставки (измените под вашу задачу)
INSERT INTO counterparty (
    name,
    inn,
    kpp,
    type,
    phone,
    email,
    legal_address,
    actual_address,
    bank_details,
    is_active
) VALUES (
    'ООО "СтройИнвест-Капитал"',  -- name
    '7712345678',                  -- inn
    '771201001',                  -- kpp
    'customer',                   -- type (customer/subcontractor/supplier/investor)
    '+74959998877',              -- phone
    'info@stroiinvest.ru',       -- email
    'г. Москва, ул. Мясницкая, 30', -- legal_address
    'г. Москва, ул. Мясницкая, 30', -- actual_address
    'р/с 40702810123450000000 в ПАО Сбербанк, БИК 044525225', -- bank_details
    true                         -- is_active
) RETURNING id, name, inn, type;

-- Проверка: вывести всех заказчиков
SELECT id, name, inn, phone, email
FROM counterparty
WHERE type = 'customer'
  AND is_active = true
ORDER BY id DESC;