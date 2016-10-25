#!/bin/bash

if [ -z "$(which ansible)" ] ; then
  yum install -y epel-release
  yum update -y
  yum install -y ntpdate ntp wget curl vim ansible

  echo "== Configure ntp client"

  # Config ntpd
  ntpdate -u time.nist.gov
  rm -rf /etc/localtime  && ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime
  chkconfig ntpd on
  service ntpd start

fi

# This makes vagrant-ssh faster
sed -i.bk -e 's#.*UseDNS.*#UseDNS no#g' /etc/ssh/sshd_config
sed -i.bk -e 's#.*GSSAPIAuthentication.*#GSSAPIAuthentication no#g' /etc/ssh/sshd_config


echo "== start provisoning"

# Created by Vagrant
source /tmp/secrets

# Automatically setup during vagrant up
export RANCHER_SERVER_HOST=${RANCHER_SERVER_HOST}
export RANCHER_AGENT_HOST=${RANCHER_AGENT_HOST}
export RANCHER_PORT=8080
export SSH_PASS=vagrant
export SSH_USER=vagrant
export ADMIN_USER=admin
export ADMIN_PASS=admin
export API_USER=api_admin
export API_PASS=api_admin

#install any ansible roles we may need
ansible-galaxy install --force abaez.docker

/tmp/ansible/files/provisionServer.sh || exit $?
/tmp/ansible/files/provisionAgent.sh

echo "== Done!"
