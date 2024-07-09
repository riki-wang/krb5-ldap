#!/usr/bin/expect

set ldap_port 349

set password [lindex $argv 0]
set ldap_host [lindex $argv 1]
set ldap_base_dn [lindex $argv 2]
set ldap_port [lindex $argv 3]

if {[llength $argv] > 3} {
    set ldap_port [lindex $argv 3]
}

set timeout 10

spawn kdb5_ldap_util -D cn=Manager,$ldap_base_dn -w $password -H ldap://$ldap_host:$ldap_port stashsrvpw -f /var/lib/krb5kdc/krb5.ldap  cn=Manager,$ldap_base_dn
expect {
  "Password for" {
    send "$password\r"
    exp_continue
  }
  "Re-enter password for" {
    send "$password\r"
  }
}

expect eof
