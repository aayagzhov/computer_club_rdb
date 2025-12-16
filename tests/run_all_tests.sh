#!/bin/bash

# ============================================
# Скрипт запуска всех тестов (Linux/Mac)
# ============================================

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="test_results_${TIMESTAMP}.log"
ERROR_FILE="test_errors_${TIMESTAMP}.log"

CONTAINERS="central_db club1_db club2_db club3_db"

echo "============================================" | tee -a "$LOG_FILE"
echo " Running All Tests" | tee -a "$LOG_FILE"
echo " Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Test each container
for CONTAINER in $CONTAINERS; do
    echo "============================================" | tee -a "$LOG_FILE"
    echo " Testing: $CONTAINER" | tee -a "$LOG_FILE"
    echo "============================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Run all test suites
    for TEST_FILE in 01_schema_tests.sql 02_replication_tests.sql 03_trigger_tests.sql 04_conflict_tests.sql 05_integration_tests.sql; do
        echo "Running $TEST_FILE on $CONTAINER..." | tee -a "$LOG_FILE"
        
        docker exec $CONTAINER bash -c "psql -U admin -d computer_club_rdb -f /tests/$TEST_FILE" >> "$LOG_FILE" 2>> "$ERROR_FILE"
        
        if [ $? -eq 0 ]; then
            echo "✓ $TEST_FILE completed" | tee -a "$LOG_FILE"
        else
            echo "✗ $TEST_FILE failed" | tee -a "$LOG_FILE" "$ERROR_FILE"
        fi
        echo "" | tee -a "$LOG_FILE"
    done
    
    # Generate summary for this container
    echo "Generating summary for $CONTAINER..." | tee -a "$LOG_FILE"
    docker exec $CONTAINER bash -c "psql -U admin -d computer_club_rdb -f /tests/99_test_summary.sql" >> "$LOG_FILE" 2>> "$ERROR_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "============================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
done

echo "============================================" | tee -a "$LOG_FILE"
echo " All Tests Completed!" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Results saved to: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Errors saved to: $ERROR_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if there were any errors
if [ -s "$ERROR_FILE" ]; then
    echo "⚠️  Some tests had errors. Check $ERROR_FILE for details." | tee -a "$LOG_FILE"
    exit 1
else
    echo "✓ All tests completed successfully!" | tee -a "$LOG_FILE"
    rm "$ERROR_FILE"
    exit 0
fi