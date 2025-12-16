# Тесты для системы компьютерного клуба

Этот каталог содержит тесты для проверки всех компонентов распределенной системы компьютерного клуба.

## Структура тестов

- `01_schema_tests.sql` - Тесты схемы базы данных
- `02_replication_tests.sql` - Тесты репликации
- `03_trigger_tests.sql` - Тесты триггеров
- `04_conflict_tests.sql` - Тесты разрешения конфликтов
- `05_integration_tests.sql` - Интеграционные тесты
- `run_all_tests.sh` - Скрипт запуска всех тестов (Linux/Mac)
- `run_all_tests.bat` - Скрипт запуска всех тестов (Windows)

## Как запустить тесты

### Windows
```bash
cd tests
run_all_tests.bat
```

### Linux/Mac
```bash
cd tests
chmod +x run_all_tests.sh
./run_all_tests.sh
```

## Требования

- Docker и docker-compose должны быть запущены
- Все контейнеры БД должны быть инициализированы
- Репликация должна быть настроена

## Результаты тестов

Результаты сохраняются в файлы:
- `test_results_<timestamp>.log` - общий лог
- `test_errors_<timestamp>.log` - только ошибки