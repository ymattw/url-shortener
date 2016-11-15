.PHONY: build compose-up compose-down test lint functional clean

IMAGE := ymattw/url-shortener

build:
	docker build -t $(IMAGE) .

compose-up:
	docker-compose up -d

compose-down:
	docker-compose down

test: lint unit functional

lint:
	pep8 src/*.py

functional:
	docker-compose up -d
	@sleep 0.5
	test/functional.sh
	docker-compose down

clean:
	docker-compose down rm
