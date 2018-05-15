FROM alpine:latest

# Install unbound
RUN apk add --update unbound bash bind-tools && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Expose udp port
EXPOSE 53/udp

RUN unbound-checkconf

CMD ["unbound"]
