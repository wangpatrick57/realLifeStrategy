#!/bin/bash
rsync -avz --progress -e 'ssh -p 22' stableServer/ local@73.189.41.182:/home/local/stableServer/
rsync -avz --progress -e 'ssh -p 22' testServer/ local\
@73.189.41.182:/home/local/testServer/