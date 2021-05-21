Script to check validity and expiration of TLS/SSL certificate on remote host. Supports TLS SNI and STARTTLS for protocols like SMTP.

May be used standalone or with Zabbix. See example of integration in `userparameters_ssl_cert_check.conf` and [zabbix manual](https://www.zabbix.com/documentation/current/manual/config/items/userparameters) about user parameters.

For zabbix, there is also template available in zabbix_template.xml

#### Usage

`ssl_cert_check.sh valid|expire <hostname or IP> [port[/starttls protocol]] [domain for TLS SNI] [check timeout (seconds)]`

* `[port]` optional, default is 443
* `[starttls protocol]` optional, use protocol-specific message to switch to TLS communication. See `man s_client` option `-starttls` for supported protocols, like `smtp`, `ftp`, `ldap`.
* `[domain for TLS SNI]` optional, default is `<hostname or IP>`.  
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)*(Server Name Indication) is used to specify certificate domain name if it differs from the hostname.*
* `[check timeout (seconds)]` optional, default is 5 seconds

#### Return values

* `1|0`  for validity check: 1 - valid, 0 - invalid, expired or unavailable
* `N`  number of days left for expiration check. Zero or negative value means certificate is expired
* `-65535`  site was unavailable for check timeout or incorrect script parameters

Exit code is always 0, otherwise zabbix agent fails to get item value and triggers would not work. 

If the script is running without terminal(from zabbix), error messages are not printed, only exit code. The reason is that zabbix merges stdout and strerr to get item value.

#### Examples

```bash
user@host:~$ ./ssl_cert_check.sh valid valid.example.com
1

user@host:~$ ./ssl_cert_check.sh valid imap.valid.example.com 993
1

# SMTP on port 25 with STARTTLS to switch to TLS communication
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

Busybox `date` can not parse date format from `openssl`. If you are using the script in busybox, for example in Alpine-based Docker images, install `coreutils` and `bash` packages.


**P.S.** If this code is useful for you - don't forget to put a star on it's [github repo](https://github.com/selivan/https-ssl-cert-check-zabbix).
