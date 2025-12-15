CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS spock;

CREATE TABLE IF NOT EXISTS tariffs(
  id smallserial PRIMARY KEY,
  name text NOT NULL,
  price smallint NOT NULL,
  description text NOT NULL
);
COMMENT ON COLUMN tariffs.price IS 'price for one hour';

CREATE TABLE IF NOT EXISTS configurations(
  id serial PRIMARY KEY,
  tariff_id smallint NOT NULL,
  cpu text NOT NULL,
  gpu text NOT NULL,
  ram text NOT NULL,
  storage text NOT NULL,
  display text NOT NULL,
  mouse text NOT NULL,
  keyboard text NOT NULL,
  headset text NOT NULL,
  os text NOT NULL
);

CREATE TABLE IF NOT EXISTS gaming_seat_statuses(
  id smallserial PRIMARY KEY,
  status varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_request_status(
  id smallserial PRIMARY KEY,
  status varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS booking_statuses(
  id smallserial PRIMARY KEY,
  status varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS discount_statuses(
  id smallserial PRIMARY KEY,
  discount_percentage smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS job_titles(
  id smallserial PRIMARY KEY,
  title text NOT NULL,
  description text NOT NULL,
  access_rights text NOT NULL
);

CREATE TABLE IF NOT EXISTS clubs(
  id serial PRIMARY KEY,
  address text NOT NULL,
  phone_number char(11) NOT NULL,
  seat_count smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS employees(
  id serial PRIMARY KEY,
  job_title_id smallint NOT NULL,
  club_id smallint NOT NULL,
  name text NOT NULL,
  last_name text NOT NULL,
  patronymic text NULL,
  passport_data json NOT NULL,
  hire_date date NOT NULL,
  fire_date date NULL,
  salary integer NOT NULL,
  login varchar(30) NOT NULL UNIQUE,
  password_hash char(60) NOT NULL
);
COMMENT ON COLUMN employees.salary IS 'salary per month';
COMMENT ON COLUMN employees.password_hash IS 'bcrypt base64';

CREATE TABLE IF NOT EXISTS gaming_seats(
  id integer PRIMARY KEY,
  club_id smallint NOT NULL,
  configuration_id integer NOT NULL,
  status_id smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS bookings(
  id integer PRIMARY KEY,
  issuer_id integer NOT NULL,
  status_id smallint NOT NULL,
  gaming_seat_id integer NOT NULL,
  client_phone_number char(11) NOT NULL,
  creation_timestamp timestamp without time zone NOT NULL,
  start_timestamp timestamp without time zone NOT NULL,
  end_timestamp timestamp without time zone NOT NULL
);

ALTER TABLE bookings
  DROP CONSTRAINT IF EXISTS bookings_no_overlap;
ALTER TABLE bookings
  ADD CONSTRAINT bookings_no_overlap EXCLUDE USING gist (
    gaming_seat_id WITH =,
    tsrange(start_timestamp, end_timestamp) WITH &&
  );

CREATE TABLE IF NOT EXISTS sessions(
  id integer PRIMARY KEY,
  gaming_seat_id integer NOT NULL,
  client_phone_number char(11) NOT NULL,
  start_timestamp timestamp without time zone NOT NULL,
  end_timestamp timestamp without time zone NOT NULL,
  booking_id integer NULL
);

CREATE TABLE IF NOT EXISTS shift(
  id integer PRIMARY KEY,
  start_timestamp timestamp without time zone NOT NULL,
  end_timestamp timestamp without time zone NOT NULL,
  employee_id integer NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_requests(
  id integer PRIMARY KEY,
  creation_timestamp timestamp without time zone NOT NULL,
  gaming_seat_id integer NULL,
  status smallint NOT NULL,
  description text NOT NULL,
  executor_id integer NULL,
  issuer_id integer NOT NULL,
  -- version or last_modified for conflict detection:
  last_modified timestamp without time zone NOT NULL DEFAULT now(),
  -- workflow control: кто имеет право редактировать (club_id или 0 для центра)
  locked_by smallint NOT NULL DEFAULT 0,
  -- история передачи прав
  lock_history jsonb DEFAULT '[]'::jsonb
);
COMMENT ON COLUMN maintenance_requests.locked_by IS '0 = центральный офис, >0 = ID клуба, который может редактировать';
COMMENT ON COLUMN maintenance_requests.lock_history IS 'История передачи прав редактирования между узлами';

-- Drop and recreate clients table to ensure PRIMARY KEY exists
CREATE TABLE IF NOT EXISTS clients(
  phone_number char(11) PRIMARY KEY,
  discount_status smallint NOT NULL,
  password_hash char(60) NOT NULL,
  registration_timestamp timestamp without time zone NOT NULL,
  last_modified timestamp without time zone NOT NULL DEFAULT now()
);
COMMENT ON COLUMN clients.password_hash IS 'bcrypt base64';
COMMENT ON COLUMN clients.last_modified IS 'Timestamp of last modification for conflict resolution';

-- Required for master-master replication with Spock
--ALTER TABLE clients REPLICA IDENTITY FULL;

-- Триггер для автоматического обновления last_modified при изменении клиента
CREATE OR REPLACE FUNCTION trg_clients_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_modified = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_clients_update_timestamp ON clients;
CREATE TRIGGER trg_clients_update_timestamp
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION trg_clients_update_timestamp();

-- ============================================
-- Таблица уведомлений для администраторов
-- ============================================
CREATE TABLE IF NOT EXISTS admin_notifications(
  id serial PRIMARY KEY,
  club_id smallint NOT NULL,
  message text NOT NULL,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false
);

-- ============================================
-- Таблица логирования конфликтов репликации
-- ============================================
CREATE TABLE IF NOT EXISTS replication_conflicts(
  id serial PRIMARY KEY,
  table_name text NOT NULL,
  conflict_type text NOT NULL,
  record_id text NOT NULL,
  local_data jsonb,
  remote_data jsonb,
  resolution text,
  created_at timestamp without time zone NOT NULL DEFAULT now(),
  resolved_at timestamp without time zone,
  resolved_by integer REFERENCES employees(id)
);
COMMENT ON TABLE replication_conflicts IS 'Логирование конфликтов репликации для ручного разрешения администратором';

-- ============================================
-- ТРИГГЕР 1: Автоматический вывод ПК из эксплуатации при ремонте
-- При создании заявки на ремонт ПК переводится в статус "На обслуживании"
-- ============================================
CREATE OR REPLACE FUNCTION trg_maintenance_request_created()
RETURNS TRIGGER AS $$
DECLARE
    maintenance_status_id smallint;
BEGIN
    -- Если заявка привязана к конкретному ПК
    IF NEW.gaming_seat_id IS NOT NULL THEN
        -- Получаем ID статуса "На обслуживании"
        SELECT id INTO maintenance_status_id 
        FROM gaming_seat_statuses 
        WHERE status = 'На обслуживании'
        LIMIT 1;
        
        IF maintenance_status_id IS NOT NULL THEN
            -- Переводим ПК в статус "На обслуживании"
            UPDATE gaming_seats 
            SET status_id = maintenance_status_id 
            WHERE id = NEW.gaming_seat_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_maintenance_request_created ON maintenance_requests;
CREATE TRIGGER trg_maintenance_request_created
    AFTER INSERT ON maintenance_requests
    FOR EACH ROW
    EXECUTE FUNCTION trg_maintenance_request_created();

-- ============================================
-- ТРИГГЕР 2: Возврат ПК в работу после ремонта
-- При завершении заявки ПК возвращается в статус "Активен"
-- ============================================
CREATE OR REPLACE FUNCTION trg_maintenance_request_completed()
RETURNS TRIGGER AS $$
DECLARE
    active_status_id smallint;
    completed_status_id smallint;
BEGIN
    -- Получаем ID статуса "Завершено" для заявок
    SELECT id INTO completed_status_id 
    FROM maintenance_request_status 
    WHERE status = 'Завершено'
    LIMIT 1;
    
    -- Если статус заявки изменился на "Завершено" и есть привязка к ПК
    IF NEW.status = completed_status_id 
       AND OLD.status != completed_status_id 
       AND NEW.gaming_seat_id IS NOT NULL THEN
        
        -- Получаем ID статуса "Активен" для ПК
        SELECT id INTO active_status_id 
        FROM gaming_seat_statuses 
        WHERE status = 'Активен'
        LIMIT 1;
        
        IF active_status_id IS NOT NULL THEN
            -- Возвращаем ПК в активный статус
            UPDATE gaming_seats 
            SET status_id = active_status_id 
            WHERE id = NEW.gaming_seat_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_maintenance_request_completed ON maintenance_requests;
CREATE TRIGGER trg_maintenance_request_completed
    AFTER UPDATE ON maintenance_requests
    FOR EACH ROW
    EXECUTE FUNCTION trg_maintenance_request_completed();

-- ============================================
-- ТРИГГЕР 3: Отмена броней при поломке ПК
-- При изменении статуса ПК на "На обслуживании" отменяются будущие брони
-- и создаётся уведомление для администратора
-- ============================================
CREATE OR REPLACE FUNCTION trg_gaming_seat_maintenance()
RETURNS TRIGGER AS $$
DECLARE
    maintenance_status_id smallint;
    cancelled_status_id smallint;
    cancelled_count integer;
    seat_club_id smallint;
BEGIN
    -- Получаем ID статуса "На обслуживании"
    SELECT id INTO maintenance_status_id 
    FROM gaming_seat_statuses 
    WHERE status = 'На обслуживании'
    LIMIT 1;
    
    -- Если статус изменился на "На обслуживании"
    IF NEW.status_id = maintenance_status_id 
       AND (OLD.status_id IS NULL OR OLD.status_id != maintenance_status_id) THEN
        
        -- Получаем ID статуса "Отменено" для бронирований
        SELECT id INTO cancelled_status_id 
        FROM booking_statuses 
        WHERE status = 'Отменено'
        LIMIT 1;
        
        IF cancelled_status_id IS NOT NULL THEN
            -- Отменяем все будущие бронирования на этот ПК
            UPDATE bookings 
            SET status_id = cancelled_status_id
            WHERE gaming_seat_id = NEW.id 
              AND start_timestamp > now()
              AND status_id != cancelled_status_id;
            
            GET DIAGNOSTICS cancelled_count = ROW_COUNT;
            
            -- Если были отменены брони — уведомляем администратора
            IF cancelled_count > 0 THEN
                -- Получаем club_id для уведомления
                SELECT club_id INTO seat_club_id FROM gaming_seats WHERE id = NEW.id;
                
                INSERT INTO admin_notifications (club_id, message)
                VALUES (
                    seat_club_id,
                    format('ПК #%s переведён на обслуживание. Отменено бронирований: %s', 
                           NEW.id, cancelled_count)
                );
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gaming_seat_maintenance ON gaming_seats;
CREATE TRIGGER trg_gaming_seat_maintenance
    AFTER UPDATE ON gaming_seats
    FOR EACH ROW
    EXECUTE FUNCTION trg_gaming_seat_maintenance();

-- ============================================
-- ТРИГГЕР 4: Запрет бронирования ПК на обслуживании
-- Нельзя создать бронь на ПК в статусе "На обслуживании"
-- ============================================
CREATE OR REPLACE FUNCTION trg_booking_check_seat_status()
RETURNS TRIGGER AS $$
DECLARE
    seat_status_id smallint;
    maintenance_status_id smallint;
BEGIN
    -- Получаем текущий статус ПК
    SELECT status_id INTO seat_status_id 
    FROM gaming_seats 
    WHERE id = NEW.gaming_seat_id;
    
    -- Получаем ID статуса "На обслуживании"
    SELECT id INTO maintenance_status_id 
    FROM gaming_seat_statuses 
    WHERE status = 'На обслуживании'
    LIMIT 1;
    
    -- Если ПК на обслуживании — запрещаем бронирование
    IF seat_status_id = maintenance_status_id THEN
        RAISE EXCEPTION 'Невозможно забронировать ПК #%: компьютер находится на обслуживании', 
                        NEW.gaming_seat_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_booking_check_seat_status ON bookings;
CREATE TRIGGER trg_booking_check_seat_status
    BEFORE INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION trg_booking_check_seat_status();

-- ============================================
-- ТРИГГЕР 5: Управление workflow для заявок на ремонт
-- Блокирует изменения заявки, если права редактирования у другого узла
-- ============================================
CREATE OR REPLACE FUNCTION trg_maintenance_request_workflow()
RETURNS TRIGGER AS $$
DECLARE
    current_club_id smallint;
BEGIN
    -- Определяем текущий узел (0 для центра, ID клуба для филиалов)
    -- Это значение должно быть установлено в session variable при подключении
    current_club_id := COALESCE(current_setting('app.current_club_id', true)::smallint, 0);
    
    -- При UPDATE проверяем права на редактирование
    IF TG_OP = 'UPDATE' THEN
        -- Если заявка заблокирована другим узлом
        IF OLD.locked_by != current_club_id THEN
            RAISE EXCEPTION 'Заявка #% заблокирована для редактирования узлом %. Текущий узел: %',
                            OLD.id, OLD.locked_by, current_club_id;
        END IF;
        
        -- Обновляем last_modified
        NEW.last_modified = now();
        
        -- Если назначается исполнитель (центральный офис), передаём права обратно клубу
        IF NEW.executor_id IS NOT NULL AND OLD.executor_id IS NULL THEN
            -- Получаем club_id из gaming_seat
            IF NEW.gaming_seat_id IS NOT NULL THEN
                SELECT club_id INTO NEW.locked_by
                FROM gaming_seats
                WHERE id = NEW.gaming_seat_id;
                
                -- Логируем передачу прав
                NEW.lock_history = NEW.lock_history || jsonb_build_object(
                    'timestamp', now(),
                    'from', OLD.locked_by,
                    'to', NEW.locked_by,
                    'reason', 'executor_assigned'
                );
            END IF;
        END IF;
    END IF;
    
    -- При INSERT устанавливаем locked_by = club_id создателя
    IF TG_OP = 'INSERT' THEN
        NEW.locked_by = current_club_id;
        NEW.last_modified = now();
        NEW.lock_history = jsonb_build_array(
            jsonb_build_object(
                'timestamp', now(),
                'locked_by', current_club_id,
                'reason', 'created'
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_maintenance_request_workflow ON maintenance_requests;
CREATE TRIGGER trg_maintenance_request_workflow
    BEFORE INSERT OR UPDATE ON maintenance_requests
    FOR EACH ROW
    EXECUTE FUNCTION trg_maintenance_request_workflow();

-- ============================================
-- ТРИГГЕР 6: Логирование конфликтов дублирования клиентов
-- При попытке вставки дублирующегося клиента логируем конфликт
-- ============================================
CREATE OR REPLACE FUNCTION trg_log_client_conflict()
RETURNS TRIGGER AS $$
DECLARE
    existing_client clients%ROWTYPE;
    current_club_id smallint;
BEGIN
    current_club_id := COALESCE(current_setting('app.current_club_id', true)::smallint, 0);
    
    -- Проверяем, существует ли уже клиент с таким номером
    SELECT * INTO existing_client FROM clients WHERE phone_number = NEW.phone_number;
    
    IF FOUND THEN
        -- Логируем конфликт
        INSERT INTO replication_conflicts (
            table_name,
            conflict_type,
            record_id,
            local_data,
            remote_data,
            resolution
        ) VALUES (
            'clients',
            'duplicate_insert',
            NEW.phone_number,
            row_to_json(existing_client)::jsonb,
            row_to_json(NEW)::jsonb,
            'Используется существующая запись (first_wins)'
        );
        
        -- Уведомляем администратора
        INSERT INTO admin_notifications (club_id, message)
        VALUES (
            current_club_id,
            format('Обнаружен конфликт дублирования клиента: %s. Проверьте таблицу replication_conflicts',
                   NEW.phone_number)
        );
        
        -- Возвращаем существующую запись (first_wins стратегия)
        RETURN NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_client_conflict ON clients;
CREATE TRIGGER trg_log_client_conflict
    BEFORE INSERT ON clients
    FOR EACH ROW
    EXECUTE FUNCTION trg_log_client_conflict();

-- ============================================
-- ТРИГГЕР 7: Логирование конфликтов обновления клиентов
-- При конфликтующих обновлениях данных клиента логируем для ручного разрешения
-- ============================================
CREATE OR REPLACE FUNCTION trg_log_client_update_conflict()
RETURNS TRIGGER AS $$
DECLARE
    current_club_id smallint;
BEGIN
    current_club_id := COALESCE(current_setting('app.current_club_id', true)::smallint, 0);
    
    -- Если изменились критичные поля (не last_modified)
    IF (OLD.discount_status != NEW.discount_status OR
        OLD.password_hash != NEW.password_hash) THEN
        
        -- Проверяем, не было ли недавнего изменения с другого узла
        -- (разница во времени меньше 1 минуты может указывать на конфликт)
        IF (now() - OLD.last_modified) < interval '1 minute' THEN
            -- Логируем потенциальный конфликт
            INSERT INTO replication_conflicts (
                table_name,
                conflict_type,
                record_id,
                local_data,
                remote_data,
                resolution
            ) VALUES (
                'clients',
                'concurrent_update',
                NEW.phone_number,
                row_to_json(OLD)::jsonb,
                row_to_json(NEW)::jsonb,
                'Применено обновление с last_modified: ' || NEW.last_modified
            );
            
            -- Уведомляем администратора
            INSERT INTO admin_notifications (club_id, message)
            VALUES (
                current_club_id,
                format('Обнаружен конфликт обновления данных клиента: %s. Проверьте таблицу replication_conflicts',
                       NEW.phone_number)
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_client_update_conflict ON clients;
CREATE TRIGGER trg_log_client_update_conflict
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION trg_log_client_update_conflict();
