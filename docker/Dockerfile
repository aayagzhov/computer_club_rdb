# Базовый образ PostgreSQL
FROM postgres:15

# Устанавливаем pglogical и зависимости
RUN apt-get update && \
    apt-get install -y \
        postgresql-15-pglogical \
    && rm -rf /var/lib/apt/lists/*

# (необязательно) копируем кастомные конфиги, если нужны
# COPY ./postgresql.conf /etc/postgresql/postgresql.conf

# Убедимся, что расширение доступно
RUN echo "shared_preload_libraries = 'pglogical'" >> /usr/share/postgresql/postgresql.conf.sample

# Оставляем стандартный entrypoint
EXPOSE 5432
