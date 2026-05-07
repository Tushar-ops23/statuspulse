.PHONY: build up down logs test clean shell

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

test:
	@echo "Checking health endpoint..."
	@curl -s -f http://localhost:8000/health || (echo "Health check failed" && exit 1)
	@echo "Health check passed!"

clean:
	docker compose down -v
	docker system prune -f

shell:
	docker exec -it statuspulse-app bash
