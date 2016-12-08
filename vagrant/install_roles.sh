#!/bin/bash
[ -z $(which ansible) ] && echo "ansible executable not found, it is needed for this to work" && exit 1

ansible-galaxy install -r ansible/requirements.yml -p ansible/roles
vagrant up
