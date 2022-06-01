Script to check validity and expiration of TLS/SSL certificate on remote host. Supports TLS SNI and STARTTLS for protocols like SMTP. Supports internationalized domain names with Punycode(uses [libidn](https://www.gnu.org/software/libidn/)).

May be used standalone or with Zabbix. See the "Zabbix integration" section below.


```bash
user@host:~$ ./ssl_cert_check.sh valid google.com
1

# Check 74.125.131.138 on port 443 for days left before certificate expiration
# TLS SNI(Server Name Indication) is set to google.com
# Check timeout is 15 seconds(default is 5)
# TLS protocol version is forced to 1.2, no auto-negotiation
user@host:~$ ./ssl_cert_check.sh expire 74.125.131.138 443 google.com 15 tls1_2
56

```

- [Usage](#usage)
- [Return values](#return-values)
- [Examples](#examples)
- [Zabbix integration](#zabbix-integration)
- [Support for Internationalized Domain Names with Punycode](#support-for-internationalized-domain-names-with-punycode)
- [Using with busybox, like Alpine-based Docker images](#using-with-busybox-like-alpine-based-docker-images)

#### Usage

`ssl_cert_check.sh valid|expire <hostname or IP> [port[/starttls protocol]] [domain for TLS SNI] [check timeout (seconds)] [tls_version[/any/s_client/options]]`

* `[port]` optional, default is 443.
* `[starttls protocol]` optional, use protocol-specific message to switch to TLS communication: `587/smtp`. See `man s_client` option `-starttls` for supported protocols, like `smtp`, `ftp`, `ldap`.
* `[domain for TLS SNI]` optional, default is `<hostname or IP>`.  
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)*(Server Name Indication) is used to specify certificate domain name if it differs from the hostname.*
* `[check timeout (seconds)]` optional, default is 5 seconds.
* `[tls_version]` optional, if not given a TLS version will be auto negotiated. Override the TLS version as you need, like: `tls1_2`, `tls1_3`, `no_tls1`, `dtls` and so on. See the "TLS Version Options" section of [man openssl](https://www.openssl.org/docs/man3.0/man1/openssl.html) or [man s_client](https://www.openssl.org/docs/man3.0/man1/s_client.html) for the available options.
* `[/any/s_client/options]` Together or instead of TLS protocol version you can add any `s_client` options without dashes and divided by `/`: `dtls1_2/sctp/sctp_label_bug` will become `-dtls1_2 -sctp -sctp_label_bug` options for `s_client`: use DTLS protocol with SCTP transport and incorrect older `openssl` way of computing endpoint-pair shared secrets.

#### Return values

* `1|0`  for validity check: 1 - valid, 0 - invalid, expired or unavailable
* `N`  number of days left for expiration check. Zero or negative value means certificate is expired
* `-65535`  site was unavailable for check timeout or incorrect script parameters

Exit code is always 0, otherwise zabbix agent fails to get the item value.

If the script is running without terminal(from zabbix), error messages are not printed, only the exit code. The reason is that zabbix merges stdout and strerr to get an item value.

#### Examples

```bash
user@host:~$ ./ssl_cert_check.sh valid google.com
1

user@host:~$ ./ssl_cert_check.sh valid imap.gmail.com 993
1

# SMTP on port 587 with STARTTLS to switch to TLS communication
user@host:~$ ./ssl_cert_check.sh valid smtp.gmail.com 587/smtp
1

user@host:~$ ./ssl_cert_check.sh valid self-signed.badssl.com
0

# Expired certificate is not valid
user@host:~$ ./ssl_cert_check.sh valid expired.badssl.com
0

user@host:~$ ./ssl_cert_check.sh expire google.com
56

user@host:~$ ./ssl_cert_check.sh expire expired.badssl.com
-2606

# NOTE: an error message is shown to stderr only when running on a terminal
# Without terminal(from zabbix), only the result is printed to stdout
user@host:~$ ./ssl_cert_check.sh expire unavailable.example.com
-65535
ERROR: Failed to get certificate

# Check 74.125.131.138:443 for a valid certificate for google.com
# TLS SNI(Server Name Indication) is set to google.com
# Check timeout is 10 seconds(default is 5)
user@host:~$ ./ssl_cert_check.sh valid 74.125.131.138 443 google.com 10
1

# Check a certificate on an endpoint only accepting TLS 1.2 and use TLS 1.2, which is valid.
user@host:~$ ./ssl_cert_check.sh valid tls-v1-2.badssl.com 1012 tls-v1-2.badssl.com 10 tls1_2
1

# Check a certificate on an endpoint only accepting TLS 1.2, but use TLS 1.1, which is invalid.
user@host:~$ ./ssl_cert_check.sh valid tls-v1-2.badssl.com 1012 tls-v1-2.badssl.com 10 tls1_1
-65535
ERROR: Failed to get certificate

```

#### Zabbix integration

Example of Zabbix [user parameters](https://www.zabbix.com/documentation/current/manual/config/items/userparameters) is in `userparameters_ssl_cert_check.conf`.

You can write your own template or use one of two example templates in `zabbix_template_examples` directory.

`basic` - basic template and userparameter for monitoring of one SSL cert per host

* copy userparameters_ssl_cert_check.conf file into /etc/zabbix/zabbix_agentd.d on host
* import template in zabbix server, assign to host, fill macros on that host

`advanced` - advanced template and userparameter for monitoring of multiple ssl certs per hosts

* copy userparameters_ssl_cert_check.conf file into /etc/zabbix/zabbix_agentd.d
* copy and modify ssl_cert_list into /etc/zabbix/scripts/ssl_cert_list
* import template in zabbix server, assign to host, either run discovery or wait

#### Support for Internationalized Domain Names with Punycode

If `idn` executable([libidn](https://www.gnu.org/software/libidn/)) is available, unicode host and domain names be will supported by converting to [Punycode](https://en.wikipedia.org/wiki/Punycode) representation. Absence of `idn` does not break the script, but unicode domains will not be supported.

#### Using with busybox, like Alpine-based Docker images

Busybox `date` can not parse date format from `openssl`. If you are using the script in busybox, for example in Alpine-based Docker images, install `coreutils` and `bash` packages.

**P.S.**

If this code is useful for you - don't forget to put a star on it's [github repo](https://github.com/selivan/https-ssl-cert-check-zabbix).
