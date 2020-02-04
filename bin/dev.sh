# for Dev work on vm test ^^!
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,dmode=755,fmode=644 z-dax ~/microkube
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,dmode=755,fmode=644 z-control ~/z-control
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,dmode=755,fmode=644 postmaster ~/postmaster
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,dmode=755,fmode=644 peatio ~/peatio
sudo mount -t vboxsf -o rw,uid=1000,gid=1000,dmode=755,fmode=644 barong ~/barong

# command run nfs server
docker run --rm -itd --name nfs --privileged -v /home/app/project:/nfs.1 -e SHARED_DIRECTORY=/nfs.1 -p 0.0.0.0:2049:2049 itsthenetwork/nfs-server-alpine:latest

# note command docker stack
docker stack deploy --with-registry-auth
