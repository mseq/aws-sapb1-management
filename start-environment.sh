#!/bin/bash
#
# Script to START ENVIRONMENT
#  Creates the WinClientImage bkp based on the base instance
#  Run the cloud formation stack, to create
#    - NetworkLoadBalance
#    - AutoScalingGroup
#    - TargetGroup
#  And finally start the NAT Instance
#

function LogInfo () {
    dt=`date +"%Y-%m-%d %T %z - STARTENV:>"`
    echo "$dt $1"
}

d=`date +%Y%m%d`
h=`date +%H:%M`
LogInfo "Starting StartEnvironment Script $d $h"

# res=`aws ssm get-parameter --name 'Start-SAPB1-Environment' --output text --query 'Parameter.Value'`

# if [ $res == $h ]; then

    # Check if the image was already created, then if not create image/bkp and update Parameter Store
    res=`aws ec2 describe-images --output text --query 'Images[*].ImageId' --filters "Name=name,Values=WinClient-IMG-$d"`
    if [ -z $res ]; then
        res=`aws ssm get-parameter --name 'CFN-NLB-WinClientInstance' --output text --query 'Parameter.Value'`
        res=`aws ec2 create-image --instance-id $res --name "WinClient-IMG-$d" --output text --query 'ImageId'`
        LogInfo "Creating img $res"
    else
        LogInfo "Image exists $res"
    fi

    # Make sure the image is available
    state=`aws ec2 describe-images --query 'Images[*].State' --output text --filters "Name=image-id,Values=$res"`
    LogInfo "Image state $state"
    while [ "$state" != "available" ]
    do
        sleep 30s
        state=`aws ec2 describe-images --query 'Images[*].State' --output text --filters "Name=image-id,Values=$res"`
        LogInfo "Image state $state"
    done
    res=`aws ssm put-parameter --name 'CFN-NLB-WinCientAMI-Id' --type 'String' --value "$res" --overwrite`
    LogInfo "SSM Parameter Store Updated"

    # Execute Cloud Formation Stack
    res=`aws ssm get-parameter --name 'CFN-NLB-StackName' --output text --query 'Parameter.Value'`
    url=`aws ssm get-parameter --name 'CFN-NLB-TemplateUrl' --output text --query 'Parameter.Value'`
    LogInfo "Creating CloudFormation Stack $res"
    res=`aws cloudformation create-stack --stack-name $res --template-url $url --capabilities CAPABILITY_NAMED_IAM --tags "Key=Department,Value=TI" "Key=Environment,Value=Production" "Key=Name,Value=SAP HANA WinClient ELB" "Key=Product,Value=SAP B1"`

    # Start NAT Instance 
    res=`aws ssm get-parameter --name 'NatInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    LogInfo "Starting NAT Instance $res"
    res=`aws ec2 start-instances --instance-ids $res`

    # Start AD Instance 
    res=`aws ssm get-parameter --name 'ADInstance-SAPB1-Environment' --output text --query 'Parameter.Value'`
    LogInfo "Starting AD Instance $res"
    res=`aws ec2 start-instances --instance-ids $res`

# fi