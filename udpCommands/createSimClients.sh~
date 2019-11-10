#!/bin/bash
for playerNum in {1..50}
do
    name=comp"$playerNum"
    echo "$name"
    port=$(( 60000+playerNum ))
    echo "$port"
    ./newPlayer.sh "$name" Home "$name" "$port"
done