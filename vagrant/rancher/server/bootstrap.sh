#!/bin/bash

# System update + some basics
cat > /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum update -y
yum install -y ntpdate wget curl vim docker-engine

# install docker-compose, because, why not...
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# This makes vagrant-ssh faster
sed -i.bk -e 's#.*UseDNS.*#UseDNS no#g' /etc/ssh/sshd_config
sed -i.bk -e 's#.*GSSAPIAuthentication.*#GSSAPIAuthentication no#g' /etc/ssh/sshd_config

# Config ntpd
ntpdate -u time.nist.gov
rm -rf /etc/localtime  && ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime

# Setup docker and preinstall rancher server
chkconfig docker on
service docker start
docker pull rancher/server:v1.0.2

# Launch the server
docker run --name rancher-server -v /data/rancher-server:/var/lib/mysql -d --restart=always -p 8080:8080 rancher/server:v1.0.2

echo "== Configure ntp client $(ts)"
yum install -y ntp
echo "server clousr-ntp-server prefer" >> /etc/ntp.conf
rm -rf /etc/localtime  && ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime
chkconfig ntpd on
service ntpd start

echo "== Done!"
