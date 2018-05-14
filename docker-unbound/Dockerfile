FROM alpine:latest

# Install unbound
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    apk add --update unbound bash bind-tools && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Expose udp port
EXPOSE 53/udp

WORKDIR /etc/unbound

COPY unbound.conf /etc/unbound/unbound.conf
COPY root.hints /var/unbound/etc/root.hints
COPY root.key /var/unbound/etc/root.key

RUN unbound-checkconf

CMD ["unbound"]
