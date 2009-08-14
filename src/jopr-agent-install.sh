#!/bin/sh

JOPR_AGENT_HOME=/opt/jopr-agent
JOPR_AGENT_NAME=rhq-enterprise-agent
JOPR_AGENT_VERSION=1.2.1
JOPR_TMP_DIR=/tmp/jopr-2.2.1

[ -f /etc/sysconfig/jopr-agent ] && . /etc/sysconfig/jopr-agent

[ "x$JOPR_SERVER_IP" = "x" ] && exit 0

JOPR_AGENT_JAR_LOCATION=http://$JOPR_SERVER_IP:7080/agentupdate/download

rm -rf $JOPR_TMP_DIR
mkdir -p $JOPR_TMP_DIR
mkdir -p $JOPR_AGENT_HOME

sleep=0
downloaded=0
while [ $downloaded -eq 1 ]; do
    sleep 5
    sleep=`expr $sleep + 5`

    http_code=`curl -o /dev/null -s -m 5 -w '%{http_code}' $JOPR_AGENT_JAR_LOCATION`

    if [ $http_code -eq "200" ]
    then
        wget $JOPR_AGENT_JAR_LOCATION -O $JOPR_AGENT_HOME/$JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.jar
        downloaded=1        
    fi
done

cd $JOPR_AGENT_HOME

java -jar $JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.jar --install




