### Manual of XenServer+RDO+Neutron

This manual gives you the instructions on installing OpenStack with 
Neutron using RDO under RHEL7/CentOS7.

##### 1. Install XenServer 6.5
1.1. Ensure that the default SR is EXT3 (in the installer this is called 
XenDesktop optimised storage)

##### 2. Install Guest VM
2.1.	One VM per hypervisor using XenServer 6.5 and the RHEL7/CentOS7 
templates, which will ensure that they are HVM guests.

##### 3. Install RDO
3.1 [RDO Quickstart](https://www.rdoproject.org/Quickstart) gives detailed 
installation guide. 

3.2 Run `Step 1: Software repositories` and then remove 
the postfix of *xxx.repo.orig* in */etc/yum.repos.d* which is CentOS 
repositories that are modified by RDO during installation.

3.3 Run `Step 2: Install Packstack Installer` to install packstack. Packstack
is the real one that installs OpenStack service.

3.4 Generate answer file `packstack --gen-answer-file=<ANSWER_FILE>`.

3.5 Change *ANSWER_FILE* to set neutron related configurations.
You should set these configuration items according to your environment.

    CONFIG_NEUTRON_INSTALL=y
    CONFIG_NEUTRON_L3_EXT_BRIDGE=br-ex
    CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vlan
    CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vlan
    CONFIG_NEUTRON_ML2_MECHANISM_DRIVERS=openvswitch
    CONFIG_NEUTRON_ML2_VLAN_RANGES=physnet1:1000:1050
    CONFIG_NEUTRON_L2_AGENT=openvswitch
    CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-eth1
    CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-eth1:eth1

3.6 Run `Step 3: Run Packstack to install OpenStack`. You should use 
`packstack --answer-file=<ANSWER_FILE>` instead.

*Note: After the above steps, OpenStack is installed and its services should 
begin running at the monent. But we should do some adpation work with XenServer*

##### 4. Configure Compute VM / Hypervisor communications

    net=$(xe network-list bridge=xenapi --minimal)
    vm=$(xe vm-list name-label=<vm-name> --minimal)
    xe vif-create vm-uuid=$vm network-uuid=$net device=9

4.1 Ensure XenServer network ovs-xen-int has an interface attached to the compute VMs

4.2 Use HIMN tool (plugin for XenCenter) to add internal management network to
Compute VMs. This effectively performs the following operations, which could
also be performed manually in dom0 for each compute node:

    net=$(xe network-list bridge=xenapi --minimal)
    vm=$(xe vm-list name-label=<vm-name> --minimal)
    vif=$(xe vif-create vm-uuid=$vm network-uuid=$net device=9)
    mac=$(xe vif-param-get uuid=$vif param-name=MAC)
    xe vm-param-set uuid=$vm xenstore-data:vm-data/himn_mac=$mac

4.3 Install the XenServer PV tools in the Compute guest

4.4 Set up DHCP on the HIMN network for the compute VMs, allowing each 
compute VM to access it’s own hypervisor on the static address 169.254.0.1

    domid=$(xenstore-read domid)
    mac=$(xenstore-read /local/domain/$domid/vm-data/himn_mac)
    dev_path=$(grep -l $mac /sys/class/net/*/address)
    dev=$(basename $(dirname $dev_path))
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$dev
    DEVICE="$dev"
    BOOTPROTO="dhcp"
    ONBOOT="yes"
    TYPE="Ethernet"
    EOF
    ifup $dev

4.5 Copy plugins to the XenServer host.

Download direct from git.openstack.org since they are not packaged

    mkdir -p /tmp/nova_plugins
    tag=$(rpm -q openstack-nova-compute --queryformat '%{Version}')
    base=https://git.openstack.org/cgit/openstack/nova/plain
    path=plugins/xenserver/xenapi/etc/xapi.d/plugins

    files=$(curl -s -S $base/$path?id=$tag | grep li | grep $path | sed -e 's#.*xapi.d/plugins/##' -e 's#\?id=.*##')
    for f in $files; do
      curl -s -S $base/$path/$f?id=$tag -o /tmp/nova_plugins/$f
    done
    chmod +x /tmp/nova_plugins/*	
    scp -p /tmp/nova_plugins/* root@169.254.0.1:/etc/xapi.d/plugins/
    

4.6 Copy Neutron plugin to the XenServer host and enable additional commands

    mkdir -p /tmp/neutron_plugins
    cp /usr/lib/python2.7/site-packages/neutron/plugins/openvswitch/agent/xenapi/etc/xapi.d/plugins/* /tmp/neutron_plugins
    chmod +x /tmp/neutron_plugins/*
    sed -i "/ALLOWED_CMDS = /a    'ipset', 'iptables-save', 'iptables-restore', 'ip6tables-save', 'ip6tables-restore'," /tmp/neutron_plugins/netwrap
    scp -p /tmp/neutron_plugins/* root@169.254.0.1:/etc/xapi.d/plugins/

4.7 Change netwrap to check exit code 0 not stderr 
(to allow iptables-restore to include deprecated ‘state’ matches)

