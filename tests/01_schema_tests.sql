-- ============================================
-- ТЕСТЫ СХЕМЫ БАЗЫ ДАННЫХ
-- ============================================

\echo '============================================'
\echo 'TEST SUITE 1: Schema Tests'
\echo '============================================'

-- Создаем схему для тестов
CREATE SCHEMA IF NOT EXISTS test_results;

-- Таблица для результатов тестов
CREATE TABLE IF NOT EXISTS test_results.test_log (
    id SERIAL PRIMARY KEY,
    test_suite VARCHAR(100),
    test_name VARCHAR(200),
    status VARCHAR(20),
    message TEXT,
    executed_at TIMESTAMP DEFAULT NOW()
);

-- Функция для логирования результатов
CREATE OR REPLACE FUNCTION test_results.log_test(
    p_suite VARCHAR(100),
    p_name VARCHAR(200),
    p_status VARCHAR(20),
    p_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO test_results.test_log (test_suite, test_name, status, message)
    VALUES (p_suite, p_name, p_status, p_message);
END;
$$ LANGUAGE plpgsql;

\echo ''
\echo 'Test 1.1: Checking all required tables exist'

DO $$
DECLARE
    required_tables TEXT[] := ARRAY[
        'tariffs', 'configurations', 'gaming_seat_statuses',
        'maintenance_request_status', 'booking_statuses', 'discount_statuses',
        'job_titles', 'clubs', 'employees', 'gaming_seats',
        'bookings', 'sessions', 'shift', 'maintenance_requests', 'clients'
    ];
    table_name TEXT;
    table_exists BOOLEAN;
BEGIN
    FOREACH table_name IN ARRAY required_tables
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            PERFORM test_results.log_test('Schema', 'Table exists: ' || table_name, 'PASS');
        ELSE
            PERFORM test_results.log_test('Schema', 'Table exists: ' || table_name, 'FAIL', 'Table not found');
        END IF;
    END LOOP;
END $$;

\echo 'Test 1.2: Checking maintenance_requests has club_id column'

DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'maintenance_requests'
        AND column_name = 'club_id'
    ) INTO column_exists;
    
    IF column_exists THEN
        PERFORM test_results.log_test('Schema', 'maintenance_requests.club_id exists', 'PASS');
    ELSE
        PERFORM test_results.log_test('Schema', 'maintenance_requests.club_id exists', 'FAIL', 'Column not found');
    END IF;
END $$;

\echo 'Test 1.3: Checking REPLICA IDENTITY on maintenance_requests'

DO $$
DECLARE
    replica_identity TEXT;
BEGIN
    SELECT relreplident INTO replica_identity
    FROM pg_class
    WHERE relname = 'maintenance_requests';
    
    IF replica_identity = 'f' THEN
        PERFORM test_results.log_test('Schema', 'maintenance_requests REPLICA IDENTITY FULL', 'PASS');
    ELSE
        PERFORM test_results.log_test('Schema', 'maintenance_requests REPLICA IDENTITY FULL', 'FAIL', 
            'Expected FULL (f), got: ' || replica_identity);
    END IF;
END $$;

\echo 'Test 1.4: Checking primary keys'

DO $$
DECLARE
    pk_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO pk_count
    FROM information_schema.table_constraints
    WHERE constraint_type = 'PRIMARY KEY'
    AND table_schema = 'public';
    
    IF pk_count >= 15 THEN
        PERFORM test_results.log_test('Schema', 'Primary keys count', 'PASS', 
            'Found ' || pk_count || ' primary keys');
    ELSE
        PERFORM test_results.log_test('Schema', 'Primary keys count', 'FAIL', 
            'Expected at least 15, found ' || pk_count);
    END IF;
END $$;

\echo 'Test 1.5: Checking bookings_no_overlap constraint'

DO $$
DECLARE
    constraint_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM pg_constraint
        WHERE conname = 'bookings_no_overlap'
    ) INTO constraint_exists;
    
    IF constraint_exists THEN
        PERFORM test_results.log_test('Schema', 'bookings_no_overlap constraint', 'PASS');
    ELSE
        PERFORM test_results.log_test('Schema', 'bookings_no_overlap constraint', 'FAIL', 'Constraint not found');
    END IF;
END $$;

\echo 'Test 1.6: Checking initial data in reference tables'

DO $$
DECLARE
    status_count INTEGER;
BEGIN
    -- Check maintenance_request_status
    SELECT COUNT(*) INTO status_count FROM maintenance_request_status;
    IF status_count >= 4 THEN
        PERFORM test_results.log_test('Schema', 'maintenance_request_status data', 'PASS', 
            'Found ' || status_count || ' statuses');
    ELSE
        PERFORM test_results.log_test('Schema', 'maintenance_request_status data', 'FAIL', 
            'Expected at least 4, found ' || status_count);
    END IF;
    
    -- Check gaming_seat_statuses
    SELECT COUNT(*) INTO status_count FROM gaming_seat_statuses;
    IF status_count >= 4 THEN
        PERFORM test_results.log_test('Schema', 'gaming_seat_statuses data', 'PASS', 
            'Found ' || status_count || ' statuses');
    ELSE
        PERFORM test_results.log_test('Schema', 'gaming_seat_statuses data', 'FAIL', 
            'Expected at least 4, found ' || status_count);
    END IF;
END $$;

\echo ''
\echo 'Schema tests completed!'
\echo ''