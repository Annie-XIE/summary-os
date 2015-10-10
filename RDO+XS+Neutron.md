### Manual of XenServer+RDO+Neutron

This manual gives brief instruction on installing OpenStack with 
Neutron using RDO under RHEL7/CentOS7.

		Environment:
			XenServer 6.5
			CentOS 7.0
			OpenStack kilo
			Neutron ML2 plugin/OVS/VLAN

##### 1. Install XenServer 6.5
1.1. Make sure the default SR is EXT3 (in the installer this is called 
XenDesktop optimised storage)

1.2 Create network for OpenStack. After installing XenServer. In our single
box environment, we need to create three networks, *Private network*, 
*Public network*, *VM network*.

		xe network-create name-label=os-int-net
		xe network-create name-label=os-ex-net
		xe network-create name-label=os-vm-net

##### 2. Install Guest VM
This Guest VM is used as platform for installing OpenStack software.

2.1. One VM per hypervisor using XenServer 6.5 and RHEL7/CentOS7 templates, 
also ensure that they are HVM guests.

2.2. Create interface card for Guest VM

		xe vif-create device=1 network-uuid=2147d400-89e2-4df9-e055-c772f0548f51 vm-uuid=63b519dd-e23b-3924-23a0-cc3549370b82
		xe vif-create device=2 network-uuid=ecf39f2b-e467-17a7-b411-14c708745aad vm-uuid=63b519dd-e23b-3924-23a0-cc3549370b82

*Note: vm-uuid is the id of guest vm, network-uuid is the id of os-vm-network and 
os-ex-network, device id shoudl be set according to your environment*

##### 3. Install RDO
3.1 [RDO Quickstart](https://www.rdoproject.org/Quickstart) gives detailed 
installation guide. 

3.2 Run `Step 0: Prerequisites` to prepare the environment

3.3 Run `Step 1: Software repositories`. Please remove the postfix *.orig* 
of *CentOS-XXX.repo.orig* in folder */etc/yum.repos.d* and then try `yum update -y`.

*Note: You may meet some errors while executing yum update, you can just ignore these 
errors and reboot the VM after yum update.*

3.4 Run `Step 2: Install Packstack Installer` to install packstack. Packstack
is the real one that installs OpenStack service.

*Note: You may also meet errors of package version, you can try to install required 
packages manually*

3.5 Generate answer file `packstack --gen-answer-file=<ANSWER_FILE>`.

3.6 Change *ANSWER_FILE* to set neutron related configurations.
You should set these configuration items according to your environment.

    CONFIG_DEFAULT_PASSWORD=<your-password>
    CONFIG_DEBUG_MODE=y
    CONFIG_NEUTRON_INSTALL=y
    CONFIG_NEUTRON_L3_EXT_BRIDGE=br-ex
    CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vlan
    CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vlan
    CONFIG_NEUTRON_ML2_MECHANISM_DRIVERS=openvswitch
    CONFIG_NEUTRON_ML2_VLAN_RANGES=physnet1:1000:1050
    CONFIG_NEUTRON_L2_AGENT=openvswitch
    CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-eth1
    CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-eth1:eth1

3.7 Run `Step 3: Run Packstack to install OpenStack`. You should use 
`packstack --answer-file=<ANSWER_FILE>` instead.

*Note: After the above steps, OpenStack is installed and its services should 
begin running at the monent. But we should do some adpation work with XenServer*

##### 4. Configure Compute VM / Hypervisor communications
4.1 Ensure XenServer network os-int-net has an interface attached to the compute VMs

4.2 Use HIMN tool (plugin for XenCenter) to add internal management network to
Compute VMs. This effectively performs the following operations, which could
also be performed manually in dom0 for each compute node:

    net=$(xe network-list bridge=xenapi --minimal)
    vm=$(xe vm-list name-label=<vm-name> --minimal)
    vif=$(xe vif-create vm-uuid=$vm network-uuid=$net device=9)
    mac=$(xe vif-param-get uuid=$vif param-name=MAC)
    xe vm-param-set uuid=$vm xenstore-data:vm-data/himn_mac=$mac

**TODO:check this: 4.3 Install the XenServer PV tools in the guest VM**

**TODO:check this: 4.4 Set up DHCP on the HIMN network for the gues VM, allowing each 
compute VM to access it’s own hypervisor on the static address 169.254.0.1**

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

##### 5. Configure Nova
5.1 Modify /etc/nova/nova.conf to switch to using XenServer, check below configuration items

    [DEFAULT]
    compute_driver=xenapi.XenAPIDriver
    firewall_driver=nova.virt.firewall.NoopFirewallDriver
    [xenserver]
    connection_url=https://169.254.0.1
    connection_username=root
    connection_password=<password>
    vif_driver=nova.virt.xenapi.vif.XenAPIOpenVswitchDriver
    ovs_int_bridge=xapi7 # Bridge for ovs-xen-int

5.2 Install XenAPI Python XML RPC lightweight bindings

    yum install -y python-pip
    pip install xenapi
    
    or
    
    curl https://raw.githubusercontent.com/xapi-project/xen-api/master/scripts/examples/python/XenAPI.py -o /usr/lib/python2.7/site-packages/XenAPI.py

##### 6. Configure Neutron
6.1 Add confguration itmes in */etc/neutron/rootwrap.conf* to support
using XenServer remotely.

    [xenapi]
    # XenAPI configuration is only required by the L2 agent if it is to
    # target a XenServer/XCP compute host's dom0.
    xenapi_connection_url=http://169.254.0.1
    xenapi_connection_username=root
    xenapi_connection_password=<password>

6.2 Check configurations in */etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini* 

    [ovs]
    integration_bridge = br-int
    bridge_mappings = physnet1:br-eth1

6.3 Restart neutron service

	`service neutron-openvswitch-agent restart`

##### 7. Launch another neutron-openvswitch-agent for talking with Dom0
7.1 Create another configuration file

    cp /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini.dom0
    
    [ovs]
    integration_bridge = xapi3
    bridge_mappings = physnet1:xapi2
    
    [agent]
    root_helper = neutron-rootwrap-xen-dom0 /etc/neutron/rootwrap.conf
    root_helper_daemon =
    minimize_polling = False
    
    [securitygroup]
    firewall_driver = neutron.agent.firewall.NoopFirewallDriver

7.2 Launch neutron-openvswitch-agent

    /usr/bin/python2 /usr/bin/neutron-openvswitch-agent --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini.dom0 --config-dir /etc/neutron/conf.d/neutron-openvswitch-agent --log-file /var/log/neutron/openvswitch-agent.log.dom0 &
    
*Note: For all-in-one installation, typically there is only one neutron-openvswitch-agent.
However, XenServer has seperation of Dom0 and DomU and all instances' VIFs are actually 
managed by Dom0 and the corresponding OVS port is created in Dom0. Thus, we should manually
start the other ovs agent to let it talk to Dom0*

##### 8. Restart Nova Services
    for svc in api cert conductor compute scheduler; do \
	    service openstack-nova-$svc restart; \
    done

##### 9. Replace cirros guest with one set up to work for XenServer
    nova image-delete cirros
    wget http://ca.downloads.xensource.com/OpenStack/cirros-0.3.4-x86_64-disk.vhd.tgz
    glance image-create --name cirros --container-format ovf --disk-format vhd --property vm_mode=xen --is-public True --file cirros-0.3.4-x86_64-disk.vhd.tgz


