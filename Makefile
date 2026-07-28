.PHONY: dev down logs backend-test backend-lint test lint

dev:
	docker compose up --build

down:
	docker compose down -v

logs:
	docker compose logs -f

backend-test:
	cd backend && python -m pytest -v

backend-lint:
	cd backend && python -m ruff check .

test: backend-test

lint: backend-lint
