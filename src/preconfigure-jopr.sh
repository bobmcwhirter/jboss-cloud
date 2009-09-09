#!/bin/sh

[ -f /etc/sysconfig/jboss-cloud ]   && . /etc/sysconfig/jboss-cloud
[ -f /etc/sysconfig/jopr ]          && . /etc/sysconfig/jopr

DATABASE_NAME=jopr
DATABASE_USER=jopr
DATABASE_NAME=jopr
DATABASE_PASSWORD=`head -c10 /dev/urandom | md5sum | head -c30`

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

USER_CREATED=`/bin/su postgres -c "/bin/echo '\du' | /usr/bin/psql -tA" &>/dev/null | awk -F\| '{ print $1 }' | grep $DATABASE_USER | wc -l`
DATABASE_CREATED=`/bin/su postgres -c "/usr/bin/psql -tAl" &>/dev/null | awk -F\| '{ print $1 }' | grep $DATABASE_NAME | wc -l`

if [ $USER_CREATED -eq "0" ]
then
        /bin/su postgres -c "/usr/bin/createuser -SDR $DATABASE_USER &>/dev/null"
        echo "ALTER USER $DATABASE_USER WITH PASSWORD '$DATABASE_PASSWORD'" | /bin/su postgres -c /usr/bin/psql &>/dev/null
fi

if [ $DATABASE_CREATED -eq "0" ]
then
        /bin/su postgres -c "/usr/bin/createdb -O $DATABASE_USER $DATABASE_NAME &>/dev/null"
fi

sed s/#LOCAL_IP#/$LOCAL_IP/g /usr/share/jopr/rhq-server.properties | sed s/#PUBLIC_IP#/$PUBLIC_IP/g | sed s/#DATABASE_USER#/$DATABASE_USER/g | sed s/#DATABASE_PASSWORD#/$DATABASE_PASSWORD/g | sed s/#DATABASE_NAME#/$DATABASE_NAME/g > $JOPR_HOME/bin/rhq-server.properties

chown jopr:jopr /opt/jopr/ -R
