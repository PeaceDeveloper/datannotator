# DataAnnotator

Docker Compose setup for **Label Studio** with **PostgreSQL 15** as the project database.

## Overview

- **Label Studio** (pinned image): web annotation UI on port 8080
- **PostgreSQL 15**: relational store for users, projects, tasks, and annotations
- **Media volume**: uploads and files remain in the `label-studio-data` Docker volume

## Prerequisites

- Docker and Docker Compose
- A filled `.env` (from `.env.example`)

## Quick Start

1. Clone and enter the repo
2. `make setup` then edit `.env` (Label Studio admin + Postgres credentials)
3. `make start`
4. Open http://localhost:8080 and sign in with `LABEL_STUDIO_USERNAME` / `LABEL_STUDIO_PASSWORD`

## Database

Label Studio does **not** use `DATABASE_URL`. It requires:

| Variable | Purpose |
|----------|---------|
| `DJANGO_DB=default` | Select PostgreSQL backend |
| `POSTGRE_HOST` | Hostname (`postgres` in Compose) |
| `POSTGRE_PORT` | Port (`5432`) |
| `POSTGRE_NAME` | Database name (`POSTGRES_DB`) |
| `POSTGRE_USER` / `POSTGRE_PASSWORD` | Credentials |

These are set in [`docker-compose.yml`](docker-compose.yml) from your `.env` `POSTGRES_*` values.

### Data persistence

| Volume | Contents |
|--------|----------|
| `label-studio-data` | Media/uploads (+ optional SQLite `.bak` after migration) |
| `postgres-data` | PostgreSQL data files |

`make clean` runs `docker compose down -v` and **deletes both volumes**.

## Commands

```bash
make setup      # Create .env from template
make start      # Start Label Studio + Postgres
make stop       # Stop services (keep volumes)
make restart
make logs
make status
make backup     # Archive label-studio-data volume under ./backups/
make db-shell   # psql into Postgres
make migrate-export  # Django dumpdata to volume + ./backups/
make clean      # WARNING: deletes all volumes/data
```

## SQLite → PostgreSQL migration

If you still have a legacy SQLite file, follow the runbook:

[`scripts/migrate-sqlite-to-postgres.md`](scripts/migrate-sqlite-to-postgres.md)

Summary: backup → `dumpdata` → point Compose at Postgres → `migrate` → `loaddata` → verify row counts. Do **not** raw-import the `.sqlite3` file into Postgres.

## Troubleshooting

1. **Label Studio not accessible**: check port 8080 and `make logs`
2. **DB connection errors**: confirm Postgres is healthy (`docker compose ps`) and `POSTGRES_*` match what Compose injects as `POSTGRE_*`
3. **Lost data after clean**: volumes were removed; restore from `./backups/`

## Security

- `.env` is gitignored; never commit secrets
- Prefer strong `LABEL_STUDIO_PASSWORD` and `POSTGRES_PASSWORD`
- `./backups/` can contain full production dumps — keep it private (gitignored)

## License

Apache License 2.0
