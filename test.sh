docker run --rm -itd --name nfs --privileged -v /root/project:/nfs.1 -e SHARED_DIRECTORY=/nfs.1 -p 0.0.0.0:2049:2049 itsthenetwork/nfs-server-alpine:latest

docker stack deploy --with-registry-auth

