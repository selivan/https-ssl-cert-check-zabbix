* `template_ssl_basic.xml` - basic template and userparameters for monitoring of one SSL cert per host
  * copy `userparameters_ssl_cert_check.conf file` into `/etc/zabbix/zabbix_agentd.d` on host
  * import template in zabbix server, assign to host
  * fill macroses for that host:
	* `{$IPADDR}`
	* `{$SSLDOMAIN}`
	* `{$SSLPORT}`
	* `{$TIMEOUT}`
	* `{$EXPIRESWITHIN}`
	* `{$UPDATEINTERVAL}`

* `template_ssl_advanced.xml` - advanced template and userparameters for monitoring of multiple ssl certs per host
  * copy `userparameters_ssl_cert_check.conf` and `userparameters_ssl_cert_discovery.conf` files into `/etc/zabbix/zabbix_agentd.d`
  * copy `ssl_cert_list.json` into `/etc/zabbix/zabbix_agentd.d` and modify to monitor your hosts. Parameter names are self-descriptive.
  * import template in zabbix server, assign to host, wait for auto discovery
