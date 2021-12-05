# nginx-auto-ssl publish on docker reminder
1) build the latest image

    docker build .

2) find the new image ID

    docker images

copy the first IMAGEID value in the list (eg: 2133c8f98f8a)

3) tag the imageid 

    docker tag 2133c8f98f8a elestio/nginx-auto-ssl:latest

4) push to docker hub

    docker push elestio/nginx-auto-ssl:latest
