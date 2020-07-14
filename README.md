Script to check validity and expiration of TLS/SSL certificate for given host, port and (optional) servername for TLS SNI.

May be used standalone or with Zabbix. See example of integration in `userparameters_ssl_cert_check.conf` and [zabbix manual](https://www.zabbix.com/documentation/current/manual/config/items/userparameters) about user parameters.

#### Usage

`ssl_cert_check.sh valid|expire <hostname or IP> <port> [domain for TLS SNI] [check timeout (seconds)]`

* `[domain for `[TLS SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)`]` default is `<hostname or IP>`.
* `[check timeout]` default is 5 seconds

#### Return values

* `1|0`  for validity check: 1 - valid, 0 - invalid, expired or unavailable
* `N`  number of days left for expiration check. Zero or negative value means certificate is expired
* `-65535`  site was unavailable for expiration check

#### Examples

```bash
user@host:~$ ./ssl_cert_check.sh valid valid.example.com 443
1

user@host:~$ ./ssl_cert_check.sh valid invalid.example.com 443
0

# Expired certificate is not valid
user@host:~$ ./ssl_cert_check.sh valid expired.example.com 443
0

user@host:~$ ./ssl_cert_check.sh expire effective-next-90-days.example.com 443
90

user@host:~$ ./ssl_cert_check.sh expire expired-37-days-ago.example.com 443
-37

user@host:~$ ./ssl_cert_check.sh expire unavailable.example.com 443
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

**P.S.** If this code is useful for you - don't forget to put a star on it's [github repo](https://github.com/selivan/https-ssl-cert-check-zabbix).
