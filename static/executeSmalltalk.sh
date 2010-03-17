#!/bin/bash

source ./switch_environment

$GEMSTONE/bin/topaz -q -l << EOF > /dev/null
display oops
output pushnew $GEMSTONE_LOGDIR/executeSmalltalk.log
login
run
$1
System commitTransaction.
%
logout
exit
EOF