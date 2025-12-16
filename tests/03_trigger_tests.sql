-- ============================================
-- ТЕСТЫ ТРИГГЕРОВ
-- ============================================

\echo '============================================'
\echo 'TEST SUITE 3: Trigger Tests'
\echo '============================================'

\echo ''
\echo 'Test 3.1: Checking all trigger functions exist'

DO $$
DECLARE
    required_functions TEXT[] := ARRAY[
        'check_maintenance_request_edit',
        'set_gaming_seat_maintenance_on_request',
        'restore_gaming_seat_after_maintenance',
        'cancel_bookings_on_maintenance',
        'prevent_booking_on_maintenance',
        'update_maintenance_request_timestamp',
        'resolve_client_conflict',
        'detect_client_update_conflict'
    ];
    func_name TEXT;
    func_exists BOOLEAN;
BEGIN
    FOREACH func_name IN ARRAY required_functions
    LOOP
        SELECT EXISTS (
            SELECT FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.proname = func_name
        ) INTO func_exists;
        
        IF func_exists THEN
            PERFORM test_results.log_test('Triggers', 'Function exists: ' || func_name, 'PASS');
        ELSE
            PERFORM test_results.log_test('Triggers', 'Function exists: ' || func_name, 'FAIL', 
                'Function not found');
        END IF;
    END LOOP;
END $$;

\echo 'Test 3.2: Checking all triggers exist'

DO $$
DECLARE
    required_triggers TEXT[] := ARRAY[
        'maintenance_request_edit_check',
        'gaming_seat_maintenance_on_request_create',
        'gaming_seat_restore_after_maintenance',
        'cancel_bookings_on_gaming_seat_maintenance',
        'prevent_booking_on_maintenance_check',
        'update_maintenance_request_timestamp_trigger',
        'resolve_client_conflict_trigger',
        'detect_client_update_conflict_trigger'
    ];
    trigger_name TEXT;
    trigger_exists BOOLEAN;
BEGIN
    FOREACH trigger_name IN ARRAY required_triggers
    LOOP
        SELECT EXISTS (
            SELECT FROM pg_trigger
            WHERE tgname = trigger_name
        ) INTO trigger_exists;
        
        IF trigger_exists THEN
            PERFORM test_results.log_test('Triggers', 'Trigger exists: ' || trigger_name, 'PASS');
        ELSE
            PERFORM test_results.log_test('Triggers', 'Trigger exists: ' || trigger_name, 'FAIL', 
                'Trigger not found');
        END IF;
    END LOOP;
END $$;

\echo 'Test 3.3: Testing maintenance request edit block (club node only)'

DO $$
DECLARE
    node_name TEXT;
    test_id INTEGER;
    edit_blocked BOOLEAN := FALSE;
BEGIN
    SELECT name INTO node_name FROM spock.node LIMIT 1;
    
    -- Only test on club nodes
    IF node_name != 'central' THEN
        -- Insert test data
        INSERT INTO maintenance_requests (id, creation_timestamp, club_id, status, description, issuer_id, last_modified)
        VALUES (999999, NOW(), 1, 1, 'Test request', 1, NOW())
        RETURNING id INTO test_id;
        
        -- Try to update (should fail)
        BEGIN
            UPDATE maintenance_requests 
            SET description = 'Updated description'
            WHERE id = test_id;
            
            edit_blocked := FALSE;
        EXCEPTION WHEN OTHERS THEN
            edit_blocked := TRUE;
        END;
        
        -- Cleanup
        DELETE FROM maintenance_requests WHERE id = test_id;
        
        IF edit_blocked THEN
            PERFORM test_results.log_test('Triggers', 'Maintenance request edit block on club', 'PASS');
        ELSE
            PERFORM test_results.log_test('Triggers', 'Maintenance request edit block on club', 'FAIL', 
                'Edit was not blocked');
        END IF;
    ELSE
        PERFORM test_results.log_test('Triggers', 'Maintenance request edit block on club', 'SKIP', 
            'Test only runs on club nodes');
    END IF;
END $$;

\echo 'Test 3.4: Testing gaming seat status change on maintenance request'

DO $$
DECLARE
    test_seat_id INTEGER := 999998;
    test_request_id INTEGER := 999997;
    seat_status INTEGER;
BEGIN
    -- Create test gaming seat
    INSERT INTO gaming_seats (id, club_id, configuration_id, status_id)
    VALUES (test_seat_id, 1, 1, 1); -- Status: Available
    
    -- Create maintenance request
    INSERT INTO maintenance_requests (id, creation_timestamp, gaming_seat_id, club_id, status, description, issuer_id, last_modified)
    VALUES (test_request_id, NOW(), test_seat_id, 1, 1, 'Test', 1, NOW());
    
    -- Check if seat status changed to "On maintenance" (3)
    SELECT status_id INTO seat_status FROM gaming_seats WHERE id = test_seat_id;
    
    -- Cleanup
    DELETE FROM maintenance_requests WHERE id = test_request_id;
    DELETE FROM gaming_seats WHERE id = test_seat_id;
    
    IF seat_status = 3 THEN
        PERFORM test_results.log_test('Triggers', 'Gaming seat set to maintenance on request', 'PASS');
    ELSE
        PERFORM test_results.log_test('Triggers', 'Gaming seat set to maintenance on request', 'FAIL', 
            'Expected status 3, got ' || seat_status);
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Triggers', 'Gaming seat set to maintenance on request', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 3.5: Testing gaming seat restoration after maintenance'

DO $$
DECLARE
    test_seat_id INTEGER := 999996;
    test_request_id INTEGER := 999995;
    seat_status INTEGER;
BEGIN
    -- Create test gaming seat in maintenance
    INSERT INTO gaming_seats (id, club_id, configuration_id, status_id)
    VALUES (test_seat_id, 1, 1, 3); -- Status: On maintenance
    
    -- Create maintenance request
    INSERT INTO maintenance_requests (id, creation_timestamp, gaming_seat_id, club_id, status, description, issuer_id, last_modified)
    VALUES (test_request_id, NOW(), test_seat_id, 1, 2, 'Test', 1, NOW()); -- Status: In progress
    
    -- Complete the request
    UPDATE maintenance_requests SET status = 3 WHERE id = test_request_id; -- Status: Completed
    
    -- Check if seat status changed to "Available" (1)
    SELECT status_id INTO seat_status FROM gaming_seats WHERE id = test_seat_id;
    
    -- Cleanup
    DELETE FROM maintenance_requests WHERE id = test_request_id;
    DELETE FROM gaming_seats WHERE id = test_seat_id;
    
    IF seat_status = 1 THEN
        PERFORM test_results.log_test('Triggers', 'Gaming seat restored after maintenance', 'PASS');
    ELSE
        PERFORM test_results.log_test('Triggers', 'Gaming seat restored after maintenance', 'FAIL', 
            'Expected status 1, got ' || seat_status);
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Triggers', 'Gaming seat restored after maintenance', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 3.6: Testing booking prevention on maintenance seat'

DO $$
DECLARE
    test_seat_id INTEGER := 999994;
    booking_prevented BOOLEAN := FALSE;
BEGIN
    -- Create test gaming seat in maintenance
    INSERT INTO gaming_seats (id, club_id, configuration_id, status_id)
    VALUES (test_seat_id, 1, 1, 3); -- Status: On maintenance
    
    -- Try to create booking (should fail)
    BEGIN
        INSERT INTO bookings (id, issuer_id, status_id, gaming_seat_id, client_phone_number, 
                             creation_timestamp, start_timestamp, end_timestamp)
        VALUES (999993, 1, 1, test_seat_id, '79991234567', NOW(), NOW() + INTERVAL '1 hour', NOW() + INTERVAL '2 hours');
        
        booking_prevented := FALSE;
    EXCEPTION WHEN OTHERS THEN
        booking_prevented := TRUE;
    END;
    
    -- Cleanup
    DELETE FROM gaming_seats WHERE id = test_seat_id;
    
    IF booking_prevented THEN
        PERFORM test_results.log_test('Triggers', 'Booking prevented on maintenance seat', 'PASS');
    ELSE
        PERFORM test_results.log_test('Triggers', 'Booking prevented on maintenance seat', 'FAIL', 
            'Booking was not prevented');
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Triggers', 'Booking prevented on maintenance seat', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 3.7: Testing conflict_log table exists'

DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'conflict_log'
    ) INTO table_exists;
    
    IF table_exists THEN
        PERFORM test_results.log_test('Triggers', 'conflict_log table exists', 'PASS');
    ELSE
        PERFORM test_results.log_test('Triggers', 'conflict_log table exists', 'FAIL', 'Table not found');
    END IF;
END $$;

\echo ''
\echo 'Trigger tests completed!'
\echo ''