#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Script requires 3 parameters in the following order: username, hostname, command" >&2
  exit 1
fi

# Parse arguments
USER=$1
shift
HOST=$1
shift
CMD=$*

if [ ! -f "$RD_CONFIG_KERBEROS_KEYTAB" ]; then
  echo "Keytab $RD_CONFIG_KERBEROS_KEYTAB not found" >&2
  exit 2
fi

# random delay (0..0.5s) to make it work with parallel exec
sleep "$(bc <<< "scale=2; $(printf '0.%02d' $(( RANDOM % 100))) / 2")"

# override the default kerberos cache file if required
if [ "$RD_CONFIG_USE_KERBEROS_CUSTOM_CACHE_FILE" = 'true' ]; then
  if [ -n "$RD_CONFIG_KERBEROS_CUSTOM_CACHE_FILENAME" ]; then
    export KRB5CCNAME="$RD_CONFIG_KERBEROS_CUSTOM_CACHE_FILENAME"
  elif [[ ${RD_CONFIG_DO_KDESTROY} == 'true' ]]; then
    export KRB5CCNAME=$(mktemp "/tmp/krb5cc_XXXXXX_rundeck_$RD_CONFIG_KERBEROS_USER")
  else
    export KRB5CCNAME="/tmp/krb5cc_$(id -ru)_rundeck_$RD_CONFIG_KERBEROS_USER"
  fi
fi

# recreate the cache if it's expired or not present
if ! klist -s; then
  kinit -kt "$RD_CONFIG_KERBEROS_KEYTAB" "$RD_CONFIG_KERBEROS_USER"
  if ! klist -s; then
    echo "Kinit failure when calling kinit -kt $RD_CONFIG_KERBEROS_KEYTAB $RD_CONFIG_KERBEROS_USER" >&2
    exit 2
  fi
fi

SSHOPTS=" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -o GSSAPIDelegateCredentials=yes"
RUNSSH="ssh $SSHOPTS $USER@$HOST $CMD"

$RUNSSH || exit $? # exit if not successful

if [[ ${RD_CONFIG_DO_KDESTROY} == 'true' ]]; then
  kdestroy
fi
