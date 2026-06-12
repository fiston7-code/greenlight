include .envrc

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | \
		sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN}

## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migrations/new name=$1: create a new database migration
.PHONY: db/migrations/new
db/migrations/new:
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up: confirm
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## tidy: tidy and vendor module dependencies, and format and modernize all .go files
.PHONY: tidy
tidy:
	go mod tidy
	go mod verify
	go mod vendor
	go fix ./...
	go fmt ./...

## audit: run quality control checks
.PHONY: audit
audit:
	go mod tidy -diff
	go mod verify
	go vet ./...
	go tool staticcheck ./...
	go test -race -vet=off ./...

# ==================================================================================== #
# BUILD
# ==================================================================================== #

## build/api: build the cmd/api application for local development
.PHONY: build/api
build/api:
	go build -ldflags='-s' -o=./bin/api ./cmd/api

## build/api-linux: build the cmd/api application for Linux (production)
.PHONY: build/api-linux
build/api-linux:
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=./bin/linux_amd64/api ./cmd/api

# ==================================================================================== #
# PRODUCTION
# ==================================================================================== #

production_host_ip = 165.232.71.54

## production/connect: connect to the production server
.PHONY: production/connect
production/connect:
	ssh -i ~/.ssh/id_rsa_greenlight greenlight@$(production_host_ip)

	# ==================================================================================== #
# PRODUCTION
# ==================================================================================== #

production_host_ip = "165.232.71.54"

## production/connect: connect to the production server
.PHONY: production/connect
production/connect:
	ssh -i ~/.ssh/id_rsa_greenlight greenlight@$(production_host_ip)

## production/deploy/api: compile, deploy the api, and run migrations in production
.PHONY: production/deploy/api
production/deploy/api:
	@echo 'Compiling application for Linux...'
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ./bin/linux_amd64/api ./cmd/api
	@echo 'Transferring API binary to server...'
	rsync -P -e "ssh -i ~/.ssh/id_rsa_greenlight" ./bin/linux_amd64/api greenlight@$(production_host_ip):~
	@echo 'Transferring migrations to server...'
	rsync -rP --delete -e "ssh -i ~/.ssh/id_rsa_greenlight" ./migrations greenlight@$(production_host_ip):~
	@echo 'Running database migrations...'
	ssh -i ~/.ssh/id_rsa_greenlight -t greenlight@$(production_host_ip) 'migrate -path ~/migrations -database $$GREENLIGHT_DB_DSN up'

	# ==================================================================================== #
# PRODUCTION
# ==================================================================================== #

production_host_ip = '165.232.71.54'

## production/connect: connect to the production server
.PHONY: production/connect
production/connect:
	ssh -i ~/.ssh/id_rsa_greenlight greenlight@$(production_host_ip)

## production/deploy/api: deploy the api to production
.PHONY: production/deploy/api
production/deploy/api:
	@echo 'Compiling application for Linux...'
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ./bin/linux_amd64/api ./cmd/api
	@echo 'Transferring files to server...'
	rsync -P -e "ssh -i ~/.ssh/id_rsa_greenlight" ./bin/linux_amd64/api greenlight@$(production_host_ip):~
	rsync -rP --delete -e "ssh -i ~/.ssh/id_rsa_greenlight" ./migrations greenlight@$(production_host_ip):~
	rsync -P -e "ssh -i ~/.ssh/id_rsa_greenlight" ./remote/production/api.service greenlight@$(production_host_ip):~
	@echo 'Executing remote deployment commands...'
	ssh -i ~/.ssh/id_rsa_greenlight -t greenlight@$(production_host_ip) '\
		migrate -path ~/migrations -database $$GREENLIGHT_DB_DSN up \
		&& sudo mv ~/api.service /etc/systemd/system/greenlight.service \
		&& sudo systemctl daemon-reload \
		&& sudo systemctl enable greenlight \
		&& sudo systemctl restart greenlight \
	'

	# ==================================================================================== #
# PRODUCTION
# ==================================================================================== #

production_host_ip = '165.232.71.54'

## production/connect: connect to the production server
.PHONY: production/connect
production/connect:
	ssh -i ~/.ssh/id_rsa_greenlight greenlight@$(production_host_ip)

## production/deploy/api: deploy the api, migrations, and server configs to production
.PHONY: production/deploy/api
production/deploy/api:
	@echo 'Compiling application for Linux...'
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ./bin/linux_amd64/api ./cmd/api
	@echo 'Transferring files to server...'
	rsync -P -e "ssh -i ~/.ssh/id_rsa_greenlight" ./bin/linux_amd64/api greenlight@$(production_host_ip):~
	rsync -rP --delete -e "ssh -i ~/.ssh/id_rsa_greenlight" ./migrations greenlight@$(production_host_ip):~
	rsync -P -e "ssh -i ~/.ssh/id_rsa_greenlight" ./remote/production/api.service greenlight@$(production_host_ip):~
	rsync -P -e "ssh -i ~/.ssh/id_rsa_greenlight" ./remote/production/Caddyfile greenlight@$(production_host_ip):~
	@echo 'Executing remote deployment commands...'
	ssh -i ~/.ssh/id_rsa_greenlight -t greenlight@$(production_host_ip) '\
		migrate -path ~/migrations -database $$GREENLIGHT_DB_DSN up \
		&& sudo mv ~/api.service /etc/systemd/system/greenlight.service \
		&& sudo systemctl daemon-reload \
		&& sudo systemctl enable greenlight \
		&& sudo systemctl restart greenlight \
		&& sudo mv ~/Caddyfile /etc/caddy/Caddyfile \
		&& sudo systemctl reload caddy \
	'