#!/bin/bash
#
# Script to execute the HANA Backup
#  After backup started, it will check for the process
#  As soon the process ends, it will shutdown the server
#

function LogInfo () {
    dt=`TZ='America/Sao_Paulo' date +"%Y-%m-%d %T %z:>"`
    echo "$dt $1"
}

d=`TZ='America/Sao_Paulo' date +%Y%m%d`
h=`TZ='America/Sao_Paulo' date +%H:%M`
w=`TZ='America/Sao_Paulo' date +%u`
w=$(($w -1))

if [ $w -eq -1 ]; then
    w=6
fi

LogInfo "Starting script $d $h..."
res=`aws ssm get-parameter --name 'Environment-Schedule' --output text --query 'Parameter.Value' | jq ".weekdays[$w]" | jq '.["stop-environment"]' | tr -d '"'`

if [ "$res" = "$h" ]; then

        cd /usr/sap/hdbclient
        # res=`./hdbsql -i 00 -n hanadb -u SYSTEM -p B1admin@ "BACKUP DATA USING FILE ('COMPLETE_DATA_BACKUP')"`
        res=`/usr/sap/SAPBusinessOne/ServerTools/Backup/bin/BackupUtility backup -compress -dbserver hanadb:30015 -database SBO_VALTELLINA_BRA -location /hana/shared/backup_service/backups/hanadb_30015 -dbuser SYSTEM -dbpassword B1admin@ -t /tmp/backup_service`
        LogInfo "$res"

        res=`/sbin/shutdown -P`
        LogInfo "$res"

fi
