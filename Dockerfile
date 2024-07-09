FROM alpine:latest

ENV KDC_PORT=88
ENV KADMIND_PORT=749
ENV LDAP_HOST=127.0.0.1
ENV LDAP_PORT=389
ENV LDAP_ADMIN_PWD=admin123
ENV LDAP_BASE_DN="dc=example,dc=com"
ENV KRB5_REALM=hello.example.com

RUN apk add --update && apk add krb5-server krb5 supervisor expect \
    && rm -rf /var/cache/apk/* 

ADD entrypoint.sh /entrypoint.sh
ADD kdb5_ldap_create.sh /kdb5_ldap_create.sh 

VOLUME ["/var/lib/krb5kdc/", "/etc/krb5_keytabs"]

EXPOSE $KDC_PORT $KADMIND_PORT

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
