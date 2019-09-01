#!/bin/bash

rsync -avz --progress -e 'ssh -p 22' rlsServer/ local@73.189.41.182:/home/local/rlsServer/