#!/bin/bash
TCP_NUM=$1
LOC="${TCP_NUM}.00000"
for i in {1..1000}; do ./send.sh "loc:${LOC}:${LOC}:rec:"; sleep 3; done