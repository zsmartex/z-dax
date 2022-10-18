# Z-Dax

Z-Dax is an project template deployment ZSmartex Exchange in `docker-compose` write by [@huuhait](https://github.com/huuhait).

Demo exchange running: [ZSmartex Demo](https://demo.zsmartex.com/)

## Getting started with ZSmartex

### 1. Get the VM

Minimum VM requirements for Z-Dax:
 * 32GB of RAM
 * 16 core dedicated CPU
 * 300GB disk space

A VM from any cloud provider like DigitalOcean, Vultr, GCP, AWS as well as any dedicated server with Ubuntu, Debian or Centos would work

### 2. Prepare the VM

#### 2.1 Create Unix user
SSH using root user, then create new user for the application
```bash
useradd -g users -s `which bash` -m app
```

#### 2.2 Install Docker and docker compose

We highly recommend using docker and compose from docker.com install guide instead of the system provided package, which would most likely be deprecated.

Docker follow instruction here: [docker](https://docs.docker.com/install/)
Docker compose follow steps: [docker compose](https://docs.docker.com/compose/install/)

#### 2.3 Install ruby in user app

##### 2.3.1 Change user using
```bash
su - app
```

##### 2.3.2 Clone Z-Dax
```bash
git clone https://github.com/zsmartex/z-dax.git
```
##### 2.3.3 Install RVM
```bash
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
cd zsmartex
rvm install .
```

### 3. Bundle install dependencies

```bash
bundle install
rake -T # To see if ruby and lib works
```

Using `rake -T` you can see all available commands, and can create new ones in `lib/tasks`

### 4. Setup everything

#### 4.1 Configure your domain
If using a VM you can point your domain name to the VM ip address before this stage.
Recommended if you enabled SSL, for local development edit the `/etc/hosts`

Insert in file `/etc/hosts`
```
0.0.0.0 www.app.local
0.0.0.0 sync.app.local
0.0.0.0 adminer.app.local
```

#### 4.2 Setup Postgresql and Vault

```bash
rake service:proxy service:backend db:setup
```

### 4.3 Setup kafka-connect

SOON

### 4.4 Setup QuestDB

SOON

You can login on `www.app.local` with the following default users from seeds.yaml
```
Seeded users:
Email: business@zsmart.tech, password: aQ#QLbG48m@L
Email: admin@zsmart.tech, password: aQ#QLbG48m@L
Email: demo@zsmart.tech, password: aQ#QLbG48m@L
Email: test@zsmart.tech, password: aQ#QLbG48m@L
```
