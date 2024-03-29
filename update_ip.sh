#!/bin/sh
[ -z ${DEBUG_OUTPUT+x} ] || set -x
set -o errexit
set -o pipefail

function print_help_and_exit
{
  cat <<EOF
Before starting GoDaddy DynDNS client, please make sure that your environment
defines the following variables:
  - DOMAIN: name of the domain to update (e.g. example.com)
  - RECORD: DNS record to update (e.g. test to update test.example.com)
  - GODADDY_KEY: key associated with your GoDaddy account
  - GODADDY_SECRET: secret associated with your GoDaddy account

To get GoDaddy key/secret, please visit:
  https://developer.godaddy.com/keys/
EOF
  exit
}

function print_dependencies_and_exit
{
  cat <<EOF
Please install the following applications and run the script again:
  - dig
  - curl
EOF
  exit
}

function error
{
  >&2 echo $1
  exit $2
}


[ -z "$DOMAIN" ] && print_help_and_exit
[ -z "$RECORD" ] && print_help_and_exit
[ -z "$GODADDY_KEY" ] && print_help_and_exit
[ -z "$GODADDY_SECRET" ] && print_help_and_exit

hash dig 2> /dev/null || print_dependencies_and_exit
hash wget 2> /dev/null || print_dependencies_and_exit

BASE_URL="https://api.godaddy.com"
URL="$BASE_URL/v1/domains/$DOMAIN/records/A/$RECORD"
AUTH="Authorization: sso-key $GODADDY_KEY:$GODADDY_SECRET"
CURRENT_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
REGISTERED_IP=$(dig +short $RECORD.$DOMAIN)

if [ "$CURRENT_IP" != "$REGISTERED_IP" ]; then
  DATA=$(cat<<EOF
[
  {
    "type": "A",
    "name": "$RECORD",
    "data": "$CURRENT_IP",
    "ttl": 600
  }
]
EOF
)
  TEMP=$(curl -f -sS -H "$AUTH" "$URL")
  [ "$TEMP" == "[]" ] && error "Host or domain not found." 1
  curl -sS --request PUT -f -d "$DATA"  \
       -H "Accept: application/json" \
       -H "Content-Type: application/json" \
       -H "$AUTH" "$URL" > /dev/null
  echo "[`date -u +"%Y-%m-%dT%H:%M:%SZ"`] Successfully changed IP from $REGISTERED_IP to $CURRENT_IP."
fi
