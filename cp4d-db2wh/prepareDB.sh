#!/bin/sh
set -x

DB2WHPOD=${1}
DB_NAME=${2}
DB_USERNAME=${3}
DEPLOYMENT_SIZE=${4}
DEPLOYMENT_SIZE=$( echo ${DEPLOYMENT_SIZE} | awk '{ print toupper($0) }')
DB_SCHEMA=$( echo ${DB_USERNAME} | awk '{ print toupper($0) }')

echo $DB2WHPOD
echo $DB_NAME
echo $DB_USERNAME
echo $DEPLOYMENT_SIZE
echo $DB_SCHEMA

oc cp db2configinst.sh $DB2WHPOD:/tmp
oc cp db2configdb.sh $DB2WHPOD:/tmp
oc cp create-ts.sql $DB2WHPOD:/tmp
oc cp rundbscripts.sh $DB2WHPOD:/tmp
oc cp db2_best_practices.sh $DB2WHPOD:/tmp
oc exec -ti $DB2WHPOD -- chmod 666 /tmp/create-ts.sql /tmp/db2configdb.sh /tmp/db2configinst.sh /tmp/rundbscripts.sh /tmp/db2_best_practices.sh
oc exec -ti $DB2WHPOD -- sudo wvcli system disable -m "Disable HA before Db2 maintenance"
oc exec -ti $DB2WHPOD -- su - db2inst1 -c "sh /tmp/rundbscripts.sh $DB_NAME $DB_USERNAME"
oc exec -ti $DB2WHPOD -- su - db2inst1 -c "sh /tmp/db2_best_practices.sh $DB_NAME $DB_SCHEMA $DEPLOYMENT_SIZE"
oc exec -ti $DB2WHPOD -- sudo wvcli system enable -m "Enable HA after Db2 maintenance"
