-- Клубы (3 клуба + центральный офис)
INSERT INTO clubs (id, address, phone_number, seat_count) VALUES
    (0, 'Москва, ул. Центральная, д. 1', '74951234567', 0),
    (1, 'Москва, ул. Ленина, д. 10', '74951111111', 20),
    (2, 'Москва, ул. Пушкина, д. 25', '74952222222', 20),
    (3, 'Москва, ул. Гагарина, д. 50', '74953333333', 20)
ON CONFLICT (id) DO UPDATE SET 
    address = EXCLUDED.address,
    phone_number = EXCLUDED.phone_number,
    seat_count = EXCLUDED.seat_count;

-- Должности
INSERT INTO job_titles (id, title, description, access_rights) VALUES
    (1, 'Администратор', 'Управление клубом, работа с клиентами', 'read,write,bookings,sessions'),
    (2, 'Технический специалист', 'Обслуживание оборудования', 'read,maintenance'),
    (3, 'Менеджер', 'Управление персоналом и операциями', 'read,write,reports,staff'),
    (4, 'Директор', 'Общее руководство', 'full_access'),
    (5, 'Бухгалтер', 'Финансовый учет', 'read,finance')
ON CONFLICT (id) DO UPDATE SET 
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    access_rights = EXCLUDED.access_rights;

-- Тарифы
INSERT INTO tariffs (id, name, price, description) VALUES
    (1, 'Эконом', 150, 'Базовая конфигурация для казуальных игр'),
    (2, 'Стандарт', 250, 'Средняя конфигурация для большинства игр'),
    (3, 'VIP', 400, 'Топовая конфигурация для требовательных игр')
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    price = EXCLUDED.price,
    description = EXCLUDED.description;

-- Конфигурации оборудования
INSERT INTO configurations (id, tariff_id, cpu, gpu, ram, storage, display, mouse, keyboard, headset, os) VALUES
    (1, 1, 'Intel Core i3-12100F', 'NVIDIA GTX 1650', '16GB DDR4', '512GB SSD', 'AOC 24" 144Hz', 'Logitech G102', 'Logitech K120', 'HyperX Cloud Stinger', 'Windows 11'),
    (2, 2, 'Intel Core i5-12400F', 'NVIDIA RTX 3060', '16GB DDR4', '1TB SSD', 'AOC 27" 165Hz', 'Logitech G305', 'HyperX Alloy Core', 'HyperX Cloud II', 'Windows 11'),
    (3, 3, 'Intel Core i7-13700K', 'NVIDIA RTX 4070', '32GB DDR5', '2TB NVMe SSD', 'ASUS 27" 240Hz', 'Logitech G Pro', 'HyperX Alloy FPS Pro', 'HyperX Cloud Alpha', 'Windows 11'),
    (4, 3, 'AMD Ryzen 9 7900X', 'NVIDIA RTX 4080', '32GB DDR5', '2TB NVMe SSD', 'ASUS 32" 240Hz', 'Razer DeathAdder V3', 'Razer BlackWidow V3', 'SteelSeries Arctis 7', 'Windows 11')
ON CONFLICT (id) DO UPDATE SET 
    tariff_id = EXCLUDED.tariff_id,
    cpu = EXCLUDED.cpu,
    gpu = EXCLUDED.gpu,
    ram = EXCLUDED.ram,
    storage = EXCLUDED.storage,
    display = EXCLUDED.display,
    mouse = EXCLUDED.mouse,
    keyboard = EXCLUDED.keyboard,
    headset = EXCLUDED.headset,
    os = EXCLUDED.os;

-- Сотрудники центрального офиса (10 человек)
INSERT INTO employees (id, job_title_id, club_id, name, last_name, patronymic, passport_data, hire_date, fire_date, salary, login, password_hash) VALUES
    (1, 4, 0, 'Иван', 'Петров', 'Сергеевич', '{"series": "4510", "number": "123456", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2015-03-15"}'::json, '2020-01-15', NULL, 150000, 'director', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (2, 3, 0, 'Мария', 'Иванова', 'Петровна', '{"series": "4511", "number": "234567", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2016-05-20"}'::json, '2020-03-01', NULL, 100000, 'manager1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (3, 3, 0, 'Алексей', 'Смирнов', 'Владимирович', '{"series": "4512", "number": "345678", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2017-07-10"}'::json, '2020-06-15', NULL, 95000, 'manager2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (4, 5, 0, 'Елена', 'Козлова', 'Андреевна', '{"series": "4513", "number": "456789", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2018-02-25"}'::json, '2021-01-10', NULL, 80000, 'accountant1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (5, 5, 0, 'Дмитрий', 'Новиков', 'Игоревич', '{"series": "4514", "number": "567890", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2019-04-12"}'::json, '2021-03-20', NULL, 75000, 'accountant2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (6, 2, 0, 'Сергей', 'Волков', 'Николаевич', '{"series": "4515", "number": "678901", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2018-08-30"}'::json, '2021-05-01', NULL, 70000, 'tech_central1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (7, 2, 0, 'Ольга', 'Морозова', 'Викторовна', '{"series": "4516", "number": "789012", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2019-11-15"}'::json, '2021-07-15', NULL, 70000, 'tech_central2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (8, 1, 0, 'Андрей', 'Соколов', 'Дмитриевич', '{"series": "4517", "number": "890123", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2020-01-20"}'::json, '2022-01-10', NULL, 60000, 'admin_central1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (9, 1, 0, 'Наталья', 'Лебедева', 'Александровна', '{"series": "4518", "number": "901234", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2020-06-05"}'::json, '2022-03-01', NULL, 60000, 'admin_central2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (10, 1, 0, 'Павел', 'Егоров', 'Сергеевич', '{"series": "4519", "number": "012345", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2021-03-18"}'::json, '2022-06-15', NULL, 55000, 'admin_central3', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy')
ON CONFLICT (id) DO UPDATE SET 
    job_title_id = EXCLUDED.job_title_id,
    club_id = EXCLUDED.club_id,
    name = EXCLUDED.name,
    last_name = EXCLUDED.last_name,
    patronymic = EXCLUDED.patronymic,
    passport_data = EXCLUDED.passport_data,
    hire_date = EXCLUDED.hire_date,
    fire_date = EXCLUDED.fire_date,
    salary = EXCLUDED.salary,
    login = EXCLUDED.login,
    password_hash = EXCLUDED.password_hash;

-- Сотрудники клуба 1 (3 человека)
INSERT INTO employees (id, job_title_id, club_id, name, last_name, patronymic, passport_data, hire_date, fire_date, salary, login, password_hash) VALUES
    (11, 1, 1, 'Виктор', 'Кузнецов', 'Павлович', '{"series": "4520", "number": "111111", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2019-02-10"}'::json, '2021-09-01', NULL, 55000, 'admin_club1_1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (12, 1, 1, 'Татьяна', 'Федорова', 'Игоревна', '{"series": "4521", "number": "222222", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2020-04-22"}'::json, '2022-01-15', NULL, 50000, 'admin_club1_2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (13, 2, 1, 'Максим', 'Орлов', 'Викторович', '{"series": "4522", "number": "333333", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2018-09-15"}'::json, '2021-11-01', NULL, 60000, 'tech_club1_1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy')
ON CONFLICT (id) DO UPDATE SET 
    job_title_id = EXCLUDED.job_title_id,
    club_id = EXCLUDED.club_id,
    name = EXCLUDED.name,
    last_name = EXCLUDED.last_name,
    patronymic = EXCLUDED.patronymic,
    passport_data = EXCLUDED.passport_data,
    hire_date = EXCLUDED.hire_date,
    fire_date = EXCLUDED.fire_date,
    salary = EXCLUDED.salary,
    login = EXCLUDED.login,
    password_hash = EXCLUDED.password_hash;

-- Сотрудники клуба 2 (3 человека)
INSERT INTO employees (id, job_title_id, club_id, name, last_name, patronymic, passport_data, hire_date, fire_date, salary, login, password_hash) VALUES
    (14, 1, 2, 'Роман', 'Павлов', 'Алексеевич', '{"series": "4523", "number": "444444", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2019-07-08"}'::json, '2021-10-01', NULL, 55000, 'admin_club2_1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (15, 1, 2, 'Юлия', 'Романова', 'Сергеевна', '{"series": "4524", "number": "555555", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2020-11-30"}'::json, '2022-02-01', NULL, 50000, 'admin_club2_2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (16, 2, 2, 'Артем', 'Зайцев', 'Владимирович', '{"series": "4525", "number": "666666", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2018-12-12"}'::json, '2021-12-01', NULL, 60000, 'tech_club2_1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy')
ON CONFLICT (id) DO UPDATE SET 
    job_title_id = EXCLUDED.job_title_id,
    club_id = EXCLUDED.club_id,
    name = EXCLUDED.name,
    last_name = EXCLUDED.last_name,
    patronymic = EXCLUDED.patronymic,
    passport_data = EXCLUDED.passport_data,
    hire_date = EXCLUDED.hire_date,
    fire_date = EXCLUDED.fire_date,
    salary = EXCLUDED.salary,
    login = EXCLUDED.login,
    password_hash = EXCLUDED.password_hash;

-- Сотрудники клуба 3 (3 человека)
INSERT INTO employees (id, job_title_id, club_id, name, last_name, patronymic, passport_data, hire_date, fire_date, salary, login, password_hash) VALUES
    (17, 1, 3, 'Константин', 'Медведев', 'Андреевич', '{"series": "4526", "number": "777777", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2019-05-25"}'::json, '2021-08-15', NULL, 55000, 'admin_club3_1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (18, 1, 3, 'Анна', 'Белова', 'Дмитриевна', '{"series": "4527", "number": "888888", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2020-08-14"}'::json, '2022-03-15', NULL, 50000, 'admin_club3_2', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
    (19, 2, 3, 'Игорь', 'Соловьев', 'Николаевич', '{"series": "4528", "number": "999999", "issued_by": "ОУФМС России по г. Москве", "issue_date": "2018-10-05"}'::json, '2021-10-15', NULL, 60000, 'tech_club3_1', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy')
ON CONFLICT (id) DO UPDATE SET 
    job_title_id = EXCLUDED.job_title_id,
    club_id = EXCLUDED.club_id,
    name = EXCLUDED.name,
    last_name = EXCLUDED.last_name,
    patronymic = EXCLUDED.patronymic,
    passport_data = EXCLUDED.passport_data,
    hire_date = EXCLUDED.hire_date,
    fire_date = EXCLUDED.fire_date,
    salary = EXCLUDED.salary,
    login = EXCLUDED.login,
    password_hash = EXCLUDED.password_hash;