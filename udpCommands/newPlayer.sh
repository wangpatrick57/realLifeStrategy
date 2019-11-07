#!/bin/bash
if [ "$1" = "" ]; then
    name="comp1"
else
    name="$1"
fi

if [ "$2" = "" ]; then
    gameID="Home"
else
    gameID="$2"
fi

uuid="$3"

port="$4"

./send.sh uuid:"$uuid":checkIDj:"$gameID":checkName:"$name":loc:1:1:team:red:simClient: "$port"