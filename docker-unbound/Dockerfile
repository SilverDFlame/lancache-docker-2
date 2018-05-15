FROM alpine:latest

# Install unbound
RUN apk add --update --no-cache unbound curl ca-certificates \
    && curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache ;\

COPY unbound.conf /etc/unbound/unbound.conf

RUN unbound-checkconf

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["unbound"]
CMD ["-d"]
