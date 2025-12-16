-- Игровые места для клуба 2 (20 мест)
INSERT INTO gaming_seats (club_id, configuration_id, status_id) VALUES
    (2, 1, 1), (2, 1, 1), (2, 1, 1), (2, 1, 1), (2, 1, 1),
    (2, 2, 1), (2, 2, 1), (2, 2, 1), (2, 2, 1), (2, 2, 1),
    (2, 2, 1), (2, 2, 1), (2, 2, 1), (2, 2, 1), (2, 2, 1),
    (2, 3, 1), (2, 3, 1), (2, 3, 1),
    (2, 4, 1), (2, 4, 1);

-- Клиенты клуба 2 (100 клиентов)
DO $$
DECLARE
    i INT;
    phone TEXT;
    discount INT;
BEGIN
    FOR i IN 1..100 LOOP
        phone := '7916200' || LPAD(i::TEXT, 4, '0');
        discount := CASE 
            WHEN i % 20 = 0 THEN 5
            WHEN i % 15 = 0 THEN 4
            WHEN i % 10 = 0 THEN 3
            WHEN i % 5 = 0 THEN 2
            ELSE 1
        END;
        INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp)
        VALUES (phone, discount, '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 
                '2023-01-01'::timestamp + (i || ' days')::interval)
        ON CONFLICT (phone_number) DO NOTHING;
    END LOOP;
END $$;

-- Бронирования (10 броней)
INSERT INTO bookings (issuer_id, status_id, gaming_seat_id, client_phone_number, creation_timestamp, start_timestamp, end_timestamp) VALUES
    (14, 1, 2, '79162000001', '2024-12-15 10:00:00', '2024-12-17 14:00:00', '2024-12-17 17:00:00'),
    (14, 1, 6, '79162000002', '2024-12-15 11:00:00', '2024-12-17 15:00:00', '2024-12-17 18:00:00'),
    (15, 1, 10, '79162000003', '2024-12-15 12:00:00', '2024-12-17 16:00:00', '2024-12-17 19:00:00'),
    (14, 2, 14, '79162000004', '2024-12-14 09:00:00', '2024-12-15 10:00:00', '2024-12-15 13:00:00'),
    (15, 2, 18, '79162000005', '2024-12-14 10:00:00', '2024-12-15 14:00:00', '2024-12-15 17:00:00'),
    (14, 1, 22, '79162000006', '2024-12-16 08:00:00', '2024-12-18 10:00:00', '2024-12-18 13:00:00'),
    (15, 1, 26, '79162000007', '2024-12-16 09:00:00', '2024-12-18 14:00:00', '2024-12-18 17:00:00'),
    (14, 1, 30, '79162000008', '2024-12-16 10:00:00', '2024-12-18 18:00:00', '2024-12-18 21:00:00'),
    (15, 3, 34, '79162000009', '2024-12-13 15:00:00', '2024-12-14 12:00:00', '2024-12-14 15:00:00'),
    (14, 3, 38, '79162000010', '2024-12-13 16:00:00', '2024-12-14 16:00:00', '2024-12-14 19:00:00');

-- Игровые сессии (50 сессий)
DO $$
DECLARE
    i INT;
    seat_id INT;
    phone TEXT;
    start_ts TIMESTAMP;
    duration INT;
BEGIN
    FOR i IN 1..50 LOOP
        seat_id := ((i - 1) % 20) * 4 + 2;
        phone := '7916200' || LPAD(((i - 1) % 100 + 1)::TEXT, 4, '0');
        start_ts := '2024-12-01'::timestamp + ((i - 1) * 6 || ' hours')::interval;
        duration := 2 + (i % 4);
        
        INSERT INTO sessions (gaming_seat_id, client_phone_number, start_timestamp, end_timestamp, booking_id)
        VALUES (seat_id, phone, start_ts, start_ts + (duration || ' hours')::interval, NULL);
    END LOOP;
END $$;

-- Смены (30 смен)
DO $$
DECLARE
    i INT;
    emp_id INT;
    start_ts TIMESTAMP;
BEGIN
    FOR i IN 1..30 LOOP
        emp_id := 14 + ((i - 1) % 3);
        start_ts := '2024-12-01'::timestamp + ((i - 1) * 8 || ' hours')::interval;
        
        INSERT INTO shift (start_timestamp, end_timestamp, employee_id)
        VALUES (start_ts, start_ts + '8 hours'::interval, emp_id);
    END LOOP;
END $$;

-- Заявки на обслуживание (1 заявка)
INSERT INTO maintenance_requests (creation_timestamp, gaming_seat_id, club_id, status, description, executor_id, issuer_id, last_modified) VALUES
    ('2024-12-15 11:00:00', 18, 2, 2, 'Проблема с клавиатурой на месте 18', 16, 14, '2024-12-15 11:30:00');
