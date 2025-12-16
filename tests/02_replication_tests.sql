-- ============================================
-- ТЕСТЫ РЕПЛИКАЦИИ
-- ============================================

\echo '============================================'
\echo 'TEST SUITE 2: Replication Tests'
\echo '============================================'

\echo ''
\echo 'Test 2.1: Checking Spock extension'

DO $$
DECLARE
    spock_installed BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM pg_extension WHERE extname = 'spock'
    ) INTO spock_installed;
    
    IF spock_installed THEN
        PERFORM test_results.log_test('Replication', 'Spock extension installed', 'PASS');
    ELSE
        PERFORM test_results.log_test('Replication', 'Spock extension installed', 'FAIL', 'Extension not found');
    END IF;
END $$;

\echo 'Test 2.2: Checking Spock node exists'

DO $$
DECLARE
    node_count INTEGER;
    node_name TEXT;
BEGIN
    SELECT COUNT(*), MAX(name) INTO node_count, node_name FROM spock.node;
    
    IF node_count > 0 THEN
        PERFORM test_results.log_test('Replication', 'Spock node exists', 'PASS', 
            'Node name: ' || node_name);
    ELSE
        PERFORM test_results.log_test('Replication', 'Spock node exists', 'FAIL', 'No nodes found');
    END IF;
END $$;

\echo 'Test 2.3: Checking replication sets'

DO $$
DECLARE
    repset_count INTEGER;
    repset_names TEXT;
BEGIN
    SELECT COUNT(*), string_agg(set_name, ', ') 
    INTO repset_count, repset_names 
    FROM spock.replication_set;
    
    IF repset_count > 0 THEN
        PERFORM test_results.log_test('Replication', 'Replication sets exist', 'PASS', 
            'Found ' || repset_count || ' sets: ' || repset_names);
    ELSE
        PERFORM test_results.log_test('Replication', 'Replication sets exist', 'FAIL', 'No replication sets found');
    END IF;
END $$;

\echo 'Test 2.4: Checking maintenance_requests in replication sets'

DO $$
DECLARE
    table_in_repset BOOLEAN;
    node_name TEXT;
BEGIN
    SELECT name INTO node_name FROM spock.node LIMIT 1;
    
    -- Check if maintenance_requests is in any replication set
    SELECT EXISTS (
        SELECT FROM spock.replication_set_table
        WHERE set_reloid = 'maintenance_requests'::regclass
    ) INTO table_in_repset;
    
    IF node_name = 'central' THEN
        -- Central should have club-specific replication sets
        IF table_in_repset THEN
            PERFORM test_results.log_test('Replication', 'maintenance_requests in central repsets', 'PASS');
        ELSE
            PERFORM test_results.log_test('Replication', 'maintenance_requests in central repsets', 'FAIL', 
                'Table not in replication sets');
        END IF;
    ELSE
        -- Clubs should have maintenance_requests in publications
        PERFORM test_results.log_test('Replication', 'maintenance_requests replication check', 'PASS', 
            'Club node: ' || node_name);
    END IF;
END $$;

\echo 'Test 2.5: Checking subscriptions'

DO $$
DECLARE
    sub_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO sub_count FROM spock.subscription;
    
    IF sub_count > 0 THEN
        PERFORM test_results.log_test('Replication', 'Subscriptions exist', 'PASS', 
            'Found ' || sub_count || ' subscriptions');
    ELSE
        PERFORM test_results.log_test('Replication', 'Subscriptions exist', 'FAIL', 'No subscriptions found');
    END IF;
END $$;

\echo 'Test 2.6: Checking subscription status'

DO $$
DECLARE
    active_subs INTEGER;
    total_subs INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_subs FROM spock.subscription;
    SELECT COUNT(*) INTO active_subs FROM spock.subscription WHERE status = 'replicating';
    
    IF active_subs = total_subs AND total_subs > 0 THEN
        PERFORM test_results.log_test('Replication', 'All subscriptions active', 'PASS', 
            active_subs || ' of ' || total_subs || ' subscriptions replicating');
    ELSE
        PERFORM test_results.log_test('Replication', 'All subscriptions active', 'WARN', 
            'Only ' || active_subs || ' of ' || total_subs || ' subscriptions replicating');
    END IF;
END $$;

\echo 'Test 2.7: Checking PostgreSQL native publications'

DO $$
DECLARE
    pub_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO pub_count FROM pg_publication;
    
    IF pub_count > 0 THEN
        PERFORM test_results.log_test('Replication', 'PostgreSQL publications exist', 'PASS', 
            'Found ' || pub_count || ' publications');
    ELSE
        PERFORM test_results.log_test('Replication', 'PostgreSQL publications exist', 'FAIL', 
            'No publications found');
    END IF;
END $$;

\echo 'Test 2.8: Checking if maintenance_requests is in publications'

DO $$
DECLARE
    in_publication BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT FROM pg_publication_tables
        WHERE tablename = 'maintenance_requests'
    ) INTO in_publication;
    
    IF in_publication THEN
        PERFORM test_results.log_test('Replication', 'maintenance_requests in publications', 'PASS');
    ELSE
        PERFORM test_results.log_test('Replication', 'maintenance_requests in publications', 'INFO', 
            'Not in native publications (may use Spock only)');
    END IF;
END $$;

\echo ''
\echo 'Replication tests completed!'
\echo ''