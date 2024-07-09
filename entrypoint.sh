#!/bin/sh

ulimit -n 2048

if [ ! -f /var/lib/krb5kdc/kadm5.acl ]; then
    echo "*/admin@$KRB5_REALM   *" > /var/lib/krb5kdc/kadm5.acl
fi

cat > /etc/supervisord.conf << EOL
[unix_http_server]
file=/run/supervisord.sock  ; the path to the socket file

[supervisord]
logfile=/var/log/supervisord.log ; main log file
;logfile_maxbytes=50MB           ; max main logfile bytes b4 rotation; default 50MB
;logfile_backups=10              ; # of main logfile backups; 0 means none, default 10
;loglevel=info                   ; log level; default info; others: debug,warn,trace
;pidfile=/run/supervisord.pid    ; supervisord pidfile; default supervisord.pid
nodaemon=true                    ; start in foreground if true; default false
;silent=false                    ; no logs to stdout if true; default false
;minfds=1024                     ; min. avail startup file descriptors; default 1024
;minprocs=200                    ; min. avail process descriptors;default 200
;umask=022                       ; process file creation umask; default 022
;user=chrism                     ; setuid to this UNIX account at startup; recommended if root
user=root
;identifier=supervisor           ; supervisord identifier, default is 'supervisor'
;directory=/tmp                  ; default is not to cd during start
;nocleanup=true                  ; don't clean up tempfiles at start; default false
;childlogdir=/var/log/supervisor ; 'AUTO' child log dir
;environment=KEY="value"         ; key value pairs to add to environment
;strip_ansi=false                ; strip ansi escape codes in logs; def. false

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///run/supervisord.sock ; use a unix:// URL for a unix socket

[program:krb5kdc]
command=krb5kdc -n
priority=10

[program:kadmind]
command=kadmind -port $KADMIND_PORT -nofork
priority=100

EOL

cat > /var/lib/krb5kdc/kdc.conf << EOL
[kdcdefaults]
  kdc_ports = $KDC_PORT
  kdc_tcp_ports = $KDC_PORT

[dbmodules]
  LDAP = {
          db_library = kldap
          ldap_kerberos_container_dn = "cn=kerberos,$LDAP_BASE_DN"
          ldap_kdc_dn = "cn=Manager,$LDAP_BASE_DN"
          ldap_kadmind_dn = "cn=Manager,$LDAP_BASE_DN"
          ldap_service_password_file = /var/lib/krb5kdc/krb5.ldap
          ldap_servers =  ldap://$LDAP_HOST:$LDAP_PORT
  }

[realms]
  $KRB5_REALM = {
    master_key_type = aes256-cts-hmac-sha1-96
    acl_file = /var/lib/krb5kdc/kadm5.acl
    dict_file = /var/lib/krb5kdc/words
    admin_keytab = /var/lib/krb5kdc/kadm5.keytab
    supported_enctypes = aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal
    max_renewable_life = 604800
    default_principal_flags = +renewable, +forwardable
    database_module = LDAP
  }

EOL

chmod 0600 /var/lib/krb5kdc/kdc.conf

if [ ! -f /var/lib/krb5kdc/words ]; then
    echo 'password\n123456\nadmin\n' > /var/lib/krb5kdc/words
    chmod 0600 /var/lib/krb5kdc/words
fi

if [ ! -f /var/lib/krb5kdc/krb5.ldap ]; then
    expect /kdb5_ldap_create.sh $LDAP_ADMIN_PWD $LDAP_HOST $LDAP_BASE_DN $LDAP_PORT
    chmod 0600 /var/lib/krb5kdc/krb5.ldap
fi

if [ ! -f /var/lib/krb5kdc/.k5.$KRB5_REALM ]; then
    echo "Init krb5kdc database"
    kdb5_ldap_util -D cn=Manager,$LDAP_BASE_DN -w $LDAP_ADMIN_PWD -H ldap://$LDAP_HOST:$LDAP_PORT create -s -P $LDAP_ADMIN_PWD
fi

if [ ! -d /etc/krb5_keytabs ]; then
    mkdir -p /etc/krb5_keytabs
fi

exec supervisord -c /etc/supervisord.conf
