_Just a toy project for demo purpose._

**Table of Contents**

  - [About](#about)
  - [Requirements](#requirements)
  - [Demo](#demo)
  - [Usage](#usage)
  - [Request and Response](#request-and-response)
  - [Development Guide](#development-guide)

# About

This is a RESTful web service that provides the [URL
shortening](https://en.wikipedia.org/wiki/URL_shortening) service.

See also [DESIGN.md](DESIGN.md) for the design thoughts.

# Requirements

Requirements to run the service are

- Docker. The service is delivered as a docker image so you need docker
- A Postgres DB server

# Demo

Start a docker compose environment

    $ make compose-up

This will pull docker image `postgres:9.6-alpine` (48 MB) and
`ymattw/url-shortener` (109 MB).

Once the compose environment is up, try send requests to the API server
listening on `localhost:9988`:

    $ curl -sX POST -H 'Content-Type: application/json' 'localhost:9988/v1/shorten' -d '{"url":"http://example.com"}'
    {"short":"http://localhost/1"}

    $ curl -sX GET -H 'Content-Type: application/json' 'localhost:9988/v1/original' -d '{"short":"http://localhost/1"}'
    {"original":"http://example.com"}

# Usage

To build the docker image locally:

    $ make build

To run with your own Postgres server, a config.json file will be needed.

    $ cp config.json.default config.json
    $ vim config.json  # Fill in Postgres server, port, database, etc.

Now run the service with the config:

    $ docker run --rm -v $PWD/config.json:/opt/url-shortener/config.json:ro -p 8080:80 ymattw/url-shortener

# Request and Response

## Shortening long URL

### Request

`POST /:version/shorten` with header `Content-Type: application/json` and a body JSON in format `{ "url": "http://example.com" }`.

`:version` must be `v1` at this moment.

### Response

Response is a status code with human readable message in HTTP header and a JSON
blob in body text. Status codes are listed below.

| Status Code   | Message               | Explanation                                       |
| ------------- | --------------------- | ------------------------------------------------- |
| 200           | OK                    | Success, result JSON will be in body              |
| 400           | BAD REQUEST           | Input is not a valid URL                          |
| 500           | INTERNAL SERVER ERROR | Unknown error happened on server side (check log) |
| 501           | NOT IMPLEMENTED       | Not supported API version                         |

Body JSON is in format `{"short":"http://domain/abcdef"}` when status code is
200, or absent otherwise.

## Get original URL

### Request

`GET /:version/original` with header `Content-Type: application/json` and a body JSON in format `{ "short": "http://domain/abcdef" }`.

`:version` must be `v1` at this moment.

### Response

Response is a status code with human readable message in HTTP header and a JSON
blob in body text. Status codes are listed below.

| Status Code   | Message               | Explanation                                                             |
| ------------- | --------------------- | ----------------------------------------------------------------------- |
| 200           | OK                    | Success, result JSON will be in body                                    |
| 400           | BAD REQUEST           | Input is invalid (not under our domain or contains unacceptable chars)  |
| 404           | NOT FOUND             | Given slug not found                                                    |
| 500           | INTERNAL SERVER ERROR | Unknown error happened on server side (check log)                       |
| 501           | NOT IMPLEMENTED       | Not supported API version                                               |

Body JSON is in format `{"original":"http://example.com"}` when status code is
200, or absent otherwise.

# Development Guide

Highly recommend to use [virtualenv](http://docs.python-guide.org/en/latest/dev/virtualenvs/).
Once you have virtualenv bootstrapped, initialize a virtual env like this
(example):

    $ virtualenv ~/venv
    $ source ~/venv/bin/activate
    (venv) $ pip install -r test/test_requirements.txt

Then type `make test` to test changes.

To exit the virtual env:

    (venv) $ deactivate
