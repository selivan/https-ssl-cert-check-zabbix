Script to check validity and expiration of SSL certificate on HTTPS site. May be used with Zabbix(user parameters example included) or standalone.

```
user@host:~$ ./ssl_cert_check.sh valid valid.example.com 443
1
user@host:~$ ./ssl_cert_check.sh valid invalid.example.com 443
0
# Shown as invalid because it's expired
user@host:~$ ./ssl_cert_check.sh valid expired.example.com 443
0
user@host:~$ ./ssl_cert_check.sh expire effective-next-90-days.example.com 443
90
user@host:~$ ./ssl_cert_check.sh expire expired.example.com 443
-37
user@host:~$ ./ssl_cert_check.sh expire unavailable.example.com 443
-65535
ERROR: Failed to get certificate
```

**P.S.** If this code is useful for you - don't forget to put a star on it's [github repo](https://github.com/selivan/https-ssl-cert-check-zabbix).
