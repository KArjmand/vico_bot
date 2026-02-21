.PHONY: build run stop logs clean shell help

# Default target
help:
	@echo "Vicobot Docker Commands:"
	@echo "  make build    - Build the Docker image"
	@echo "  make run      - Run vicobot with docker-compose"
	@echo "  make stop     - Stop the containers"
	@echo "  make logs     - Show logs"
	@echo "  make shell    - Open shell in container"
	@echo "  make clean    - Remove containers and images"
	@echo "  make dev      - Development mode with volume mount"

# Build optimized Docker image
build:
	docker build -f docker/Dockerfile -t vicobot:latest .

# Run with docker-compose
run:
	docker-compose -f docker/docker-compose.yml up -d

# Stop containers
stop:
	docker-compose -f docker/docker-compose.yml down

# Show logs
logs:
	docker-compose -f docker/docker-compose.yml logs -f

# Open shell in container
shell:
	docker-compose -f docker/docker-compose.yml exec vicobot sh

# Clean up
clean:
	docker-compose -f docker/docker-compose.yml down -v
	docker image rm vicobot:latest || true

# Development mode (mount source code)
dev:
	docker-compose -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up --build

# Production mode
prod:
	docker-compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml up -d --build

# Initialize workspace
init:
	docker-compose -f docker/docker-compose.yml run --rm vicobot ./vicobot onboard

# Test build
test-build:
	docker build --no-cache -t vicobot:test docker/

# Show status
status:
	docker-compose -f docker/docker-compose.yml ps
