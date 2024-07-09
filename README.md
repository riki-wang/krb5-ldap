# krb5-ldap
A kerberos server docker image compatible with LDAP based on alpine linux

# Environment Variables
- KDC_PORT: krb5kdc port, default 88
- KADMIND_PORT: kadmin port, default 749
- LDAP_HOST: ldap host, default 127.0.0.1
- LDAP_PORT: ldap port, default 389
- LDAP_ADMIN_PWD: ldap admin password, default admin123
- LDAP_BASE_DN: base ldap dn
- KRB5_REALM: kerberos realm

# How to start
## Prepare krb5.conf
```
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
  default_realm = RIKI.EXAMPLE.COM
  dns_lookup_kdc = false
  dns_lookup_realm = false
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true
  renewable = true
  default_tgs_enctypes = aes256-cts-hmac-sha1-96
  default_tkt_enctypes = aes256-cts-hmac-sha1-96
  permitted_enctypes = aes256-cts-hmac-sha1-96
  udp_preference_limit = 1
  kdc_timeout = 3000

[realms]
  RIKI.EXAMPLE.COM = {
    kdc = 192.168.56.101
    admin_server = 192.168.56.101
  }

[domain_realm]
  .riki.example.com = RIKI.EXAMPLE.COM
  riki.example.com = RIKI.EXAMPLE.COM
```
## Edit docker-compose.yaml
```
services:
  krb5:
    image: krb5:v1.0
    restart: always
    container_name: krb5
    environment:
      - LDAP_HOST=192.168.56.101
      - LDAP_BASE_DN=dc=example,dc=com
      - KRB5_REALM=RIKI.EXAMPLE.COM
      - LDAP_ADMIN_PWD=admin123
    volumes:
      - /etc/hosts:/etc/hosts:ro
      - kdc:/var/lib/krb5kdc
      - krb5.conf:/etc/krb5.conf:ro
    network_mode: host
```
