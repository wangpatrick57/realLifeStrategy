#!/bin/bash
if [ "$2" = "" ]; then
    port=60000
else
    port="$2"
fi

echo "$1" | nc -p "$port" -w 0 -u "73.189.41.182" 8889