#!/bin/sh
# Commands to restore Database
set -x

DB_NAME=${1}
DB_USERNAME=${2}

echo $DB_NAME
echo $DB_USERNAME

#db2 connect to $DB_NAME
#db2 force application all
#db2 terminate
#db2 deactivate database $DB_NAME
#db2stop force
#db2start admin mode restricted access
#db2 RESTORE DATABASE TRIRIGA FROM /tmp TAKEN AT 20210823021710 ON /mnt/blumeta0/db2/databases DBPATH ON /mnt/blumeta0/db2/databases INTO $DB_NAME NEWLOGPATH DEFAULT WITHOUT ROLLING FORWARD WITHOUT PROMPTING
#db2 restore db tridb from /mnt/blumeta0/backups/ taken at $1 WITH 2 BUFFERS BUFFER 1024 PARALLELISM 1 WITHOUT PROMPTING REPLACE EXISTING WITHOUT ROLLING FORWARD;
#db2stop force
#db2start
#db2 activate db $DB_NAME

# Config Instance by running db2configinst.sh
sh /tmp/db2configinst.sh db2inst1 50000 /mnt/blumeta0/home/db2inst1/sqllib
sleep 15
# Config DB by running db2configdb.sh
sh /tmp/db2configdb.sh $DB_NAME db2inst1 US /mnt/blumeta0/home/db2inst1/sqllib $DB_USERNAME

# Run script to load tablespaces
SEDCMD1="s/DB_NAME/${DB_NAME}/g"
SEDCMD2="s/DB_USERNAME/${DB_USERNAME}/g"
sed -e $SEDCMD1 -e $SEDCMD2 </tmp/create-ts.sql>/tmp/tablespace.sql
db2 -tvf /tmp/tablespace.sql
