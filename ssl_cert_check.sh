#!/bin/bash

default_check_timeout=5
error_code=-65535

function show_help() {
	echo $error_code
	# if running on ternimal, show error
	# without terminal(from zabbix) this will create an unsupported item because return value is stdout + stderr
	if [ -t 1 ]; then
	cat >&2 << EOF

Usage: $(basename "$0") expire|valid hostname|ip [port[/starttls protocol]] [domain for TLS SNI] [check_timeout]

Script checks SSL certificate expiration and validity for HTTPS.

[port] is optional, default is 443

[starttls protocol] is optional. Use protocol-specific message to switch to TLS communication. See "man s_client" for supported protocols, like: smtp, ftp, ldap

[domain for TLS SNI] is optional, default is hostname

[check_timeout] is optional, default is $default_check_timeout seconds

Output:

* expire:

  * N	number of days left before expiration, 0 or negative if expired
  * $error_code	failed to get certificate or incorrect parameters

* valid:

  * 1	valid
  * 0	invalid
  * $error_code	failed to get certificate or incorrect parameters

Return code is always 0, otherwise zabbix agent fails to get item value and triggers would not work. Note: error messages are not printed when running not on a terninal, so that script result from zabbix is always a correct integer.
EOF
	fi

}

function error() { echo $error_code; if [ -t 1 ]; then echo "ERROR: $*" >&2; fi; exit 0; }

function result() { echo "$1"; exit 0; }


# Arguments
check_type="$1"
host="$2"
port="${3:-443}"
domain="${4:-$host}"
check_timeout="${5:-$default_check_timeout}"

starttls=""
starttls_proto=""

IFS='/' split=($port)

if [ ${#split[@]} -gt 1 ]; then
	port="${split[0]}"
	if [ "${split[1]}" != "tls" ]; then
		starttls="-starttls"
		starttls_proto="${split[1]}"
	fi
fi

# Check if required utilities exist
for util in timeout openssl date; do
	type "$util" >/dev/null || error "Not found in \$PATH: $util"
done

# Check that busybox date isn't used: it does not support requited date format
if date --version 2>&1 | grep -qi 'busybox'; then
	error "Busybox date does not support parsing required date format. date from coreutils package is required"
fi

# Check arguments
[ "$#" -lt 2 ] && show_help && exit 0
[ "$check_type" = "expire" ] || [ "$check_type" = "valid" ] || error "Wrong check type. Should be one of: expire,valid"
[[ "$port" =~ ^[0-9]+$ ]] || error "Port should be a number"
{ [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; } || error "Port should be between 1 and 65535"
if [ ! -z "$starttls_proto" ]; then
	[[ "$starttls_proto" =~ ^[a-z0-9]+$ ]] || error "Starttls protocol should be an identifier"
fi
[[ "$check_timeout" =~ ^[0-9]+$ ]] || error "Check timeout should be a number"

# Get certificate
if ! output=$( echo \
| timeout "$check_timeout" openssl s_client $starttls $starttls_proto -servername "$domain" -verify_hostname "$domain" -connect "$host":"$port" 2>/dev/null )
then
	error "Failed to get certificate"
fi

# Run checks
if [ "$check_type" = "expire" ]; then
	expire_date=$( echo "$output" \
	| openssl x509 -noout -dates \
	| grep '^notAfter' | cut -d'=' -f2 )

	expire_date_epoch=$(date -d "$expire_date" +%s) || error "Failed to get expire date"
	current_date_epoch=$(date +%s)
	days_left=$(( (expire_date_epoch - current_date_epoch)/(3600*24) ))
	result "$days_left"
elif [ "$check_type" = "valid" ]; then
	# Note: new openssl versions can print multiple return codes for post-handshake session tickets, so we need to get only the first one
	verify_return_code=$( echo "$output" | grep -E '^ *Verify return code:' | sed -n 1p | sed 's/^ *//' | tr -s ' ' | cut -d' ' -f4 )
	if [ "$verify_return_code" -eq "0" ]; then result 1; else result 0; fi
fi
