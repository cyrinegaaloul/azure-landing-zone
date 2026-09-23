FROM python:3.12.14-slim-bookworm

WORKDIR /app

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid appgroup --no-create-home --shell /usr/sbin/nologin appuser

COPY --chown=10001:10001 server.py /app/server.py

ENV APP_HOST=0.0.0.0 \
    APP_PORT=8080 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8080
USER 10001:10001

CMD ["python", "server.py"]
