#!/bin/bash
set -x

DB_NAME=${1}
DB_SCHEMA=${2}
DEPLOYMENT_SIZE=${3}

# Disable Auto Maintenance - from Cloud team
db2 update db cfg for $DB_NAME using AUTO_MAINT OFF;
db2 update db cfg for $DB_NAME using AUTO_RUNSTATS OFF;
db2 update db cfg for $DB_NAME using AUTO_STMT_STATS OFF;
db2 update db cfg for $DB_NAME using AUTO_SAMPLING OFF;
db2 update db cfg for $DB_NAME using AUTO_TBL_MAINT OFF;
db2 update db cfg for $DB_NAME using AUTO_REORG OFF;
db2 update db cfg for $DB_NAME using AUTO_STATS_VIEWS OFF;

# Change specific db2wh defaults
# DDL_CONSTRAINT_DEF is set in db2configdb.sh
db2 update db cfg for $DB_NAME using dft_table_org row;


# DB2 Parameter settings - from Cloud team
db2set DB2_PARALLEL_IO=*;
db2set DB2_INLIST_TO_NLJN=YES;
db2set DB2_MINIMIZE_LISTPREFETCH=YES;
db2set DB2_SKIPDELETED=ON;
db2set DB2_SKIPINSERTED=ON;
db2set DB2_EVALUNCOMMITTED=YES;
db2set DB2_COMPATIBILITY_VECTOR=ORA
db2set DB2_DEFERRED_PREPARE_SEMANTICS=YES
db2set DB2_ATS_ENABLE=YES
db2set DB2_USE_ALTERNATE_PAGE_CLEANING=ON

# Change DB2 log settings - from Cloud team
db2 update db cfg for $DB_NAME using logsecond 176;
db2 update db cfg for $DB_NAME using LOGPRIMARY 80;
db2 update db cfg for $DB_NAME using logbufsz 32767;

if [ "$DEPLOYMENT_SIZE" == "SMALL" ]
then
  db2 update db cfg for $DB_NAME using logfilsiz 32767;
elif [ "$DEPLOYMENT_SIZE" == "MEDIUM" ]
then
  db2 update db cfg for $DB_NAME using logfilsiz 32767;
elif [ "$DEPLOYMENT_SIZE" == "LARGE" ]
then
  db2 update db cfg for $DB_NAME using logfilsiz 96000;
elif [ "$DEPLOYMENT_SIZE" == "VERY LARGE" ]
then
  db2 update db cfg for $DB_NAME using logfilsiz 262144;
fi

# Update database manager configs - Cloud settings
db2 update dbm cfg using cpuspeed -1
db2 update dbm cfg using comm_bandwidth -1
db2 update dbm cfg using SYSADM_GROUP DB2IADM1
db2 update dbm cfg using SYSCTRL_GROUP $DB_SCHEMA
db2 update dbm cfg using RQRIOBLK 65535

# Database monitor settings - Cloud settings help with DB2 monitoring
db2 update dbm cfg using DFT_MON_STMT ON
db2 update dbm cfg using DFT_MON_TIMESTAMP ON

# Update database configs
db2 update db cfg for $DB_NAME using STMT_CONC OFF
db2 update db cfg for $DB_NAME using string_units CODEUNITS32

# Avoid Deadlock
db2 update db cfg for $DB_NAME using LOCKTIMEOUT 300

#DB2 Memory Settings - Cloud settings
db2 update dbm cfg using INSTANCE_MEMORY 80
db2 update db cfg for $DB_NAME using DB_MEM_THRESH 100
db2 update db cfg for $DB_NAME using STMTHEAP 60000 AUTOMATIC
db2 update db cfg for $DB_NAME using CATALOGCACHE_SZ 8192

# CP4D Issue https://github.ibm.com/DB2/tracker/issues/15062
# Uncomment after it is fixed
#db2 update db cfg for $DB_NAME using SHEAPTHRES_SHR 1500000 automatic immediate
#db2 update db cfg for $DB_NAME using SORTHEAP 200000 automatic immediate

# Bind packages
db2 connect to $DB_NAME
cd /mnt/blumeta0/home/db2inst1/sqllib/bnd
db2 bind @db2cli.lst blocking all grant public sqlerror continue CLIPKG 10
db2 bind '/mnt/blumeta0/home/db2inst1/sqllib/bnd/db2clipk.bnd' collection NULLIDR1

# Bufferpool Changes
db2 "CREATE BUFFERPOOL TEMPSPACEBP IMMEDIATE ALL DBPARTITIONNUMS SIZE 50000 AUTOMATIC PAGESIZE 32768"
db2 "ALTER TABLESPACE TEMPSPACE1 BUFFERPOOL TEMPSPACEBP"

