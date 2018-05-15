FROM alpine:latest

# Install unbound
RUN apk add --update unbound ; \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

COPY unbound.conf /etc/unbound/unbound.conf
COPY root.hints /etc/unbound/root.hints
COPY root.key /etc/unbound/root.key

RUN unbound-checkconf

CMD ["unbound"]
