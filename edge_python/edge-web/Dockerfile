FROM busybox:1.37

RUN addgroup -S www && adduser -S www -G www

USER www

WORKDIR /app

COPY index.html .

CMD ["busybox", "httpd", "-f", "-v", "-p", "80"]
