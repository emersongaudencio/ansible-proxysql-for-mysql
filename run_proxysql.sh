#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_HOST=${1}
VAR_PX_MODE=${2}
VAR_MONITOR_USER=${3}
VAR_MONITOR_PASS=${4}

if [ "${VAR_HOST}" == '' ] ; then
  echo "No host specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_PX_MODE}" == '' ] ; then
  echo "No ProxySQL Mode specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MONITOR_USER}" == '' ] ; then
  echo "No MaxScale Monitor user specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MONITOR_PASS}" == '' ] ; then
  echo "No MaxScale Monitor password specified. Please have a look at README file for futher information!"
  exit 1
fi

### ProxySQL Setup ####
ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{px_mode: '$VAR_PX_MODE', monitor_user: '$VAR_MONITOR_USER', monitor_pass: '$VAR_MONITOR_PASS'}" $SCRIPT_PATH/playbook/proxysql.yml -l $VAR_HOST
