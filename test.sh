#!/bin/bash

set +xu

DOMZERO_USER=domzero
dom0_ip=$1
ssh_dom0="sudo -u $DOMZERO_USER ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$dom0_ip"

#XS_HOST=`$ssh_dom0 "xe host-list --minimal"`
#XS_VER=`$ssh_dom0 "xe host-param-get uuid=$XS_HOST param-name=software-version param-key=product_version_text_short"`

# check whether conntrack-tools package is installed
CONNTRACK_INSTALLED=`$ssh_dom0 "yum list conntrack-tools | grep 'Installed Packages'"`
if [ -z "$CONNTRACK_INSTALLED" ]; then
    REPO_VER=`$ssh_dom0 "yum version nogroups |grep Installed"`
    CENTOS_VER=$(echo $REPO_VER | awk -F " " '{print $2}' | awk -F ".el" '{print $1}' | awk -F "-" '{print $1 "." $2}')
	CENTOS_BASEREPO="/etc/yum.repos.d/CentOS-Base.repo"
	BASEREPO_ENABLED=`$ssh_dom0 "grep enabled=1 $CENTOS_BASEREPO"`
	
	if [ -z "$BASEREPO_ENABLED" ]; then
        $ssh_dom0 "sed -i s/mirrorlist=/#mirrorlist=/g $CENTOS_BASEREPO"
        $ssh_dom0 "sed -i s/#baseurl=/baseurl=/g $CENTOS_BASEREPO"
        $ssh_dom0 "sed -i s/enabled=0/enabled=1/g $CENTOS_BASEREPO"
        $ssh_dom0 "sed -i s/\\\$releasever/$CENTOS_VER/g $CENTOS_BASEREPO"
    fi
	
	$ssh_dom0 "yum install -y conntrack-tools"
fi

# check whether conntrackd service is started
CONNTRACK_STARTED=`$ssh_dom0 "service conntrackd status |grep 'not-found'"`
if [ -e "$CONNTRACK_STARTED" ]; then
	$ssh_dom0 "service conntrackd start"
fi
