@echo off
REM ============================================
REM Скрипт запуска всех тестов (Windows)
REM ============================================

setlocal enabledelayedexpansion

set TIMESTAMP=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set LOG_FILE=test_results_%TIMESTAMP%.log
set ERROR_FILE=test_errors_%TIMESTAMP%.log

set CONTAINERS=central_db club1_db club2_db club3_db

echo ============================================ > "%LOG_FILE%"
echo  Running All Tests >> "%LOG_FILE%"
echo  Timestamp: %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo ============================================
echo  Running All Tests
echo  Timestamp: %date% %time%
echo ============================================
echo.

REM Test each container
for %%C in (%CONTAINERS%) do (
    echo ============================================ >> "%LOG_FILE%"
    echo  Testing: %%C >> "%LOG_FILE%"
    echo ============================================ >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
    
    echo ============================================
    echo  Testing: %%C
    echo ============================================
    echo.
    
    REM Run all test suites
    for %%T in (01_schema_tests.sql 02_replication_tests.sql 03_trigger_tests.sql 04_conflict_tests.sql 05_integration_tests.sql) do (
        echo Running %%T on %%C... >> "%LOG_FILE%"
        echo Running %%T on %%C...
        
        docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /tests/%%T" >> "%LOG_FILE%" 2>> "%ERROR_FILE%"
        
        if !errorlevel! equ 0 (
            echo [OK] %%T completed >> "%LOG_FILE%"
            echo [OK] %%T completed
        ) else (
            echo [FAIL] %%T failed >> "%LOG_FILE%"
            echo [FAIL] %%T failed >> "%ERROR_FILE%"
            echo [FAIL] %%T failed
        )
        echo. >> "%LOG_FILE%"
        echo.
    )
    
    REM Generate summary for this container
    echo Generating summary for %%C... >> "%LOG_FILE%"
    echo Generating summary for %%C...
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /tests/99_test_summary.sql" >> "%LOG_FILE%" 2>> "%ERROR_FILE%"
    echo. >> "%LOG_FILE%"
    echo ============================================ >> "%LOG_FILE%"
    echo. >> "%LOG_FILE%"
    echo.
)

echo ============================================ >> "%LOG_FILE%"
echo  All Tests Completed! >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"
echo Results saved to: %LOG_FILE% >> "%LOG_FILE%"
echo Errors saved to: %ERROR_FILE% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo ============================================
echo  All Tests Completed!
echo ============================================
echo.
echo Results saved to: %LOG_FILE%
echo Errors saved to: %ERROR_FILE%
echo.

REM Check if there were any errors
for %%A in ("%ERROR_FILE%") do set ERROR_SIZE=%%~zA
if %ERROR_SIZE% gtr 0 (
    echo [WARNING] Some tests had errors. Check %ERROR_FILE% for details. >> "%LOG_FILE%"
    echo [WARNING] Some tests had errors. Check %ERROR_FILE% for details.
    pause
    exit /b 1
) else (
    echo [OK] All tests completed successfully! >> "%LOG_FILE%"
    echo [OK] All tests completed successfully!
    del "%ERROR_FILE%"
    pause
    exit /b 0
)