-- =====================================================
-- Файл: create_db.sql
-- Назначение: ПОЛНОЕ создание базы данных строительной компании
-- =====================================================

-- Создание базы данных
CREATE DATABASE construction_company
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    CONNECTION LIMIT = -1;

\c construction_company;

-- -----------------------------------------------------
-- 1. Контрагенты (заказчики, подрядчики, поставщики)
-- -----------------------------------------------------
CREATE TABLE counterparty (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    inn VARCHAR(12) UNIQUE,
    kpp VARCHAR(9),
    type VARCHAR(50) NOT NULL CHECK (type IN ('customer', 'subcontractor', 'supplier', 'investor')),
    phone VARCHAR(20),
    email VARCHAR(100),
    legal_address TEXT,
    actual_address TEXT,
    bank_details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- -----------------------------------------------------
-- 2. Сотрудники
-- -----------------------------------------------------
CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    position VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    hire_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    login VARCHAR(50) UNIQUE
);

-- -----------------------------------------------------
-- 3. Строительные объекты
-- -----------------------------------------------------
CREATE TABLE construction_object (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES counterparty(id),
    project_status VARCHAR(50) NOT NULL DEFAULT 'design'
        CHECK (project_status IN ('design', 'expertise', 'preparatory', 'zero_cycle',
                                  'framing', 'roofing', 'finishing', 'commissioning', 'warranty')),
    planned_start_date DATE NOT NULL,
    planned_end_date DATE NOT NULL,
    actual_start_date DATE,
    actual_end_date DATE,
    total_contract_amount DECIMAL(15,2),
    responsible_engineer_id INTEGER REFERENCES employee(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- 4. Договоры
-- -----------------------------------------------------
CREATE TABLE contract (
    id SERIAL PRIMARY KEY,
    contract_number VARCHAR(50) NOT NULL,
    contract_date DATE NOT NULL,
    object_id INTEGER NOT NULL REFERENCES construction_object(id),
    counterparty_id INTEGER NOT NULL REFERENCES counterparty(id),
    contract_type VARCHAR(50) NOT NULL CHECK (contract_type IN ('general_contract', 'subcontract', 'supply', 'service')),
    amount DECIMAL(15,2) NOT NULL,
    amount_paid DECIMAL(15,2) DEFAULT 0,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'draft'
        CHECK (status IN ('draft', 'active', 'suspended', 'completed', 'terminated')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- 5. Материалы
-- -----------------------------------------------------
CREATE TABLE material (
    id SERIAL PRIMARY KEY,
    article VARCHAR(50) UNIQUE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    purchase_price DECIMAL(12,2),
    estimated_price DECIMAL(12,2),
    supplier_id INTEGER REFERENCES counterparty(id),
    delivery_time_days INTEGER,
    min_stock_level DECIMAL(12,2)
);

-- -----------------------------------------------------
-- 6. Склады
-- -----------------------------------------------------
CREATE TABLE warehouse (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) CHECK (type IN ('central', 'on_site', 'transit')),
    object_id INTEGER REFERENCES construction_object(id),
    address TEXT,
    manager_id INTEGER REFERENCES employee(id)
);

CREATE TABLE warehouse_stock (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL REFERENCES warehouse(id),
    material_id INTEGER NOT NULL REFERENCES material(id),
    quantity DECIMAL(15,3) NOT NULL DEFAULT 0,
    reserved_quantity DECIMAL(15,3) DEFAULT 0,
    unit_price DECIMAL(12,2),
    last_movement_date TIMESTAMP,
    UNIQUE(warehouse_id, material_id)
);

-- -----------------------------------------------------
-- 7. Заявки на материалы
-- -----------------------------------------------------
CREATE TABLE material_request (
    id SERIAL PRIMARY KEY,
    request_number VARCHAR(50) UNIQUE NOT NULL,
    object_id INTEGER NOT NULL REFERENCES construction_object(id),
    requester_id INTEGER NOT NULL REFERENCES employee(id),
    created_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'draft'
        CHECK (status IN ('draft', 'approved', 'rejected', 'completed', 'cancelled')),
    priority VARCHAR(20) CHECK (priority IN ('low', 'normal', 'high', 'critical')),
    approved_by_id INTEGER REFERENCES employee(id),
    notes TEXT
);

CREATE TABLE material_request_item (
    id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES material_request(id) ON DELETE CASCADE,
    material_id INTEGER NOT NULL REFERENCES material(id),
    quantity_required DECIMAL(15,3) NOT NULL,
    quantity_supplied DECIMAL(15,3) DEFAULT 0,
    unit VARCHAR(20) NOT NULL,
    purpose TEXT
);

-- -----------------------------------------------------
-- 8. Акты КС-2
-- -----------------------------------------------------
CREATE TABLE ks2_act (
    id SERIAL PRIMARY KEY,
    act_number VARCHAR(50) NOT NULL,
    act_date DATE NOT NULL,
    contract_id INTEGER NOT NULL REFERENCES contract(id),
    object_id INTEGER NOT NULL REFERENCES construction_object(id),
    period_month INTEGER NOT NULL,
    period_year INTEGER NOT NULL,
    work_description TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    vat_rate INTEGER DEFAULT 20,
    vat_amount DECIMAL(15,2),
    total_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'draft'
        CHECK (status IN ('draft', 'checking', 'approved', 'signed', 'paid')),
    created_by_id INTEGER REFERENCES employee(id),
    signed_date DATE
);

-- -----------------------------------------------------
-- Индексы
-- -----------------------------------------------------
CREATE INDEX idx_object_status ON construction_object(project_status);
CREATE INDEX idx_contract_object ON contract(object_id);
CREATE INDEX idx_material_request_object ON material_request(object_id);
CREATE INDEX idx_material_request_status ON material_request(status);
CREATE INDEX idx_ks2_contract ON ks2_act(contract_id);
CREATE INDEX idx_warehouse_stock_material ON warehouse_stock(material_id);

-- -----------------------------------------------------
-- Функция обновления updated_at
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_construction_object
    BEFORE UPDATE ON construction_object
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------
-- Вставка тестовых справочников
-- -----------------------------------------------------
INSERT INTO employee (full_name, position, department, phone, email, hire_date, login) VALUES
('Соколов Иван Петрович', 'Начальник ПТО', 'ПТО', '+79161112233', 'sokolov@company.ru', '2020-03-15', 'sokolov'),
('Морозов Андрей Викторович', 'Прораб', 'Участок №1', '+79162223344', 'morozov@company.ru', '2019-08-20', 'morozov'),
('Волкова Елена Сергеевна', 'Сметчик', 'СДО', '+79163334455', 'volkova@company.ru', '2021-01-10', 'volkova'),
('Козлов Дмитрий Олегович', 'Снабженец', 'ОМТС', '+79165556677', 'kozlov@company.ru', '2020-05-25', 'kozlov');

SELECT 'База данных construction_company успешно создана!' AS message;