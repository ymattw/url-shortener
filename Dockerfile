FROM python:2.7-alpine

COPY src /opt/url-shortener
COPY config.json.sample /opt/url-shortener/config.json

RUN apk add --no-cache musl-dev postgresql-dev gcc && pip install -r /opt/url-shortener/requirements.txt

EXPOSE 80
CMD ["/opt/url-shortener/url_shortener_server.py"]
