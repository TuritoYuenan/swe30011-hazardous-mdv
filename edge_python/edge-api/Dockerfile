FROM python:3-alpine

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY srv-api.py .
EXPOSE 8000

RUN addgroup -S www && adduser -S www -G www
USER www

CMD [ "fastapi", "run", "./srv-api.py" ]
