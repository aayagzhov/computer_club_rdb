-- ============================================
-- Начальные данные для справочников статусов
-- ============================================

-- Статусы игровых мест (ПК)
INSERT INTO gaming_seat_statuses (id, status) VALUES
    (1, 'Активен'),
    (2, 'На обслуживании'),
    (3, 'Выведен из эксплуатации')
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- Статусы заявок на обслуживание
INSERT INTO maintenance_request_status (id, status) VALUES
    (1, 'Создана'),
    (2, 'В работе'),
    (3, 'Завершено'),
    (4, 'Отменено')
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- Статусы бронирований
INSERT INTO booking_statuses (id, status) VALUES
    (1, 'Активно'),
    (2, 'Завершено'),
    (3, 'Отменено'),
    (4, 'Неявка')
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- Статусы скидок клиентов
INSERT INTO discount_statuses (id, discount_percentage) VALUES
    (1, 0),   -- Без скидки
    (2, 5),   -- Бронзовый
    (3, 10),  -- Серебряный
    (4, 15)   -- Золотой
ON CONFLICT (id) DO UPDATE SET discount_percentage = EXCLUDED.discount_percentage;
