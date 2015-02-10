SSH Kerberos Node Executor Plugin for Rundeck
=============================================

Description
-----------
This is a script type plugin for Rundeck, allowing execution of remote commands
on nodes using a Kerberos ticket. The ticket is obtained before executing the Rundeck
ssh/scp steps.

The user and the path for the kerberos keytab holding the ecrypted key for the
user can be specified via plugin parameters on the project's configuration page.

Parameters
----------

`Kerberos user` - The name of the Kerberos principal going to be authenticated
using the keytab

`Kerberos keytab` - The path to the keytab file used to authenticate the principal

Requirements
------------
The plugin requires Rundeck version 2.4.0 or higher.
