# 1. Проверка master->master репликации для таблицы clients

## Запустить на каждом клубе:

### Центр

```sql
INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp) 
VALUES
  ('central', 1, '$2a$10$abcdefghijk1234567890lmnopqrstuv', '2024-01-15 10:30:00')
```

### Клуб 1

```sql
INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp) 
VALUES
  ('club1', 1, '$2a$10$abcdefghijk1234567890lmnopqrstuv', '2024-01-15 10:30:00')
```
### Клуб 2

```sql
INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp) 
VALUES
  ('club2', 1, '$2a$10$abcdefghijk1234567890lmnopqrstuv', '2024-01-15 10:30:00')
```
### Клуб 3

```sql
INSERT INTO clients (phone_number, discount_status, password_hash, registration_timestamp) 
VALUES
  ('club3', 1, '$2a$10$abcdefghijk1234567890lmnopqrstuv', '2024-01-15 10:30:00')
```

После на каждом клубе прогнать:

```sql
select * from clients;
```

и проверить что на каждом клубе появились новые записи.

# 2. НСИ есть на всех клубах.

## Запустить на каждом клубе

```

select * from booking_statuses bs ;

```

и убедится что они соответсвуют данным с центрального узла.

# 3. Проверка рабочего потока для таблицы 