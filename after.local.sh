#! /bin/sh
#
# Copyright (c) 2010 SuSE LINUX Products GmbH, Germany.  All rights reserved.
#
# Author: Werner Fink, 2010
#
# /etc/init.d/after.local
#
# script with local commands to be executed from init after all scripts
# of a runlevel have been executed.
#
# Here you should add things, that should happen directly after
# runlevel has been reached.
#

# Wait 5min to make sure all scripts finished their processes
sleep 5m

# Validate if HANA Service is ok, and restart if not
d=`TZ='America/Sao_Paulo' date +"%Y-%m-%d %T %z:>"`
countProcess=`ps ax | grep -i ' hdb' | wc -l`
logFile='/var/log/check-hdb-processes.log'

echo $d ' Count HDB Process -' $countProcess
echo $d ' Count HDB Process -' $countProcess >> $logFile

if [ $countProcess -lt 8 ]; then
    sudo -H -u ndbadm bash -c 'cd /usr/sap/NDB/HDB00; ./HDB stop'
    sleep 30s
    
    sudo -H -u ndbadm bash -c 'cd /usr/sap/NDB/HDB00; ./HDB start'
    sleep 1m
    service sapb1servertools restart

    d=`TZ='America/Sao_Paulo' date +"%Y-%m-%d %T %z:>"`
    echo $d ' HDB Services restarted' >> $logFile
    countProcess=`ps ax | grep -i ' hdb' | wc -l`
    echo $d ' Count HDB Process -' $countProcess
    echo $d ' Count HDB Process -' $countProcess >> $logFile
else
    echo "HDB Services are ok"
fi