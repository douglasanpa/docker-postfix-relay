#!/usr/bin/env sh
set -e # exit on error

# Variables
[ -z "$SMTP_LOGIN" -o -z "$SMTP_PASSWORD" ] && {
	echo "SMTP_LOGIN and SMTP_PASSWORD _must_ be defined" >&2
	exit 1
}

if [ -n "$RECIPIENT_RESTRICTIONS" ]; then
	RECIPIENT_RESTRICTIONS="inline:{$(echo $RECIPIENT_RESTRICTIONS | sed 's/\s\+/=OK, /g')=OK}"
else
	RECIPIENT_RESTRICTIONS=static:OK
fi

export SMTP_LOGIN SMTP_PASSWORD RECIPIENT_RESTRICTIONS
export SMTP_HOST=${SMTP_HOST:-"email-smtp.us-east-1.amazonaws.com"}
export SMTP_PORT=${SMTP_PORT:-"25"}
export ACCEPTED_NETWORKS=${ACCEPTED_NETWORKS:-"192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"}
export USE_TLS=${USE_TLS:-"no"}
export NO_REPLY_TEXT=${NO_REPLY_TEXT:-"NO REPLY THIS EMAIL"}
export TLS_VERIFY=${TLS_VERIFY:-"may"}

# Template
export DOLLAR='$'
envsubst < /root/conf/postfix-main.cf > /etc/postfix/main.cf

openssl dsaparam 1024 > /etc/postfix/dsa1024.pem
openssl req -x509 -config /etc/postfix/config.conf  -nodes -days 3650 -newkey dsa:/etc/postfix/dsa1024.pem -out /etc/postfix/mycert.pem -keyout /etc/postfix/mykey.pem;ln  -s /etc/postfix/mycert.pem /etc/postfix/CAcert.pem
openssl req -x509 -config /etc/postfix/config.conf  -new -days 3650 -key /etc/postfix/mykey.pem -out /etc/postfix/mycert.pem;rm /etc/postfix/dsa1024.pem

touch /etc/postfix/generic
echo "root@$HOSTNAME $SMTP_MAIL" >> /etc/postfix/generic
echo "root@$HOSTNAME.localdomain $SMTP_MAIL" >> /etc/postfix/generic
echo "@$HOSTNAME $SMTP_MAIL" >> /etc/postfix/generic
echo "@$HOSTNAME.localdomain $SMTP_MAIL" >> /etc/postfix/generic
echo "[$SMTP_HOST]:$SMTP_PORT    $SMTP_LOGIN:$SMTP_PASSWORD" >>  /etc/postfix/sasl_passwd
echo "/.+/    $SMTP_MAIL" >> /etc/postfix/sender_canonical_maps
echo "/From:.*/ REPLACE From: \"$NO_REPLY_TEXT\" <$SMTP_MAIL>" >> /etc/postfix/header_check

newaliases

# Generate default alias DB
postmap /etc/postfix/sasl_passwd;postmap /etc/postfix/generic;postmap /etc/postfix/main.cf

# Launch
rm -f /var/spool/postfix/pid/*.pid
exec supervisord -n -c /etc/supervisord.conf
