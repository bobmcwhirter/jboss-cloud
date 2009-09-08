#!/bin/sh

[ -f /etc/sysconfig/jboss-cloud ]   && . /etc/sysconfig/jboss-cloud
[ -f /etc/sysconfig/jopr ]          && . /etc/sysconfig/jopr

IP_ADDRESS=`ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1`

status_code=`curl -o /dev/null -s -m 5 -w '%{http_code}' http://169.254.169.254/latest/meta-data/local-ipv4`

if [ $status_code -eq "200" ]
then
    LOCAL_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
    PUBLIC_IP=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
else
    LOCAL_IP=$IP_ADDRESS
    # this is intentional
    PUBLIC_IP=$IP_ADDRESS
fi

sed s/#LOCAL_IP#/$LOCAL_IP/g /usr/share/jopr/rhq-server.properties | sed s/#PUBLIC_IP#/$PUBLIC_IP/g > $JOPR_HOME/bin/rhq-server.properties

chown jopr:jopr /opt/jopr/ -R
