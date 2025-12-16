-- ============================================
-- СВОДКА РЕЗУЛЬТАТОВ ТЕСТОВ
-- ============================================

\echo ''
\echo '============================================'
\echo 'TEST RESULTS SUMMARY'
\echo '============================================'
\echo ''

-- Summary by status
\echo 'Results by Status:'
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM test_results.test_log
GROUP BY status
ORDER BY 
    CASE status
        WHEN 'PASS' THEN 1
        WHEN 'WARN' THEN 2
        WHEN 'INFO' THEN 3
        WHEN 'SKIP' THEN 4
        WHEN 'FAIL' THEN 5
    END;

\echo ''
\echo 'Results by Test Suite:'
SELECT 
    test_suite,
    COUNT(*) as total,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) as passed,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) as failed,
    SUM(CASE WHEN status = 'WARN' THEN 1 ELSE 0 END) as warnings,
    SUM(CASE WHEN status = 'SKIP' THEN 1 ELSE 0 END) as skipped
FROM test_results.test_log
GROUP BY test_suite
ORDER BY test_suite;

\echo ''
\echo 'Failed Tests (if any):'
SELECT 
    test_suite,
    test_name,
    message,
    executed_at
FROM test_results.test_log
WHERE status = 'FAIL'
ORDER BY executed_at;

\echo ''
\echo 'Warnings (if any):'
SELECT 
    test_suite,
    test_name,
    message,
    executed_at
FROM test_results.test_log
WHERE status = 'WARN'
ORDER BY executed_at;

\echo ''
\echo '============================================'
\echo 'Test execution completed!'
\echo '============================================'
\echo ''

-- Export results to CSV (optional)
\copy (SELECT * FROM test_results.test_log ORDER BY id) TO '/tmp/test_results.csv' WITH CSV HEADER;

\echo 'Results exported to /tmp/test_results.csv'
\echo ''