-- ============================================
-- ТРИГГЕРЫ ДЛЯ СИСТЕМЫ КОМПЬЮТЕРНОГО КЛУБА
-- ============================================

-- ============================================
-- ТРИГГЕР 1: Блокировка редактирования заявок в клубах
-- ============================================

-- Trigger function to block club edits when status is 'Создана' (1)
CREATE OR REPLACE FUNCTION check_maintenance_request_edit()
RETURNS TRIGGER AS $$
DECLARE
    spock_node_name TEXT;
BEGIN
    -- Get current Spock node name
    SELECT node_name INTO spock_node_name 
    FROM spock.node 
    LIMIT 1;
    
    -- Allow all operations in central node
    IF spock_node_name = 'central' THEN
        RETURN NEW;
    END IF;
    
    -- Block UPDATE in club databases when status is 'Создана' (1)
    IF TG_OP = 'UPDATE' AND OLD.status = 1 THEN
        RAISE EXCEPTION 'Невозможно редактировать заявку со статусом "Создана". Заявка находится на рассмотрении в центральном офисе.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER maintenance_request_edit_check
    BEFORE UPDATE ON maintenance_requests
    FOR EACH ROW
    EXECUTE FUNCTION check_maintenance_request_edit();

-- ============================================
-- ТРИГГЕР 2: Автоматический вывод ПК из эксплуатации при ремонте
-- ============================================

CREATE OR REPLACE FUNCTION set_gaming_seat_maintenance_on_request()
RETURNS TRIGGER AS $$
BEGIN
    -- При создании заявки на ремонт переводим ПК в статус "На обслуживании" (3)
    IF NEW.gaming_seat_id IS NOT NULL THEN
        UPDATE gaming_seats 
        SET status_id = 3 -- На обслуживании
        WHERE id = NEW.gaming_seat_id;
        
        RAISE NOTICE 'Игровое место % переведено в статус "На обслуживании"', NEW.gaming_seat_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gaming_seat_maintenance_on_request_create
    AFTER INSERT ON maintenance_requests
    FOR EACH ROW
    WHEN (NEW.gaming_seat_id IS NOT NULL)
    EXECUTE FUNCTION set_gaming_seat_maintenance_on_request();

-- ============================================
-- ТРИГГЕР 3: Возврат ПК в работу после ремонта
-- ============================================

CREATE OR REPLACE FUNCTION restore_gaming_seat_after_maintenance()
RETURNS TRIGGER AS $$
BEGIN
    -- При завершении заявки (статус 3 - Завершено) возвращаем ПК в статус "Доступно" (1)
    IF NEW.status = 3 AND OLD.status != 3 AND NEW.gaming_seat_id IS NOT NULL THEN
        UPDATE gaming_seats 
        SET status_id = 1 -- Доступно
        WHERE id = NEW.gaming_seat_id;
        
        RAISE NOTICE 'Игровое место % возвращено в статус "Доступно"', NEW.gaming_seat_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gaming_seat_restore_after_maintenance
    AFTER UPDATE ON maintenance_requests
    FOR EACH ROW
    WHEN (NEW.gaming_seat_id IS NOT NULL)
    EXECUTE FUNCTION restore_gaming_seat_after_maintenance();

-- ============================================
-- ТРИГГЕР 4: Отмена броней при поломке ПК
-- ============================================

CREATE OR REPLACE FUNCTION cancel_bookings_on_maintenance()
RETURNS TRIGGER AS $$
DECLARE
    cancelled_count INTEGER;
BEGIN
    -- При переводе ПК в статус "На обслуживании" (3) отменяем будущие бронирования
    IF NEW.status_id = 3 AND OLD.status_id != 3 THEN
        -- Отменяем только будущие бронирования (start_timestamp > NOW())
        UPDATE bookings 
        SET status_id = 3 -- Отменено
        WHERE gaming_seat_id = NEW.id 
            AND start_timestamp > NOW()
            AND status_id = 1; -- Только активные бронирования
        
        GET DIAGNOSTICS cancelled_count = ROW_COUNT;
        
        IF cancelled_count > 0 THEN
            RAISE NOTICE 'Отменено % будущих бронирований для игрового места %', cancelled_count, NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cancel_bookings_on_gaming_seat_maintenance
    AFTER UPDATE ON gaming_seats
    FOR EACH ROW
    WHEN (NEW.status_id = 3)
    EXECUTE FUNCTION cancel_bookings_on_maintenance();

-- ============================================
-- ТРИГГЕР 5: Блокировка создания броней для ПК на обслуживании
-- ============================================

CREATE OR REPLACE FUNCTION prevent_booking_on_maintenance()
RETURNS TRIGGER AS $$
DECLARE
    seat_status INTEGER;
BEGIN
    -- Проверяем статус игрового места
    SELECT status_id INTO seat_status
    FROM gaming_seats
    WHERE id = NEW.gaming_seat_id;
    
    -- Блокируем создание брони если ПК на обслуживании (3) или неисправен (4)
    IF seat_status IN (3, 4) THEN
        RAISE EXCEPTION 'Невозможно создать бронирование. Игровое место % находится на обслуживании или неисправно.', NEW.gaming_seat_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_booking_on_maintenance_check
    BEFORE INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION prevent_booking_on_maintenance();

-- ============================================
-- ТРИГГЕР 6: Автоматическое обновление last_modified
-- ============================================

CREATE OR REPLACE FUNCTION update_maintenance_request_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_maintenance_request_timestamp_trigger
    BEFORE UPDATE ON maintenance_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_maintenance_request_timestamp();

-- ============================================
-- ОБРАБОТЧИКИ КОНФЛИКТОВ SPOCK
-- ============================================

-- Таблица для логирования конфликтов
CREATE TABLE IF NOT EXISTS conflict_log (
    id SERIAL PRIMARY KEY,
    conflict_time TIMESTAMP NOT NULL DEFAULT NOW(),
    table_name TEXT NOT NULL,
    conflict_type TEXT NOT NULL,
    local_data JSONB,
    remote_data JSONB,
    resolution TEXT,
    resolved_by TEXT,
    resolved_at TIMESTAMP
);

-- ============================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ АДМИНИСТРАТОРОВ
-- ============================================

-- Функция для просмотра неразрешенных конфликтов
CREATE OR REPLACE FUNCTION get_unresolved_conflicts()
RETURNS TABLE (
    id INTEGER,
    conflict_time TIMESTAMP,
    table_name TEXT,
    conflict_type TEXT,
    local_data JSONB,
    remote_data JSONB,
    resolution TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cl.id,
        cl.conflict_time,
        cl.table_name,
        cl.conflict_type,
        cl.local_data,
        cl.remote_data,
        cl.resolution
    FROM conflict_log cl
    WHERE cl.resolved_at IS NULL
    ORDER BY cl.conflict_time DESC;
END;
$$ LANGUAGE plpgsql;

-- Функция для разрешения конфликта администратором
CREATE OR REPLACE FUNCTION resolve_conflict(
    conflict_id INTEGER,
    resolution_note TEXT,
    admin_name TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE conflict_log
    SET 
        resolved_by = admin_name,
        resolved_at = NOW(),
        resolution = resolution || E'\n' || 'Разрешено администратором: ' || resolution_note
    WHERE id = conflict_id;
    
    RAISE NOTICE 'Конфликт % разрешен администратором %', conflict_id, admin_name;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- КОММЕНТАРИИ К ТРИГГЕРАМ
-- ============================================

COMMENT ON FUNCTION check_maintenance_request_edit() IS 
'Блокирует редактирование заявок на обслуживание в клубах, когда статус "Создана"';

COMMENT ON FUNCTION set_gaming_seat_maintenance_on_request() IS 
'Автоматически переводит игровое место в статус "На обслуживании" при создании заявки на ремонт';

COMMENT ON FUNCTION restore_gaming_seat_after_maintenance() IS 
'Автоматически возвращает игровое место в статус "Доступно" после завершения ремонта';

COMMENT ON FUNCTION cancel_bookings_on_maintenance() IS 
'Отменяет будущие бронирования при переводе игрового места в статус "На обслуживании"';

COMMENT ON FUNCTION prevent_booking_on_maintenance() IS 
'Блокирует создание новых бронирований для игровых мест на обслуживании';

COMMENT ON TABLE conflict_log IS 
'Журнал конфликтов репликации для ручного разрешения администратором';