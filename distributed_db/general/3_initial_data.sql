-- Статусы заявок на обслуживание
INSERT INTO maintenance_request_status (id, status) VALUES
    (1, 'Создана'),
    (2, 'В работе'),
    (3, 'Завершено'),
    (4, 'Отменено')
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- Статусы игровых мест
INSERT INTO gaming_seat_statuses (id, status) VALUES
    (1, 'Доступно'),
    (2, 'Занято'),
    (3, 'На обслуживании'),
    (4, 'Неисправно')
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- Статусы бронирований
INSERT INTO booking_statuses (id, status) VALUES
    (1, 'Активно'),
    (2, 'Завершено'),
    (3, 'Отменено')
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- Статусы скидок
INSERT INTO discount_statuses (id, discount_percentage) VALUES
    (1, 0),
    (2, 5),
    (3, 10),
    (4, 15),
    (5, 20)
ON CONFLICT (id) DO UPDATE SET discount_percentage = EXCLUDED.discount_percentage;