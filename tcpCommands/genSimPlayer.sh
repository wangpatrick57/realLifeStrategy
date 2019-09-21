#!/bin/bash
TCP_NUM=`cat tcpNum.txt`
TCP_NUM=$(( TCP_NUM+1 ))
echo $TCP_NUM > tcpNum.txt
./newPlayer.sh "comp${TCP_NUM}"
./step.sh $TCP_NUM
