#!/bin/bash


if [ $# -lt 3 ]; then
  echo Script requires 3 parameters in the following order: username, hostname, command
  exit 1
fi

# Parse arguments
USER=$1
shift
HOST=$1
shift
CMD=$*
KERB_KEYTAB=$RD_CONFIG_KERBEROS_KEYTAB

if [ ! -f $KERB_KEYTAB ]; then
  >&2 echo Keytab $KERB_KEYTAB not found
  exit 2
fi

# random delay (0..0.5s) to make it work with parallel exec
sleep $(bc <<< "scale=2; $(printf '0.%02d' $(( $RANDOM % 100))) / 2")

# status 1 if the credentials cache cannot be read or is expired, and with status 0 otherwise
klist -s
if [ $? -ne 0 ]; then
  kinit -kt $KERB_KEYTAB $RD_CONFIG_KERBEROS_USER

  # verify ticket has been successfuly created
  klist -s
  if [ $? -ne 0 ]; then
    >&2 echo Kinit failure when calling kinit -kt $KERB_KEYTAB $RD_CONFIG_KERBEROS_USER
    exit 2
  fi
fi

SSHOPTS=" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"
RUNSSH="ssh $SSHOPTS $USER@$HOST $CMD"

exec $RUNSSH

if [[ ${RD_CONFIG_DO_KDESTROY} == 'true' ]]; then
  kdestroy
fi
