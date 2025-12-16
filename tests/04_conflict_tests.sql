-- ============================================
-- ТЕСТЫ РАЗРЕШЕНИЯ КОНФЛИКТОВ
-- ============================================

\echo '============================================'
\echo 'TEST SUITE 4: Conflict Resolution Tests'
\echo '============================================'

\echo ''
\echo 'Test 4.1: Testing client duplicate resolution (earlier registration wins)'

DO $$
DECLARE
    conflict_logged BOOLEAN;
    phone_test VARCHAR(11) := '79999999999';
BEGIN
    -- Insert first client
    INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp)
    VALUES (phone_test, 1, '$2a$10$test1', '2024-01-01 10:00:00');
    
    -- Try to insert duplicate with later timestamp (should be rejected)
    INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp)
    VALUES (phone_test, 2, '$2a$10$test2', '2024-01-02 10:00:00');
    
    -- Check if conflict was logged
    SELECT EXISTS (
        SELECT FROM conflict_log 
        WHERE table_name = 'clients' 
        AND conflict_type = 'duplicate_registration'
        AND local_data->>'phone_number' = phone_test
    ) INTO conflict_logged;
    
    -- Cleanup
    DELETE FROM clients WHERE phone_number = phone_test;
    DELETE FROM conflict_log WHERE table_name = 'clients' AND local_data->>'phone_number' = phone_test;
    
    IF conflict_logged THEN
        PERFORM test_results.log_test('Conflicts', 'Client duplicate conflict logged', 'PASS');
    ELSE
        PERFORM test_results.log_test('Conflicts', 'Client duplicate conflict logged', 'FAIL', 
            'Conflict was not logged');
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Conflicts', 'Client duplicate conflict logged', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 4.2: Testing client update conflict detection'

DO $$
DECLARE
    conflict_logged BOOLEAN;
    phone_test VARCHAR(11) := '79999999998';
BEGIN
    -- Insert client
    INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp)
    VALUES (phone_test, 1, '$2a$10$test1', NOW());
    
    -- Update client (should log conflict)
    UPDATE clients 
    SET password_hash = '$2a$10$test2'
    WHERE phone_number = phone_test;
    
    -- Check if conflict was logged
    SELECT EXISTS (
        SELECT FROM conflict_log 
        WHERE table_name = 'clients' 
        AND conflict_type = 'concurrent_update'
        AND local_data->>'phone_number' = phone_test
    ) INTO conflict_logged;
    
    -- Cleanup
    DELETE FROM clients WHERE phone_number = phone_test;
    DELETE FROM conflict_log WHERE table_name = 'clients' AND local_data->>'phone_number' = phone_test;
    
    IF conflict_logged THEN
        PERFORM test_results.log_test('Conflicts', 'Client update conflict detected', 'PASS');
    ELSE
        PERFORM test_results.log_test('Conflicts', 'Client update conflict detected', 'FAIL', 
            'Conflict was not detected');
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Conflicts', 'Client update conflict detected', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo 'Test 4.3: Testing get_unresolved_conflicts function'

DO $$
DECLARE
    func_exists BOOLEAN;
    result_count INTEGER;
BEGIN
    -- Check if function exists
    SELECT EXISTS (
        SELECT FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'get_unresolved_conflicts'
    ) INTO func_exists;
    
    IF NOT func_exists THEN
        PERFORM test_results.log_test('Conflicts', 'get_unresolved_conflicts function', 'FAIL', 
            'Function not found');
        RETURN;
    END IF;
    
    -- Try to call function
    BEGIN
        SELECT COUNT(*) INTO result_count FROM get_unresolved_conflicts();
        PERFORM test_results.log_test('Conflicts', 'get_unresolved_conflicts function', 'PASS', 
            'Found ' || result_count || ' unresolved conflicts');
    EXCEPTION WHEN OTHERS THEN
        PERFORM test_results.log_test('Conflicts', 'get_unresolved_conflicts function', 'FAIL', 
            'Error calling function: ' || SQLERRM);
    END;
END $$;

\echo 'Test 4.4: Testing resolve_conflict function'

DO $$
DECLARE
    func_exists BOOLEAN;
    test_conflict_id INTEGER;
BEGIN
    -- Check if function exists
    SELECT EXISTS (
        SELECT FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'resolve_conflict'
    ) INTO func_exists;
    
    IF NOT func_exists THEN
        PERFORM test_results.log_test('Conflicts', 'resolve_conflict function', 'FAIL', 
            'Function not found');
        RETURN;
    END IF;
    
    -- Create test conflict
    INSERT INTO conflict_log (table_name, conflict_type, local_data, remote_data, resolution)
    VALUES ('test_table', 'test_conflict', '{}', '{}', 'Test resolution')
    RETURNING id INTO test_conflict_id;
    
    -- Try to resolve conflict
    BEGIN
        PERFORM resolve_conflict(test_conflict_id, 'Resolved by test', 'test_admin');
        
        -- Check if conflict was resolved
        IF EXISTS (
            SELECT FROM conflict_log 
            WHERE id = test_conflict_id 
            AND resolved_by = 'test_admin'
            AND resolved_at IS NOT NULL
        ) THEN
            PERFORM test_results.log_test('Conflicts', 'resolve_conflict function', 'PASS');
        ELSE
            PERFORM test_results.log_test('Conflicts', 'resolve_conflict function', 'FAIL', 
                'Conflict was not marked as resolved');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        PERFORM test_results.log_test('Conflicts', 'resolve_conflict function', 'FAIL', 
            'Error calling function: ' || SQLERRM);
    END;
    
    -- Cleanup
    DELETE FROM conflict_log WHERE id = test_conflict_id;
END $$;

\echo 'Test 4.5: Testing maintenance_requests last_modified auto-update'

DO $$
DECLARE
    test_id INTEGER := 999992;
    old_timestamp TIMESTAMP;
    new_timestamp TIMESTAMP;
BEGIN
    -- Insert test request
    INSERT INTO maintenance_requests (id, creation_timestamp, club_id, status, description, issuer_id, last_modified)
    VALUES (test_id, NOW(), 1, 2, 'Test', 1, NOW() - INTERVAL '1 hour')
    RETURNING last_modified INTO old_timestamp;
    
    -- Wait a moment
    PERFORM pg_sleep(0.1);
    
    -- Update request
    UPDATE maintenance_requests 
    SET description = 'Updated'
    WHERE id = test_id
    RETURNING last_modified INTO new_timestamp;
    
    -- Cleanup
    DELETE FROM maintenance_requests WHERE id = test_id;
    
    IF new_timestamp > old_timestamp THEN
        PERFORM test_results.log_test('Conflicts', 'last_modified auto-update', 'PASS');
    ELSE
        PERFORM test_results.log_test('Conflicts', 'last_modified auto-update', 'FAIL', 
            'Timestamp was not updated');
    END IF;
EXCEPTION WHEN OTHERS THEN
    PERFORM test_results.log_test('Conflicts', 'last_modified auto-update', 'FAIL', 
        'Error: ' || SQLERRM);
END $$;

\echo ''
\echo 'Conflict resolution tests completed!'
\echo ''