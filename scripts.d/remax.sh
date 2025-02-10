#!/bin/bash

alias ls-ec2s='aws ec2 describe-instances --region eu-west-1 --query "Reservations[*].Instances[*].{Name:Tags[?Key=="Name"]|[0].Value, PublicIP:PublicIpAddress}" --output table'