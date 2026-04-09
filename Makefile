start:
	docker compose up -d

stop:
	docker compose down

restart:
	make stop && make start

api-cli:
	docker exec -it solyto-api bash

create-user:
	docker exec -it solyto-api php artisan app:user:create