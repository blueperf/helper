#!/bin/bash
# Delete all containers
#docker rm $(docker ps -a -q)

# Delete all images
#docker rmi -f $(docker images -q)

#Delete images from Bluemix Repository
bx cr image-rm $(bx cr images | awk {'print $1}')

