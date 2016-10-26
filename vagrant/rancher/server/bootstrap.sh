#!/bin/bash

echo "== Create an user for provisioning"
ANSIBLE_USER=ansible
ANSIBLE_DIR=/home/ansible
useradd ${ANSIBLE_USER}
echo "${ANSIBLE_USER}:${ANSIBLE_USER}" | chpasswd
sed  -i.bk -e 's/^PasswordAuth.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart

echo "== Done!"
