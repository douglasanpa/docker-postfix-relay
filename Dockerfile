FROM alpine:3.11
LABEL maintainer "Douglas Andrade <douglasanpa@gmail.com>"

ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

EXPOSE 25
ENTRYPOINT ["fileenv", "/entrypoint.sh"]
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 CMD netstat -an | fgrep 25 | fgrep -q LISTEN


# 1: install required packages
# 2: prepare configuration files
RUN apk --no-cache add ca-certificates gettext libintl postfix openssl cyrus-sasl-plain cyrus-sasl-login tzdata rsyslog supervisor git make musl-dev go  \
    && cp /usr/bin/envsubst /usr/local/bin/ \
    && apk --no-cache del gettext \
    mkdir -p ${GOPATH}/src ${GOPATH}/bin && go get github.com/korylprince/fileenv &&\
    && ln -fs /root/conf/rsyslog.conf /etc/rsyslog.conf \
    && ln -fs /root/conf/supervisord.conf /etc/supervisord.conf

# copy required files
COPY bin/ /usr/local/bin/
COPY conf/ /root/conf/
COPY conf/config.conf /etc/postfix/
COPY entrypoint.sh /
