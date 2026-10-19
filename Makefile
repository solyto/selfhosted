start:
	docker compose up -d

stop:
	docker compose down

restart:
	make stop && make start

update:
	@echo "Updating to the newest solyto images (SOLYTO_VERSION in .env)."
	@echo "Make sure you have a backup: migrations run automatically on start."
	docker compose pull
	docker compose up -d

api-cli:
	docker exec -it solyto-api bash

create-user:
	docker exec -it solyto-api php artisan app:user:create