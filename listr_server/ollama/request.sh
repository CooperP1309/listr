#!/usr/bin/env bash
#
#

cat request_commencement.json > temp_request.json

echo "Enter your request:"

read user_request

echo "$user_request" >> temp_request.json

cat request_termination.json >> temp_request.json

curl http://192.168.1.124:11434/api/chat -d @temp_request.json
