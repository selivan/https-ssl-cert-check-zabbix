`basic` template creates validity and expiration items and triggers for macros `{$EXPIRESWITHIN}`, `{$IPADDR}`, `{$SSLDOMAIN}`, `{$SSLPORT}`, `{$TIMEOUT}`, `{$UPDATEINTERVAL}`. Macros are defined in the template and should be re-defined for every host using this template.

`advanced` template uses autodiscovery from file `/etc/zabbix/scripts/ssl_cert_list`, example file provided. Parameter names are self-descriptive. This way a single zabbix host can make checks for multiple SSL endpoints.
