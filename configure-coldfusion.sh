#!/bin/bash

/run-coldfusion.sh &
cf_pid=$!

echo 'Waiting for ColdFusion to start...'
sleep 10

pwd_digest=$(echo -n 'admin' | sha1sum | awk '{print toupper($1)}')

echo 'Connecting to ColdFusion...'

curl --location --max-time 30 --retry 5 --fail \
    --silent --show-error \
    --cookie-jar /tmp/cf-cookies.txt \
    --output /tmp/cf-login.log \
    --data-urlencode cfadminPassword=$pwd_digest \
    --data-urlencode requestedURL=/CFIDE/administrator/index.cfm \
    --data-urlencode submit=Login \
    'http://localhost:8500/CFIDE/administrator/enter.cfm'
result=$?
if [[ ! $result -eq 0 ]]; then
    echo "Failed to log in to ColdFusion Administrator (error $result)."
    echo 'Final response was:'
    cat /tmp/cf-login.log
    exit 1
fi

echo 'Configuring ColdFusion...'

retries=0
needs_config=1
while [[ $retries -lt 6 && $needs_config -eq 1 ]]; do
    sleep $(($retries * 3))
    curl --location --max-time 30 --retry 5 --fail \
         --silent --show-error \
         --cookie /tmp/cf-cookies.txt \
         --cookie-jar /tmp/cf-cookies.txt \
         'http://localhost:8500/CFIDE/administrator/index.cfm?configServer=true' \
        | tee /tmp/cf-config.log \
        | fgrep '<title>ColdFusion: Setup Complete</title>' \
        > /dev/null
    result=$?
    if [[ $result -eq 0 ]]; then
        needs_config=0
    else
        echo "Failed to initialize ColdFusion (error $result).  Waiting to retry..."
        retries=$(($retries + 1))
    fi
done

if [[ $needs_config -eq 1 ]]; then
    echo 'Gave up trying to configure ColdFusion.'
    echo 'Final response was:'
    cat /tmp/cf-config.log
    exit 1
fi

rm /tmp/cf-cookies.txt /tmp/cf-login.log /tmp/cf-config.log

echo 'Successfully configured ColdFusion.'
echo 'Stopping ColdFusion...'
kill -TERM $cf_pid
wait $cf_pid
echo 'ColdFusion stopped.'
