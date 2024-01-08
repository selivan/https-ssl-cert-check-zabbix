Zabbix in containers: https://www.zabbix.com/documentation/current/en/manual/installation/containers

`docker compose up -d`

Zabbix web interface: http://127.0.0.1:8080/  Error "can not find a configuration" is OK, wait about a minute.

Default user and password: Admin:zabbix

Add agent: zabbix-agent 10050

Install openssl in agent:
```
docker compose exec -u 0 zabbix-agent sh -c 'apk add openssl curl'
```

Now you can debug templates.
