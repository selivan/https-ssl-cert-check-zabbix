#!/bin/bash

function error_usage() {
	echo -1
	cat >&2 << EOF
	Usage: $(basename $0) expire|valid hostname port [check_timeout]

	Script checks SSL cerfificate expiration and validity for HTTPS.

	check_timeout is optional, default 5 seconds.

	Output:
	* expire:
	  * N	number of days left before expiration, 0 or negative if expired
	  * -65535	failed to get certificate
	* valid:
	  * 1	valid
	  * 0	invalid
	  * -65535	failed to get certificate

	Return code is always 0, otherwise zabbix agent fails to get item.
EOF

	exit 0
}

function error() { echo -65535; echo "ERROR: $@" >&2; exit 0; }

function result() { echo "$1"; exit 0; }

# Arguments
check_type="$1"
host="$2"
port="$3"
check_timeout="${4:-5}"

ssl_ca_path=/etc/ssl/certs

# Check if required utilites exist
for util in timeout openssl date; do
	which "$util" >/dev/null || error "Not found in \$PATH: $util"
done
# Check arguments
[ "$#" -lt 3 ] && error_usage
[ "$check_type" = "expire" -o "$check_type" = "valid" ] || error "Wrong check type. Should be one of: expire,valid"
[[ "$port" =~ ^[0-9]+$ ]] || error "Port should be a number"
[ "$port" -ge 1 -a "$port" -le 65535 ] || error "Port should be between 1 and 65535"
[[ "$check_timeout" =~ ^[0-9]+$ ]] || error "Check timeout should be a number"

[ -n "$err_message" ] && print_usage "ERROR: $err_message" && exit 255

# Get certificate
output=$( echo \
| timeout "$check_timeout" openssl s_client -CApath "$ssl_ca_path" -servername "$host" -connect "$host":"$port" 2>/dev/null )
[ $? -ne 0 ] && error "Failed to get certificate"

# Run checks
if [ "$check_type" = "expire" ]; then

expire_date=$( echo "$output" \
| openssl x509 -noout -dates \
| grep '^notAfter' | cut -d'=' -f2 )

expire_date_epoch=$(date -d "$expire_date" +%s) || error "Failed to get expire date"
current_date_epoch=$(date +%s)
days_left=$(( ($expire_date_epoch - $current_date_epoch)/(3600*24) ))
result "$days_left"

elif [ "$check_type" = "valid" ]; then

verify_return_code=$( echo "$output" | egrep '^[ ]+Verify return code:' | tr -s ' ' | cut -d' ' -f5 )
[ "$verify_return_code" -eq 0 ] && result 1 || result 0

fi
