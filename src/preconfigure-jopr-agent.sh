#!/bin/sh

JOPR_HOME=/opt/jopr
JOPR_VERSION=2.2.1
JOPR_AGENT_NAME=rhq-enterprise-agent
JOPR_AGENT_VERSION=1.2.1
JOPR_CONFIG=/usr/share/jopr/agent-configuration.xml
JOPR_TMP_DIR=/tmp/jopr-2.2.1

IP_ADDRESS=`ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1`

rm -rf $JOPR_TMP_DIR
mkdir -p $JOPR_TMP_DIR

cd $JOPR_TMP_DIR
jar xvf $JOPR_HOME/jbossas/server/default/deploy/rhq.ear.rej/rhq-downloads/rhq-agent/$JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.jar $JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.zip
unzip -q $JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.zip -d $JOPR_TMP_DIR

## ADD HERE CHANGES TO agent-configuration.xml
sed s/#BIND_ADDRESS#/$IP_ADDRESS/g $JOPR_CONFIG > rhq-agent/conf/agent-configuration.xml 

jar uvf $JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.zip rhq-agent/conf/agent-configuration.xml
jar uvf $JOPR_HOME/jbossas/server/default/deploy/rhq.ear.rej/rhq-downloads/rhq-agent/$JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.jar $JOPR_AGENT_NAME-$JOPR_AGENT_VERSION.zip

