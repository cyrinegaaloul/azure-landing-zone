FROM python:3.12-slim

WORKDIR /app

COPY server.py /app/server.py

ENV APP_HOST=0.0.0.0
ENV APP_PORT=8080

EXPOSE 8080

CMD ["python", "server.py"]
