-- ============================================
-- ИНТЕГРАЦИОННЫЕ ТЕСТЫ
-- ============================================

\echo '============================================'
\echo 'TEST SUITE 5: Integration Tests'
\echo '============================================'

\echo ''
\echo 'Test 5.1: Full maintenance request workflow'

DO $$
DECLARE
    test_seat_id INTEGER := 999991;
    test_request_id INTEGER := 999990;
    test_booking_id INTEGER := 999989;
    seat_status INTEGER;
    request_status INTEGER;
    booking_status INTEGER;
    node_name TEXT;
BEGIN
    SELECT name INTO node_name FROM spock.node LIMIT 1;
    
    -- Step 1: Create gaming seat
    INSERT INTO gaming_seats (id, club_id, configuration_id, status_id)
    VALUES (test_seat_id, 1, 1, 1); -- Available
    
    -- Step 2: Create future booking
    INSERT INTO bookings (id, issuer_id, status_id, gaming_seat_id, client_phone_number, 
                         creation_timestamp, start_timestamp, end_timestamp)
    VALUES (test_booking_id, 1, 1, test_seat_id, '79991234567', 
            NOW(), NOW() + INTERVAL '1 day', NOW() + INTERVAL '2 days');
    
    -- Step 3: Create maintenance request (should set seat to maintenance and cancel booking)
    INSERT INTO maintenance_requests (id, creation_timestamp, gaming_seat_id, club_id, status, description, issuer_id, last_modified)
    VALUES (test_request_id, NOW(), test_seat_id, 1, 1, 'Test workflow', 1, NOW());
    
    -- Check seat status
    SELECT status_id INTO seat_status FROM gaming_seats WHERE id = test_seat_id;
    
    -- Check booking status
    SELECT status_id INTO booking_status FROM bookings WHERE id = test_booking_id;
    
    IF seat_status = 3 THEN
        PERFORM test_results.log_test('Integration', 'Workflow: Seat set to maintenance', 'PASS');
    ELSE
        PERFORM test_results.log_test('Integration', 'Workflow: Seat set to maintenance', 'FAIL', 
            'Expected status 3, got ' || seat_status);
    END IF;
    
    -- Step 4: Complete maintenance request (should restore seat)
    IF node_name = 'central' THEN
        UPDATE maintenance_requests SET status = 3 WHERE id = test_request_id;
        
        SELECT status_id INTO seat_status FROM gaming_seats WHERE id = test_seat_id;
        
        IF seat_status = 1 THEN
            PERFORM test_results.log_test('Integration', 'Workflow: Seat restored after completion', 'PASS');
        ELSE
            PERFORM test_results.log_test('Integration', 'Workflow: Seat restored after completion', 'FAIL', 
                'Expected status 1, got ' || seat_status);
        END IF;
    ELSE
        PERFORM test_results.log_test('Integration', 'Workflow: Seat restored after completion', 'SKIP', 
            'Only runs on central node');
    END IF;
    
    -- Cleanup
    DELETE FROM maintenance_requests WHERE id = test_request_id;
    DELETE FROM bookings WHERE id = test_booking_id;
    DELETE FROM gaming_seats WHERE id = test_seat_id;
    
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Integration', 'Full maintenance workflow', 'FAIL', 
        'Error: ' || SQLERRM);
    -- Cleanup on error
    DELETE FROM maintenance_requests WHERE id = test_request_id;
    DELETE FROM bookings WHERE id = test_booking_id;
    DELETE FROM gaming_seats WHERE id = test_seat_id;
END $$;

\echo 'Test 5.2: Booking overlap prevention'

DO $$
DECLARE
    test_seat_id INTEGER := 999988;
    test_booking1_id INTEGER := 999987;
    test_booking2_id INTEGER := 999986;
    overlap_prevented BOOLEAN := FALSE;
BEGIN
    -- Create gaming seat
    INSERT INTO gaming_seats (id, club_id, configuration_id, status_id)
    VALUES (test_seat_id, 1, 1, 1);
    
    -- Create first booking
    INSERT INTO bookings (id, issuer_id, status_id, gaming_seat_id, client_phone_number, 
                         creation_timestamp, start_timestamp, end_timestamp)
    VALUES (test_booking1_id, 1, 1, test_seat_id, '79991234567', 
            NOW(), NOW() + INTERVAL '1 hour', NOW() + INTERVAL '3 hours');
    
    -- Try to create overlapping booking (should fail)
    BEGIN
        INSERT INTO bookings (id, issuer_id, status_id, gaming_seat_id, client_phone_number, 
                             creation_timestamp, start_timestamp, end_timestamp)
        VALUES (test_booking2_id, 1, 1, test_seat_id, '79991234568', 
                NOW(), NOW() + INTERVAL '2 hours', NOW() + INTERVAL '4 hours');
        
        overlap_prevented := FALSE;
    EXCEPTION WHEN OTHERS THEN
        overlap_prevented := TRUE;
    END;
    
    -- Cleanup
    DELETE FROM bookings WHERE id IN (test_booking1_id, test_booking2_id);
    DELETE FROM gaming_seats WHERE id = test_seat_id;
    
    IF overlap_prevented THEN
        PERFORM test_results.log_test('Integration', 'Booking overlap prevention', 'PASS');
    ELSE
        PERFORM test_results.log_test('Integration', 'Booking overlap prevention', 'FAIL', 
            'Overlapping booking was not prevented');
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Integration', 'Booking overlap prevention', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 5.3: Club isolation test (maintenance_requests)'

DO $$
DECLARE
    node_name TEXT;
    club_id INTEGER;
    test_request_id INTEGER := 999985;
    other_club_requests INTEGER;
BEGIN
    SELECT name INTO node_name FROM spock.node LIMIT 1;
    
    -- Determine club_id based on node name
    IF node_name = 'club1' THEN
        club_id := 1;
    ELSIF node_name = 'club2' THEN
        club_id := 2;
    ELSIF node_name = 'club3' THEN
        club_id := 3;
    ELSE
        PERFORM test_results.log_test('Integration', 'Club isolation test', 'SKIP', 
            'Only runs on club nodes');
        RETURN;
    END IF;
    
    -- Insert request for this club
    INSERT INTO maintenance_requests (id, creation_timestamp, club_id, status, description, issuer_id, last_modified)
    VALUES (test_request_id, NOW(), club_id, 1, 'Test isolation', 1, NOW());
    
    -- Wait for potential replication
    PERFORM pg_sleep(2);
    
    -- Check if there are requests from other clubs
    SELECT COUNT(*) INTO other_club_requests 
    FROM maintenance_requests 
    WHERE club_id != club_id;
    
    -- Cleanup
    DELETE FROM maintenance_requests WHERE id = test_request_id;
    
    IF other_club_requests = 0 THEN
        PERFORM test_results.log_test('Integration', 'Club isolation test', 'PASS', 
            'No requests from other clubs found');
    ELSE
        PERFORM test_results.log_test('Integration', 'Club isolation test', 'FAIL', 
            'Found ' || other_club_requests || ' requests from other clubs');
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Integration', 'Club isolation test', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 5.4: System health check'

DO $$
DECLARE
    total_tables INTEGER;
    total_triggers INTEGER;
    total_functions INTEGER;
    spock_subs INTEGER;
    pg_subs INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO total_tables 
    FROM information_schema.tables 
    WHERE table_schema = 'public';
    
    -- Count triggers
    SELECT COUNT(*) INTO total_triggers FROM pg_trigger;
    
    -- Count functions
    SELECT COUNT(*) INTO total_functions 
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public';
    
    -- Count Spock subscriptions
    SELECT COUNT(*) INTO spock_subs FROM spock.subscription;
    
    -- Count PostgreSQL subscriptions
    SELECT COUNT(*) INTO pg_subs FROM pg_subscription;
    
    PERFORM test_results.log_test('Integration', 'System health check', 'INFO', 
        'Tables: ' || total_tables || 
        ', Triggers: ' || total_triggers || 
        ', Functions: ' || total_functions || 
        ', Spock subs: ' || spock_subs || 
        ', PG subs: ' || pg_subs);
END $$;

\echo ''
\echo 'Integration tests completed!'
\echo ''