#!/bin/sh

INT_NET=openstack-int-network
EXT_NET=openstack-ext-network
VM_NET=openstack-vm-network

function create_network()
{
    xe network-create name-label=$INT_NET;
    xe network-create name-label=$EXT_NET;
    xe network-create name-label=$VM_NET;
}

# input param: vm_uuid
function create_vif {
    local vm_uuid=$1
    local allowed_vif_list=$(xe vm-param-get uuid=$vm_uuid param-name=allowed-VIF-devices | sed 's/;/ /g')
    local vif_dev_int_net=$(echo $allowed_vif_list | awk '{print $1}')
    local vif_dev_ext_net=$(echo $allowed_vif_list | awk '{print $2}')

    local int_net_uuid=$(xe network-list name-label=$INT_NET --minimal)
    local ext_net_uuid=$(xe network-list name-label=$EXT_NET --minimal)

    local vif_int_net=$(xe vif-create device=$vif_dev_int_net network-uuid=$int_net_uuid vm_uuid=$vm_uuid)
    xe vif-plug uuid=$vif_int_net
    local vif_ext_net=$(xe vif-create device=$vif_dev_ext_net network-uuid=$ext_net_uuid vm_uuid=$vm_uuid)
    xe vif-plug uuid=$vif_ext_net
}

# input param: vm_uuid
function create_himn {
    local vm_uuid=$1
    local net=$(xe network-list bridge=xenapi --minimal)
    local vif=$(xe vif-create vm-uuid=$vm_uuid network-uuid=$net device=9)
    local mac=$(xe vif-param-get uuid=$vif param-name=MAC)
    xe vm-param-set uuid=$vm_uuid xenstore-data:vm-data/himn_mac=$mac
    xe vif-plug uuid=$vif
}

# run this function in domU
function active_himn_interface {

	local domid=$(xenstore-read domid)
	local mac=$(xenstore-read /local/domain/$domid/vm-data/himn_mac)
    local dev_path=$(grep -l $mac /sys/class/net/*/address)
    local dev=$(basename $(dirname $dev_path))
    local ifcfg_file=/etc/sysconfig/network-scripts/ifcfg-$dev

    touch $ifcfg_file
    echo "DEVICE=$dev" >> $ifcfg_file
    echo "BOOTPROTO=dhcp" >> $ifcfg_file
    echo "ONBOOT=yes" >> $ifcfg_file
    echo "TYPE=Ethernet" >> $ifcfg_file

    ifup $dev
}

# input param: dom0_ip
function install_dom0_plugins {
    local dom0_ip=$1

    ################## nova #################
    mkdir -p /tmp/nova_plugins
    local tag=$(rpm -q openstack-nova-compute --queryformat '%{Version}')
    local base=https://git.openstack.org/cgit/openstack/nova/plain
    local path=plugins/xenserver/xenapi/etc/xapi.d/plugins

    local files=$(curl -s -S $base/$path?id=$tag | grep li | grep $path | sed -e 's#.*xapi.d/plugins/##' -e 's#\?id=.*##')
    for f in $files; do
        curl -s -S $base/$path/$f?id=$tag -o /tmp/nova_plugins/$f
    done
    chmod +x /tmp/nova_plugins/*
    scp -p /tmp/nova_plugins/* root@$dom0_ip:/etc/xapi.d/plugins/

    ################## neutron ##############
    mkdir -p /tmp/neutron_plugins
    cp /usr/lib/python2.7/site-packages/neutron/plugins/openvswitch/agent/xenapi/etc/xapi.d/plugins/* /tmp/neutron_plugins
    chmod +x /tmp/neutron_plugins/*
    sed -i "/ALLOWED_CMDS = /a    'ipset', 'iptables-save', 'iptables-restore', 'ip6tables-save', 'ip6tables-restore'," /tmp/neutron_plugins/netwrap
    scp -p /tmp/neutron_plugins/* root@$dom0_ip:/etc/xapi.d/plugins/
}