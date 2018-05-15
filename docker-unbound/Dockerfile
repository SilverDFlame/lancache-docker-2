FROM alpine:latest

# Install unbound
RUN apk add --update --no-cache unbound ; \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

COPY unbound.conf /etc/unbound/unbound.conf
COPY root.hints /etc/unbound/root.hints
COPY root.key /etc/unbound/root.key

EXPOSE 53/udp

RUN unbound-checkconf

CMD ["unbound"]
