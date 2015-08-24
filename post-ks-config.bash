#!/bin/bash
/usr/bin/mkdir -p /tmp/auto_build/
cd /tmp/auto_build/
/usr/bin/wget http://192.168.2.1/pub/auto_build/vmhost_autobuild.csv > /dev/null 2&>1
DFEAULT_INT=`/sbin/route -n | /usr/bin/grep "^0.0.0.0" | /usr/bin/awk '{ print $8 }'`
MAC_ADD=`/sbin/ifconfig ${DFEAULT_INT} | /usr/bin/grep ether | /usr/bin/awk '{ print $2 }'`
MY_IP=`/sbin/ifconfig eno16777728 | /usr/bin/grep inet | /usr/bin/grep -v inet6 | /usr/bin/awk ' {print $2} '`
MY_NAME=`/usr/bin/grep "${MAC_ADD}" /tmp/auto_build/vmhost_autobuild.csv | /usr/bin/tail -1 | /usr/bin/cut -f 2 -d , | /usr/bin/tr '[A-Z]' '[a-z]'`
/usr/bin/hostnamectl set-hostname ${MY_NAME}
/usr/bin/echo "${MY_NAME}" > /etc/hostname
/usr/bin/echo "${MY_NAME}" > /etc/sysconfig/network
/usr/bin/mv /etc/hosts /etc/hosts.ks
/usr/bin/echo "${MY_IP} ${MY_NAME}" > /etc/hosts
/usr/bin/cat /etc/hosts.ks >> /etc/hosts
/usr/bin/rm -rf /etc/hosts.ks
