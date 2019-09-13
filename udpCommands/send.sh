#!/bin/bash
echo "$1" | nc -p 60001 -cu "10.0.1.128" 8889