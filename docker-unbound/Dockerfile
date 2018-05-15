FROM alpine:latest

# Install unbound
RUN apk add --update unbound bash bind-tools && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Expose udp port
EXPOSE 53/udp

COPY unbound.conf /etc/unbound/unbound.conf
COPY root.hints /var/unbound/etc/root.hints
COPY root.key /var/unbound/etc/root.key

RUN unbound-checkconf

CMD ["unbound"]
