# command run nfs server
docker run --rm -itd --name nfs --privileged -v /home/app/project:/nfs.1 -e SHARED_DIRECTORY=/nfs.1 -p 0.0.0.0:2049:2049 itsthenetwork/nfs-server-alpine:latest

# note command docker stack
docker stack deploy --with-registry-auth

docker run --rm -itd --name nfs --privileged -v $PWD:/nfs.1 -e SHARED_DIRECTORY=/nfs.1 -p 0.0.0.0:2049:2049 itsthenetwork/nfs-server-alpine:latest

cp -v *.pem ~/.docker

[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/home/huuhadz2k/.docker/ca.pem --tlscert=/home/huuhadz2k/.docker/server-cert.pem --tlskey=/home/huuhadz2k/.docker/server-key.pem \
  -H=0.0.0.0:2376 -H unix:///var/run/docker.sock

docker run \
  -v /home/huuhadz2k/nfs_share:/nfs \
  -v /home/huuhadz2k/test/server.keytab:/etc/krb5.keytab:ro \
  -v /home/huuhadz2k/test/server.krb5conf:/etc/krb5.conf:ro \
  -e NFS_ENABLE_KERBEROS=1 \
  --hostname my-nfs-server.com \
  -e NFS_EXPORT_0='/nfs                 *(ro,no_subtree_check)' \
  --cap-add SYS_ADMIN \
  -p 2049:2049 \
  erichough/nfs-server

docker run                                                  \
  -v /home/app/nfs_share:/nfs                         \
  -e NFS_EXPORT_0='/nfs                 *(ro,no_subtree_check)' \
  -e NFS_ENABLE_KERBEROS=1                                  \
  --hostname my-nfs-server.com                              \
  --cap-add SYS_ADMIN                                       \
  -p 2049:2049                                              \
  erichough/nfs-server

# Change all file type from dos to unix
find . -type f -exec dos2unix {} \;