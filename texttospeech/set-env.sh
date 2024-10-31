#!/bin/bash

# set-env.sh
export $(cat .env | xargs)

# Use AWS CLI to configure credentials
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_DEFAULT_REGION"

echo "AWS configuration set successfully."

# echo $AWS_ACCESS_KEY_ID
# echo $AWS_SECRET_ACCESS_KEY