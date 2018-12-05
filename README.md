Script to check validity and expiration of TLS/SSL certificate for given host, port and (optional) servername. May be used with Zabbix(user parameters example included) or standalone.

```
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

# Check 127.0.0.1:443 for a valid example.com certificate
# In case example.com is not resolved to 127.0.0.1
user@host:~$ ./ssl_cert_check.sh valid 127.0.0.1 443 example.com
1
```

**P.S.** If this code is useful for you - don't forget to put a star on it's [github repo](https://github.com/selivan/https-ssl-cert-check-zabbix).
