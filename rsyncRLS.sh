#!/bin/bash

rsync -avz --progress -e 'ssh -p 6789' rlsServer/ local@73.189.41.182:/home/local/rlsServer/