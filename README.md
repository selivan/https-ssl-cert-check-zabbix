Script to check validity and expiration of TLS/SSL certificate for given host, port and (optional) servername for TLS SNI.

May be used standalone or with Zabbix. See example of integration in `userparameters_ssl_cert_check.conf` and [zabbix manual](https://www.zabbix.com/documentation/current/manual/config/items/userparameters) about user parameters.

#### Usage

`ssl_cert_check.sh valid|expire <hostname or IP> [port][/[starttls protocol]] [domain for TLS SNI] [check timeout (seconds)]`

* `[port]` optional, default is 443
* `[starttls protocol]` is optional, default is "tls". See "man s_client" for supported values.
* `[domain for TLS SNI]` optional, default is `<hostname or IP>`.  
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)*(Server Name Indication) is used to specify certificate domain name if it differs from the hostname.*
* `[check timeout (seconds)]` optional, default is 5 seconds

#### Return values

* `1|0`  for validity check: 1 - valid, 0 - invalid, expired or unavailable
* `N`  number of days left for expiration check. Zero or negative value means certificate is expired
* `-65535`  site was unavailable for expiration check or incorrect script parameters

#### Examples

```bash
user@host:~$ ./ssl_cert_check.sh valid valid.example.com
1

user@host:~$ ./ssl_cert_check.sh valid imap.valid.example.com 993
1

# SMTP on port 25 reqires STARTTLS. It is necessary to specify the protocol
# to use STARTTLS. Supported protocols depend on the openssl version used.
# For recent openssl versions the following protocols are supported:
#  smtp, pop3, imap, ftp, xmpp, xmpp-server, irc, postgres, mysql,
#  lmtp, nntp, sieve, ldap
# For more details about supported protocols refer to "man s_client"
user@host:~$ ./ssl_cert_check.sh valid smtp.valid.example.com 25/smtp
1

user@host:~$ ./ssl_cert_check.sh valid invalid.example.com
0

# Expired certificate is not valid
user@host:~$ ./ssl_cert_check.sh valid expired.example.com
0

user@host:~$ ./ssl_cert_check.sh expire effective-next-90-days.example.com
90

user@host:~$ ./ssl_cert_check.sh expire expired-37-days-ago.example.com
-37

# NOTE: an error message is shown to stderr only when running on a terminal
# Without terminal(from zabbix), only the result is printed to stdout
user@host:~$ ./ssl_cert_check.sh expire unavailable.example.com
-65535
ERROR: Failed to get certificate

# Check 127.0.0.1:443 for a valid certificate for example.com
# TLS SNI(Server Name Indication) is set to example.com
user@host:~$ ./ssl_cert_check.sh valid 127.0.0.1 443 example.com
1

# Check 127.0.0.1:443 for a valid certificate for example.com
# TLS SNI(Server Name Indication) is set to example.com
# Check timeout is 10 seconds(default is 5)
user@host:~$ ./ssl_cert_check.sh valid 127.0.0.1 443 example.com 10
1
```

#### Using with busybox, like Alpine-based Docker images

Busybox `date` can not parse date format from `openssl`. If you are using busybox, for example for Alpine-based Docker images, install `coreutils` package.


**P.S.** If this code is useful for you - don't forget to put a star on it's [github repo](https://github.com/selivan/https-ssl-cert-check-zabbix).
