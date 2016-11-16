FROM python:2.7-alpine

COPY src /opt/url-shortener
COPY config.json.default /opt/url-shortener/config.json

RUN apk add --no-cache musl-dev postgresql-dev && \
    apk add --no-cache --virtual .build-deps gcc && \
    pip install -r /opt/url-shortener/requirements.txt && \
    apk del .build-deps && \
    rm -rf ~/.cache

EXPOSE 80
CMD ["/opt/url-shortener/url_shortener_server.py"]
