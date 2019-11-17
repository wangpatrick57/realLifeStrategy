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

./send.sh "0:${uuid}:10:${gameID}:11:${name}:15:1:1:14:red:7:" "${port}"