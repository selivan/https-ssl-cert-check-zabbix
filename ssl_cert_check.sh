#!/usr/bin/env bash

# Default variables
default_check_timeout=5
error_code=-65535
# Use this list to valide if the status code is valid.
openssl_valid_codes=(0)

function show_help() {
	echo $error_code
	# if running on ternimal, show error
	# without terminal(from zabbix) this will create an unsupported item because return value is stdout + stderr
	if [ -t 1 ]; then
	cat >&2 << EOF

Usage: $(basename "$0") expire|valid|json hostname|ip [port[/starttls protocol]] [domain for TLS SNI] [check_timeout] [tls_version|tls_auto,[self_signed_ok]] [ s_client_option1 ] [ ... ] [ s_client_optionN ]

Script checks SSL certificate expiration and validity for HTTPS.

[port] is optional, default is 443

[starttls protocol] is optional. Use protocol-specific message to switch to TLS communication. See "man s_client" for supported protocols, like: smtp, ftp, ldap

[domain for TLS SNI] is optional, default is hostname

[check_timeout] is optional, default is $default_check_timeout seconds

[tls_version|tls_auto,[self_signed_ok]] predefined options comma (`,`) separated, flag is optional. Set what is needed, no order of parameters is present of the available options below.
  * [tls_version] is optional, no default is set. This will auto negotiate the TLS protocol and choose the TLS version itself. Override the TLS version as you need: tls1, tls1_1, tls1_2, tls1_3. See either the [TLS Version Options](https://www.openssl.org/docs/man3.0/man1/openssl.html) section for the TLS options or use "man s_client" for supported TLS options.

  * [self_signed_ok] is optional. When this flag is set all self-signed certificates will be seen as 'valid'. It will allow OpenSSL return codes 18 and 19. See the 'Diagnostics' section at https://www.openssl.org/docs/man1.0.2/man1/verify.html.

  * [tls_auto] means auto negotiating TLS protocol. That is the default, this option is used as separator if you want to speficy additional s_client options after it.

[ s_client_option1 ] [ ... ] [ s_client_optionN ] is optional. But all other parameters are required to be set. Everything you append after all parameters will be added/appended on the OpenSSL s_client command. See all s_client options at https://www.openssl.org/docs/man1.0.2/man1/s_client.html.

Output:

* expire:

  * N	number of days left before expiration, 0 or negative if expired
  * $error_code	failed to get certificate or incorrect parameters

* valid:

  * 1	valid
  * 0	invalid
  * $error_code	failed to get certificate or incorrect parameters

* json:

  * JSON object with a summary of the result, which can be used by Zabbix (JSONPath)
	* expire_days: the amount of days before the certificate is expired
	* valid: see 'valid' check
	* return_code: the OpenSSL return code
	* return_text: the OpenSSL return text which gives helpful insights
  * JSON object with the error code and message
	* error_code: $error_code
	* error_message: The output of the error message

Return code is always 0, otherwise zabbix agent fails to get item value and triggers would not work. Note: error messages are not printed when running not on a terninal, so that script result from zabbix is always a correct integer.
EOF
	fi

}

function error() {
	if [ $check_type == "json" ]; then
		echo "{\"error_code\": $error_code, \"error_message\": \"$*\"}"
		exit 0
	else
		echo $error_code; if [ -t 1 ]; then echo "ERROR: $*" >&2; fi; exit 0;
	fi
}

function result() { echo "$1"; exit 0; }

function get_expire_days() {
	expire_date=$( echo "$output" \
	| openssl x509 -noout -dates \
	| grep '^notAfter' | cut -d'=' -f2 )

	expire_date_epoch=$(date -d "$expire_date" +%s) || error "Failed to get expire date"
	current_date_epoch=$(date +%s)
	days_left=$(( (expire_date_epoch - current_date_epoch)/(3600*24) ))

	echo $days_left
}

# Arguments
check_type="$1"
host="$2"
port="${3:-443}"
domain="${4:-$host}"
check_timeout="${5:-$default_check_timeout}"
options="$6"
s_client_options="${@: 7}"

starttls=""
starttls_proto=""

IFS='/' read -r -a split <<< "${port}"

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
[ "$check_type" = "expire" ] || [ "$check_type" = "valid" ] || [ "$check_type" = "json" ] || error "Wrong check type. Should be one of: expire,valid,json"
[[ "$port" =~ ^[0-9]+$ ]] || error "Port should be a number"
{ [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; } || error "Port should be between 1 and 65535"
if [ -n "$starttls_proto" ]; then
	[[ "$starttls_proto" =~ ^[a-z0-9]+$ ]] || error "Starttls protocol should be an identifier"
fi
[[ "$check_timeout" =~ ^[0-9]+$ ]] || error "Check timeout should be a number"

# Support for IDN(internationalized domain names) with Punycode
# Requires libidn(https://www.gnu.org/software/libidn/)
if type idn > /dev/null 2>&1; then
	host="$(echo 		"${host}" 	| idn 2>/dev/null || echo "${host}"		)"
	domain="$(echo 	"${domain}" | idn 2>/dev/null || echo "${domain}"	)"
fi

# Option handling
# Split the given options (on argument 6), verify what is given and set the appropriate flags
IFS=',' read -r -a split_options <<< "${options}"

# Default options
tls_version=""

# Iterate over every given option and set all the needed flags
for opt in "${split_options[@]}"; do
	# Look for the flag 'self_signed_ok' to set a Self Signed certificate as valid.
	if [ "${opt}" = "self_signed_ok" ]; then
		# Add status codes '18' and '19' as valid in the list. See the 'Diagnostics' section at https://www.openssl.org/docs/man1.0.2/man1/verify.html
		openssl_valid_codes+=(18 19)
	fi

	# Look for a TLS, SSL or DTLS flag and set the flag
	if [[ "${opt}" == "tls_auto" ]]; then
		true
	elif [[ "${opt}" == *"tls"* || "${opt}" == *"ssl"* || "${opt}" == *"dtls"* ]]; then
		tls_version="-${opt}"
	fi
done

# Get certificate
# shellcheck disable=SC2086
if ! output=$( echo \
| timeout "$check_timeout" openssl s_client $starttls $starttls_proto -servername "$domain" -verify_hostname "$domain" -connect "$host":"$port" $tls_version $s_client_options 2>/dev/null )
then
	error "Failed to get certificate"
fi

# Run checks
if [ "$check_type" = "expire" ]; then
	result $(get_expire_days)
elif [[ "$check_type" = "valid" || "$check_type" = "json" ]]; then
	# Note: new openssl versions can print multiple return codes for post-handshake session tickets, so we need to get only the first one
	verify_return_code=$( echo "$output" | grep -E '^ *Verify return code:' | sed -n 1p | sed 's/^ *//' | tr -s ' ' | cut -d' ' -f4 )
	verify_return_text=$( echo "$output" | grep -E '^ *Verify return code:' | sed -n 1p | sed 's/^ *//' | tr -s ' ' | grep -Eo "\(.*\)" | sed 's/(//g; s/)//g' )
	# Check if the return code is in the valid code list
	if [[ "${openssl_valid_codes[*]}" =~ "${verify_return_code}" ]]; then valid=1; else valid=0; fi

	case "$check_type" in
		"valid")
			 result $valid
			 ;;
		"json")
			days=$(get_expire_days)
			result "{\"expire_days\": ${days}, \"valid\": ${valid}, \"return_code\": ${verify_return_code}, \"return_text\": \"${verify_return_text}\"}"
			;;
	esac
fi
