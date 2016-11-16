.PHONY: build compose-up compose-down test lint unit functional clean

IMAGE := ymattw/url-shortener
COVERAGE_OMIT ?= '*/lib*/python*/*,*/pypy-*/*,*/site-packages/*'

build:
	docker build -t $(IMAGE) .

compose-up:
	docker-compose up -d

compose-down:
	docker-compose down

test: lint unit functional

lint:
	pep8 src/*.py test/*.py

unit:
	coverage erase
	coverage run --append --omit=$(COVERAGE_OMIT) test/*test.py
	coverage report --show-missing

functional:
	docker-compose up -d
	@sleep 0.5
	test/functional.sh
	docker-compose down

clean:
	docker-compose down rm
