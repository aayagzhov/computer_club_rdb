SELECT spock.node_create(
    node_name := 'central',
    dsn := 'host=central_db port=5432 dbname=computer_club_rdb user=admin password=password'
);

SELECT spock.repset_create(
    'central_master_master',   -- имя replication set
    true,              -- реплицировать INSERT
    true,              -- реплицировать UPDATE
    true,              -- реплицировать DELETE
    true               -- реплицировать TRUNCATE
);

SELECT spock.repset_add_table(
    'central_master_master',  -- имя существующего replication set
    'public.clients', -- таблица для добавления
    false,            -- синхронизация данных сразу (false, чтобы не переписать данные на подписчиках)
    NULL,             -- все колонки реплицируются
    NULL              -- фильтр строк отсутствует
);