FROM python:3-alpine

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY srv-etl.py .

RUN addgroup -S www && adduser -S www -G www
USER www

CMD [ "python", "./srv-etl.py" ]
