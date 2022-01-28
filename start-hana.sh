#!/bin/bash
#
# Script to HANA SERVER
#  It finds what is the current HANA Server Instance and starts it
#

function LogInfo () {
    dt=`date +"%Y-%m-%d %T %z - STARTHANA:>"`
    echo "$dt $1"
}

d=`date +%Y%m%d`
h=`date +%H:%M`
LogInfo "Starting StartHana Script $d $h"

# res=`aws ssm get-parameter --name 'Start-HANA-Environment' --output text --query 'Parameter.Value'`

# if [ $res == $h ]; then

    # Check if the image was already created, then if not create image/bkp
    res=`aws ec2 describe-images --output text --query 'Images[*].ImageId' --filters "Name=name,Values=SAPHanaMaster-IMG-$d"`
    if [ -z $res ]; then
        res=`aws ssm get-parameter --name 'HanaInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
        res=`aws ec2 create-image --instance-id $res --name "SAPHanaMaster-IMG-$d" --output text --query 'ImageId'`
        LogInfo "Creating img $res"
    else
        LogInfo "Image exists $res"
    fi

    # Make sure the image is available
    state=`aws ec2 describe-images --query 'Images[*].State' --output text --filters "Name=image-id,Values=$res"`
    LogInfo "Image state $state"
    while [ "$state" != "available" ]
    do
        sleep 300s
        state=`aws ec2 describe-images --query 'Images[*].State' --output text --filters "Name=image-id,Values=$res"`
        LogInfo "Image state $state"
    done

    # Start HANA Instance 
    res=`aws ssm get-parameter --name 'HanaInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    LogInfo "Starting HANA: $res"
    res=`aws ec2 start-instances --instance-ids $res`

# fi