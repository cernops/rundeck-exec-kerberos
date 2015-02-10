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

kinit -kt $KERB_KEYTAB $RD_CONFIG_KERBEROS_USER
if [ $? -ne 0 ]; then
  >&2 echo Kinit failure when calling kinit -kt $KERB_KEYTAB $RD_CONFIG_KERBEROS_USER
  exit 2
fi

SSHOPTS=" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"
RUNSSH="ssh $SSHOPTS $USER@$HOST $CMD"

exec $RUNSSH

kdestroy
