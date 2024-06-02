FROM bash:4.0.44-alpine3.20

COPY ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
