FROM alpine:latest

RUN apk add --no-cache bind-tools curl

COPY *.sh /

CMD ["/entrypoint.sh"]
