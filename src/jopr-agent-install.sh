#!/bin/sh

[ -f /etc/sysconfig/jboss-cloud ] && . /etc/sysconfig/jboss-cloud

JOPR_AGENT_HOME=/opt/jopr-agent

[ -f /etc/sysconfig/jopr-agent ] && . /etc/sysconfig/jopr-agent

[ "x$JOPR_SERVER_IP" = "x" ] && exit 0

JOPR_AGENT_JAR_LOCATION=http://$JOPR_SERVER_IP:7080/agentupdate/download

rm -rf $JOPR_AGENT_HOME
mkdir -p $JOPR_AGENT_HOME

sleep=0
downloaded=0
while [ "$downloaded" = "0" ]; do
    sleep 5
    sleep=`expr $sleep + 5`

    http_code=`curl -o /dev/null -s -m 5 -w '%{http_code}' $JOPR_AGENT_JAR_LOCATION`

    if [ $http_code -eq "200" ]
    then
        wget $JOPR_AGENT_JAR_LOCATION -O $JOPR_AGENT_HOME/jopr-agent.jar
        downloaded=1        
    fi
done

cd $JOPR_AGENT_HOME

java -jar jopr-agent.jar --install

sed -i s/#AGENT_NAME#/$APPLIANCE_NAME-$HOSTNAME/g $JOPR_AGENT_HOME/rhq-agent/conf/agent-configuration.xml
