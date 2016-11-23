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

# grep out the IP
export RANCHER_SERVER_HOST=$(cat /etc/hosts | grep mi.org | awk '{print $1}')
export RANCHER_PORT=8080
export REGISTRY_PORT=5000
export SSH_PASS=vagrant
export SSH_USER=vagrant
export ADMIN_USER=admin
export ADMIN_PASS=admin
export API_USER=api_admin
export API_PASS=api_admin

#install any ansible roles we may need
ansible-galaxy install --force abaez.docker

#/tmp/ansible/provisionServer.sh || exit $?

export ANSIBLE_HOST_KEY_CHECKING=False

TOPDIR=$(cd $(dirname $0) ; pwd)
ansible-playbook \
  -u $SSH_USER \
  -i ${TOPDIR}/ansible/hosts \
  --extra-vars "ansible_ssh_pass=$SSH_PASS RANCHER_SERVER=$RANCHER_SERVER_HOST RANCHER_PORT=$RANCHER_PORT ADMIN_USER=$ADMIN_USER ADMIN_PASS=$ADMIN_PASS \
  REGISTRY_PORT=$REGISTRY_PORT \
  API_USER=$API_USER API_PASS=$API_PASS"  \
  "${TOPDIR}/ansible/site.yml"
