# Migrate Label Studio SQLite → PostgreSQL (no data loss)

This project stores Label Studio media in the `label-studio-data` volume and the
relational database in PostgreSQL (`DJANGO_DB=default` + `POSTGRE_*`).

Do **not** import `label_studio.sqlite3` into Postgres with raw SQL tools.
Use Django `dumpdata` / `loaddata` so booleans, JSON, and FKs convert correctly.

## Prerequisites

- Running stack (or at least the Label Studio container with access to the SQLite file)
- Pin the Label Studio image (see `docker-compose.yml`) so dump and load share the same migrations
- Enough disk for `./backups/` (media volume can be large)

## 0. Preflight counts

```bash
docker exec label-studio python3 -c "
import sqlite3
c=sqlite3.connect('/label-studio/data/label_studio.sqlite3')
for t in ['htx_user','organization','project','task','task_completion','prediction']:
    print(t, c.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0])
"
```

Confirm engine is SQLite before export:

```bash
docker exec -w /label-studio/label_studio label-studio \
  python3 manage.py diffsettings | findstr /i "DJANGO_DB ENGINE"
```

## 1. Backup

```bash
make backup
# Also copy the SQLite file alone:
docker run --rm \
  -v datannotator_label-studio-data:/data:ro \
  -v "%cd%/backups:/backup" \
  alpine cp /data/label_studio.sqlite3 /backup/label_studio.sqlite3.bak
```

Never run `make clean` during migration (`down -v` deletes volumes).

## 2. Export (while still on SQLite)

```bash
make migrate-export
```

Or manually:

```bash
docker exec -w /label-studio/label_studio label-studio python3 manage.py dumpdata \
  --natural-foreign --natural-primary \
  --exclude auth.permission \
  --exclude contenttypes \
  --exclude django_rq \
  --exclude sessions \
  --exclude authtoken.token \
  --exclude token_blacklist \
  -o /label-studio/data/datadump.json
```

Exclude `authtoken.token` / `token_blacklist`: user `post_save` signals recreate API tokens
and will conflict with tokens in the fixture.

Copy dump to the host: `docker cp label-studio:/label-studio/data/datadump.json ./backups/`

## 3. Point Label Studio at Postgres

Ensure `docker-compose.yml` has:

- `DJANGO_DB=default`
- `POSTGRE_HOST=postgres`, `POSTGRE_PORT=5432`
- `POSTGRE_NAME/USER/PASSWORD` from `.env`
- Postgres `healthcheck` + `depends_on: condition: service_healthy`

Then recreate:

```bash
docker compose up -d --force-recreate
```

If Postgres has a broken half-migrated schema (empty `django_migrations` but tables exist),
clear **only** the incomplete Postgres tables (SQLite dump remains source of truth), then:

```bash
docker compose run --rm --no-deps --entrypoint python3 label-studio \
  /label-studio/label_studio/manage.py migrate --noinput
```

## 4. Load into Postgres (Label Studio web process stopped)

```bash
docker compose stop label-studio

docker compose run --rm --no-deps --entrypoint python3 label-studio \
  /label-studio/label_studio/manage.py flush --no-input

docker compose run --rm --no-deps --entrypoint python3 label-studio \
  /label-studio/label_studio/manage.py shell -c \
  "from django.contrib.contenttypes.models import ContentType; ContentType.objects.all().delete()"

docker compose run --rm --no-deps --entrypoint python3 label-studio \
  /label-studio/label_studio/manage.py loaddata /label-studio/data/datadump.json

docker compose up -d label-studio
```

Loading ~20k tasks can take 20–40+ minutes; wait for `Installed N object(s)`.

## 5. Verify

```bash
docker exec datannotator-postgres psql -U labelstudio -d labelstudio -c "
SELECT 'htx_user' t, COUNT(*) n FROM htx_user
UNION ALL SELECT 'organization', COUNT(*) FROM organization
UNION ALL SELECT 'project', COUNT(*) FROM project
UNION ALL SELECT 'task', COUNT(*) FROM task
UNION ALL SELECT 'task_completion', COUNT(*) FROM task_completion;
"
```

Counts must match preflight. Confirm UI login and that media URLs still open
(media stays on `label-studio-data`).

Optional: rename SQLite so it is not mistaken for the live DB:

```bash
docker run --rm -v datannotator_label-studio-data:/data alpine \
  mv /data/label_studio.sqlite3 /data/label_studio.sqlite3.bak
```

## Rollback

1. `docker compose stop label-studio`
2. Restore `label_studio.sqlite3` into the data volume from `./backups/`
3. Set `DJANGO_DB=sqlite` (or remove Postgres env vars) and recreate Label Studio
4. Verify counts against the preflight file

## Notes from the 2026-08-11 cutover

| Metric | Count |
|--------|------:|
| users | 7 |
| organization | 1 |
| projects | 4 |
| tasks | 20158 |
| annotations (`task_completion`) | 20134 |
| Image | Label Studio 1.20.0 `@sha256:f4481a772b19...` |
| Result | `Installed 62001 object(s)` into PostgreSQL |
