#!/bin/bash

if [ $# -lt 4 ]; then
  echo "Script requires 4 parameters in the following order: username, hostname, src_file, dest_file" >&2
  exit 1
fi

# Parse arguments
USER=$1
shift
HOST=$1
shift
SRC_FILE=$1
shift
DEST_FILE=$1

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
RUNSSH='scp $SSHOPTS "$SRC_FILE" $USER@$HOST:"${DEST_FILE// /\\ }"'

#finally, execute scp but don't print to STDOUT
eval $RUNSSH 1>&2 || exit $? # exit if not successful
echo "$DEST_FILE" # echo remote filepath

if [[ ${RD_CONFIG_DO_KDESTROY} == 'true' ]]; then
  kdestroy
fi
