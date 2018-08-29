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
KERB_KEYTAB=$RD_CONFIG_KERBEROS_KEYTAB

if [ ! -f "$KERB_KEYTAB" ]; then
  echo "Keytab $KERB_KEYTAB not found" >&2
  exit 2
fi

# random delay (0..0.5s) to make it work with parallel exec
sleep "$(bc <<< "scale=2; $(printf '0.%02d' $(( RANDOM % 100))) / 2")"

# status 1 if the credentials cache cannot be read or is expired, and with status 0 otherwise
klist -s
if [ $? -ne 0 ]; then
  kinit -kt "$KERB_KEYTAB" "$RD_CONFIG_KERBEROS_USER"

  # verify ticket has been successfuly created
  klist -s
  if [ $? -ne 0 ]; then
    echo "Kinit failure when calling kinit -kt $KERB_KEYTAB $RD_CONFIG_KERBEROS_USER" >&2
    exit 2
  fi
fi

SSHOPTS=" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -o GSSAPIDelegateCredentials=yes"
RUNSSH="ssh $SSHOPTS $USER@$HOST $CMD"

$RUNSSH || exit $? # exit if not successful

if [[ ${RD_CONFIG_DO_KDESTROY} == 'true' ]]; then
  kdestroy
fi
