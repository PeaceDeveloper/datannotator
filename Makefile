.PHONY: help start stop logs restart clean status setup backup db-shell migrate-export

# Default target
help:
	@echo "DataAnnotator Docker Compose Commands:"
	@echo ""
	@echo "  setup            - Create .env file from template"
	@echo "  start            - Start Label Studio + PostgreSQL"
	@echo "  stop             - Stop all services (keeps volumes)"
	@echo "  restart          - Restart all services"
	@echo "  logs             - View logs from all services"
	@echo "  status           - Show status of all services"
	@echo "  backup           - Tar label-studio-data volume into ./backups/"
	@echo "  db-shell         - Open psql in the Postgres container"
	@echo "  migrate-export   - Django dumpdata to volume and ./backups/"
	@echo "  clean            - Stop services and remove volumes (WARNING: deletes data)"
	@echo ""
	@echo "Before first use, run 'make setup' and edit the .env file with your credentials."
	@echo "Migration runbook: scripts/migrate-sqlite-to-postgres.md"

# Create .env file from template
setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from template. Please edit it with your credentials:"; \
		echo "  - Set LABEL_STUDIO_USERNAME, LABEL_STUDIO_PASSWORD"; \
		echo "  - Set POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB"; \
	else \
		echo ".env file already exists"; \
	fi

# Start all services
start:
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Run 'make setup' first."; \
		exit 1; \
	fi
	docker compose up -d

# Stop all services
stop:
	docker compose down

# Restart all services
restart: stop start

# View logs
logs:
	docker compose logs -f

# Show status
status:
	docker compose ps

# Archive Label Studio data volume (media + any local dumps/sqlite bak)
backup:
	@mkdir -p backups
	@ts=$$(date +%Y%m%d-%H%M%S); \
	echo "Backing up datannotator_label-studio-data -> backups/labelstudio-data-$$ts.tar.gz"; \
	docker run --rm \
	  -v datannotator_label-studio-data:/data:ro \
	  -v "$$(pwd)/backups:/backup" \
	  alpine tar czf "/backup/labelstudio-data-$$ts.tar.gz" -C /data .; \
	echo "Done: backups/labelstudio-data-$$ts.tar.gz"

# Open PostgreSQL shell
db-shell:
	docker exec -it datannotator-postgres \
	  psql -U "$${POSTGRES_USER:-labelstudio}" -d "$${POSTGRES_DB:-labelstudio}"

# Export Django data (works for SQLite or Postgres depending on current DJANGO_DB)
migrate-export:
	@mkdir -p backups
	docker exec -w /label-studio/label_studio label-studio python3 manage.py dumpdata \
	  --natural-foreign --natural-primary \
	  --exclude auth.permission \
	  --exclude contenttypes \
	  --exclude django_rq \
	  --exclude sessions \
	  --exclude authtoken.token \
	  --exclude token_blacklist \
	  -o /label-studio/data/datadump.json
	docker cp label-studio:/label-studio/data/datadump.json ./backups/datadump.json
	@echo "Exported to backups/datadump.json (and /label-studio/data/datadump.json in the volume)"

# Clean up (WARNING: removes data)
clean:
	@echo "WARNING: This will delete all data including Label Studio projects, annotations, and Postgres."
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose down -v
