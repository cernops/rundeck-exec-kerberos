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
RUNSSH="scp $SSHOPTS $SRC_FILE $USER@$HOST:$DEST_FILE"

#finally, execute scp but don't print to STDOUT
$RUNSSH 1>&2 || exit $? # exit if not successful
echo "$DEST_FILE" # echo remote filepath

if [[ ${RD_CONFIG_DO_KDESTROY} == 'true' ]]; then
  kdestroy
fi
