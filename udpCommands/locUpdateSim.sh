#!/bin/bash
while :
do
    for playerNum in {1..10}
    do
	port=$(( 60000+playerNum ))
	./send.sh "15:${playerNum}.00000:${playerNum}.00000:" "$port"
    done

    sleep 1
done