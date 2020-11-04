---
name:  ''
about: Create a bug report to help improve this code
title: ''
labels: bug
assignees: ''
---

### Environment

`openssl version` says:

```

```

Operating System: <!--- OS you are running the script  -->

### Expected Behavior

<!--- What should happen -->

### Current Behavior

<!--- What happens instead -->

### Diagnostics

* `$domain` TLS/SSL certificate domain name
* `$host` host address, usually the same as `$domain`
* `$port` port to check TLS/SSL, usually 443

`openssl s_client -servername "$domain" -verify_hostname "$domain" -connect "$host":"$port"`

says:

```

```

### Details

<!--- Anything else you think is important -->
