#!/bin/bash
# Start off preparing the network and hostname config
mkdir -p /tmp/auto_build/
cd /tmp/auto_build/
wget http://192.168.2.1/pub/auto_build/vmhost_autobuild.csv > /dev/null
MAC_ADD=`ifconfig | grep ether | awk '{ print $2 }'`
MY_IP=`ifconfig | grep inet | egrep -v 'inet6|127.0.0.1' | awk ' {print $2} '`
MY_NAME=`grep "${MAC_ADD}" /tmp/auto_build/vmhost_autobuild.csv | tail -1 | cut -f 2 -d , | tr '[A-Z]' '[a-z]'`
echo "MAC:  $MAC_ADD"
echo "IP:   $MY_IP"
echo "NAME: $MY_NAME"
hostnamectl set-hostname ${MY_NAME}
echo "${MY_NAME}" > /etc/hostname
mv /etc/hosts /etc/hosts.ks
echo "${MY_IP} ${MY_NAME}" > /etc/hosts
cat /etc/hosts.ks >> /etc/hosts
rm -rf /etc/hosts.ks

# Add the ssh key for the main admin host
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDc5Hi/i6A9vZxeCpLLEGd+xIowMYWLvJymstKb4lGM3fX+iMmBQm8IJ+rix75s6U9T5pDRtQEaku0M6nnwTNQh+uVGYXPNuR1ce0PKssxHvtLVpeq2Uhs6PkdmhC4b6b67SzeanpwM7MhTs5bCFh0g3WoVdrr7fcm/N20C28EnsPJfoBZksciG5xztdguQulz8UR/v16S6giS2+e9Dd8q0kLodO395JqroCczo5EYcGWz8CCwIH/Zlqz1h+Vs/OfSpKXOQqZucIfsuxguG6dOBwPRX6lE5H/z9fu1VjVrn7gX/72Zx26hqIG5aJpUdUWZoY01eLbIU40YfkzO/0yab root@bp-v-lnx1" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Set up the chef client which will take over the rest of the host config
wget http://192.168.2.1/pub/auto_build/chef-12.4.1-1.el7.x86_64.rpm
rpm -Uvh chef-12.4.1-1.el7.x86_64.rpm
wget http://192.168.2.1/pub/auto_build/chef-client-config.tar
tar -C / -xvf chef-client-config.tar
rm -rf /etc/chef/client.pem
echo "PATH=/usr/local/bin:/usr/bin:/bin" > /etc/cron.d/chef-client
echo "*/10 * * * * root sleep $(expr $RANDOM \% 300);chef-client -l error -L /var/log/chef-client" >> /etc/cron.d/chef-client
chef-client
