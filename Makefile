.PHONY: help start stop logs restart clean status setup

# Default target
help:
	@echo "DataAnnotator Docker Compose Commands:"
	@echo ""
	@echo "  setup     - Create .env file from template"
	@echo "  start     - Start all services"
	@echo "  stop      - Stop all services"
	@echo "  restart   - Restart all services"
	@echo "  logs      - View logs from all services"
	@echo "  status    - Show status of all services"
	@echo "  clean     - Stop services and remove volumes (WARNING: deletes data)"
	@echo ""
	@echo "Before first use, run 'make setup' and edit the .env file with your credentials."

# Create .env file from template
setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from template. Please edit it with your credentials:"; \
		echo "  - Set LABEL_STUDIO_USERNAME, LABEL_STUDIO_PASSWORD, LABEL_STUDIO_USER_TOKEN"; \
		echo "  - Set NGROK_AUTHTOKEN from https://dashboard.ngrok.com/get-started/your-authtoken"; \
		echo "  - Optionally set NGROK_REGION (default: us)"; \
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

# Clean up (WARNING: removes data)
clean:
	@echo "WARNING: This will delete all data including Label Studio projects and annotations."
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker compose down -v