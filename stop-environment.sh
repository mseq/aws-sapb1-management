#!/bin/bash
#
# Script to STOP ENVIRONMENT
#  Kill the CloudFormation Stack, so the resources created are destroyed
#  Expunge the older image
#  And finally shutdown NatInstance
#

function LogInfo () {
    dt=`date +"%Y-%m-%d %T %z - STOPENV:>"`
    echo "$dt $1"
}

d=`date +%Y%m%d`
h=`date +%H:%M`
LogInfo "Starting StopEnvironment Script $d $h"

# res=`aws ssm get-parameter --name 'ShutDown-SAPB1-Environment' --output text --query 'Parameter.Value'`

# if [ $res == $h ]; then

    # Kill Cloud Formation Stack
    res=`aws ssm get-parameter --name 'CFN-NLB-StackName' --output text --query 'Parameter.Value'`
    LogInfo "Deleting Cloud Formation Stack: $res"
    res=`aws cloudformation delete-stack --stack-name "$res"`

    # Expunge Image Backup with Expiring Retention Period for 3 consecutive days
    exdays=`aws ssm get-parameter --name 'RetentionPeriod-SAPB1-Environment' --output text --query 'Parameter.Value'`
    for i in {0..2}; do
        days=$((exdays + i))
        d=`date -d "-$days days" +%Y%m%d`
        resw=`aws ec2 describe-images --query 'Images[*].ImageId' --output text --filters "Name=name,Values=WinClient-IMG-$d"`
        resh=`aws ec2 describe-images --query 'Images[*].ImageId' --output text --filters "Name=name,Values=SAPHanaMaster-IMG-$d"`
        if [ -z $resw ]; then
            LogInfo "No WinClient image to delete $d"
        else
            LogInfo "Deleting IMG $d: $resw"
            res=`aws ec2 deregister-image --image-id "$resw"`
        fi
        if [ -z $resh ]; then
            LogInfo "No HanaMaster image to delete $d"
        else
            LogInfo "Deleting IMG $d: $resh"
            res=`aws ec2 deregister-image --image-id "$resh"`
        fi
    done
<<<<<<< HEAD
=======

    # # Shutdown NAT Instance 
    # res=`aws ssm get-parameter --name 'NatInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    # LogInfo "Stoping NAT Instance: $res"
    # res=`aws ec2 stop-instances --instance-ids "$res"`
>>>>>>> 83092a3fbefec48f7a59c9c810dfb225d29ee846

    # # Shutdown AD Instance 
    # res=`aws ssm get-parameter --name 'ADInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    # LogInfo "Stoping AD Instance: $res"
    # res=`aws ec2 stop-instances --instance-ids "$res"`

    # Shutdown WinClient Instance
    res=`aws ssm get-parameter --name 'CFN-NLB-WinClientInstance' --output text --query 'Parameter.Value'`
    LogInfo "Stoping WinClient Instance: $res"
    res=`aws ec2 stop-instances --instance-ids "$res"`

    # Shutdown HANA Instance
    res=`aws ssm get-parameter --name 'HanaInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    LogInfo "Stoping HANA Instance: $res"
    res=`aws ec2 stop-instances --instance-ids "$res"`

    # Shutdown NAT Instance 
    res=`aws ssm get-parameter --name 'NatInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    LogInfo "Stoping NAT Instance: $res"
    res=`aws ec2 stop-instances --instance-ids "$res"`

    # # Shutdown Other Instances - RDP
    # LogInfo "Stoping other instances."
    # res=`aws ec2 stop-instances --instance-ids i-0c7f6dcbf24c6c7f8`

# fi