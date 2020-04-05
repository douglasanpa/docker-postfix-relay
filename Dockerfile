FROM alpine:3.11
LABEL maintainer "Douglas Andrade <douglasanpa@gmail.com>"

EXPOSE 25
ENTRYPOINT ["/entrypoint.sh"]

# 1: install required packages
# 2: prepare configuration files
RUN apk --no-cache add ca-certificates gettext libintl postfix bash nano mailx mutt busybox-extras openssl libsasl cyrus-sasl-plain cyrus-sasl-crammd5 cyrus-sasl-dev cyrus-sasl-gs2 cyrus-sasl-gssapiv2 cyrus-sasl-login cyrus-sasl-ntlm cyrus-sasl-scram cyrus-sasl-openrc tzdata rsyslog supervisor \
    && cp /usr/bin/envsubst /usr/local/bin/ \
    && apk --no-cache del gettext \
    && ln -fs /root/conf/rsyslog.conf /etc/rsyslog.conf \
    && ln -fs /root/conf/supervisord.conf /etc/supervisord.conf

# copy required files
COPY bin/ /usr/local/bin/
COPY conf/ /root/conf/
COPY conf/config.conf /etc/postfix/
COPY entrypoint.sh /
