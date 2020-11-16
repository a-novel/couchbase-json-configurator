#!/bin/sh

# Check user configuration, based on couchbase rules.

# From couchbase documentation:
# Couchbase Server requires that administrators and applications authenticate, in order to gain access to data,
# settings, and statistics. Authentication typically requires that a username and password be provided.
# More at https://docs.couchbase.com/server/current/learn/security/usernames-and-passwords.html

DIVAN_USERNAME=""
DIVAN_PASSWORD=""

[ -n "$DIVAN_SECRET" ] && [ -f "$DIVAN_SECRET" ] && { jq empty "${DIVAN_SECRET}" 2>/dev/null; } && {
  DIVAN_USERNAME="$(jq -re '.username // empty' <"${DIVAN_SECRET}")"
  DIVAN_PASSWORD="$(jq -re '.password // empty' <"${DIVAN_SECRET}")"
}

[ -z "$DIVAN_USERNAME" ] && DIVAN_USERNAME="$(jq -re '.database.username // empty' <"${DIVAN_CONFIG}")"
[ -z "$DIVAN_PASSWORD" ] && DIVAN_PASSWORD="$(jq -re '.database.password // empty' <"${DIVAN_CONFIG}")"

if [ -z "$DIVAN_USERNAME" ]; then
  printf "missing .database.username\n" 1>&2
  exit 1
fi

# Username shall be less than 128 characters long, and is recommended less than 64.
# https://docs.couchbase.com/server/current/learn/security/usernames-and-passwords.html#usernames-and-roles
if [ "${#DIVAN_USERNAME}" -gt 128 ]; then
  printf ".database.username should not be more than 128 character long\n" 1>&2
  exit 1
fi

# Username cannot start with an '@', and should not contain the following characters: ( ) < > , ; : \ " / [ ] ? = { }
# https://docs.couchbase.com/server/current/learn/security/usernames-and-passwords.html#usernames-and-roles
case $DIVAN_USERNAME in
"@"*) {
  printf ".database.username cannot start with '@'\n" 1>&2
  exit 1
} ;;
*"("*) {
  printf ".database.username cannot contain character '('\n" 1>&2
  exit 1
} ;;
*")"*) {
  printf ".database.username cannot contain character ')'\n" 1>&2
  exit 1
} ;;
*"<"*) {
  printf ".database.username cannot contain character '<'\n" 1>&2
  exit 1
} ;;
*">"*) {
  printf ".database.username cannot contain character '>'\n" 1>&2
  exit 1
} ;;
*","*) {
  printf ".database.username cannot contain character ','\n" 1>&2
  exit 1
} ;;
*";"*) {
  printf ".database.username cannot contain character ';'\n" 1>&2
  exit 1
} ;;
*":"*) {
  printf ".database.username cannot contain character ':'\n" 1>&2
  exit 1
} ;;
*'\'*) {
  printf ".database.username cannot contain character '\\\\'\n" 1>&2
  exit 1
} ;;
*'"'*) {
  printf ".database.username cannot contain character '\"'\n" 1>&2
  exit 1
} ;;
*"/"*) {
  printf ".database.username cannot contain character '/'\n" 1>&2
  exit 1
} ;;
*"["*) {
  printf ".database.username cannot contain character '['\n" 1>&2
  exit 1
} ;;
*"]"*) {
  printf ".database.username cannot contain character ']'\n" 1>&2
  exit 1
} ;;
*"?"*) {
  printf ".database.username cannot contain character '?'\n" 1>&2
  exit 1
} ;;
*"="*) {
  printf ".database.username cannot contain character '='\n" 1>&2
  exit 1
} ;;
*"{"*) {
  printf ".database.username cannot contain character '{'\n" 1>&2
  exit 1
} ;;
*"}"*) {
  printf ".database.username cannot contain character '}'\n" 1>&2
  exit 1
} ;;
esac

# Password is required, couchbase doesn't allow non secure access.
if [ -z "$DIVAN_PASSWORD" ] || [ "$DIVAN_PASSWORD" = "null" ]; then
  printf "missing .database.password\n" 1>&2
  exit 1
fi

# We keep with the default 6 characters policy for Couchbase password.
# https://docs.couchbase.com/server/current/learn/security/usernames-and-passwords.html#password-strengthd
if [ "${#DIVAN_PASSWORD}" -lt 6 ]; then
  printf ".database.password should be at least 6 character long\n" 1>&2
  exit 1
fi

echo "DIVAN_USERNAME=\"$DIVAN_USERNAME\" DIVAN_PASSWORD=\"$DIVAN_PASSWORD\""
exit 0