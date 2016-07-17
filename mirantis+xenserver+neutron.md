### Mirantis 8.0 with XenServer 6.5/7.0 using Neutron VLAN

Mirantis OpenStack is the most popular distribution in IaaS area and
has 100+ enterprise customers.
XenServer as the leading open source virtualization platform, has released
its offical [Fuel](https://wiki.openstack.org/wiki/Fuel) plugin based on Mirantis
OpenStack 8.0, which integrates neturon and provides neutron VLAN support first time.
You can download our plugin from 
[mirantis fuel plugin](https://www.mirantis.com/validated-solution-integrations/fuel-plugins/) page.


In this blog, I will focus on network part since neutron project is introduced in
XenServer Fuel plugin for the first time. For basic Mirantis OpenStack, Mirantis Fuel
and XenServer introduction, you can refer previous
[blog post](https://github.com/citrix-openstack/blogentries/blob/master/Introduction_To_XenServer_Fuel_Plugin.md).

#### 1. Neutron brief

Basically Neutron is an OpenStack project which provides "networking as a service" (NaaS)
with code-name Neutron. It's a standalone service alongside other services such as Nova (compute), 
Glance (image), Cinder (storage). It provides high level abstraction of network resources,
such as network, subnet, port, router, etc. And it enforces SDN, delegating its implementation
and functionalities to the plugin, which is not possible in nova-network.

The picture from OpenStack offical website describes typical deployment with Neutron.

* Controller node: Provide management functions, such as API servers and scheduling
services for Nova/Neutron/Glance/Cinder. It's the central part where most standard
OpenStack services and tools run.
* Network node: Provide network sevices, runs networking plug-in, layer 2 agent,
and several layer 3 agents. Handles external (internet) connectivity for tenant virtual machines or instances.
    * Layer 2 services include provisioning of virtual networks and tunnels. 
    * Layer 3 services include routing, NAT, and DHCP.
* Compute node: Provide computing service, it manages the hypervisors and virtual
instances.

Note: With Mirantis OpenStack, network node and controller node combined to controller node

![openstack_architecture]
(http://docs.openstack.org/security-guide/_images/1aa-network-domains-diagram.png)

#### 2. How neutron works under XenServer

Back to XenServer and Neutron, let's start by clarifying the concepts first.

##### 2.1 Logical networks

With Mirantis OpenStack, there are several networks involved.

    Public network (br-ex)
    Private network (br-prv)
    Internal network
        Management network (br-mgmt)
        Storage network (br-storage)
        PXE network (br-fw-admin)

These networks will be created automaitcally by Fuel during installation and they
all use Linux bridge by default. 

* Public network (br-ex): 

This network should be represented as tagged or untagged isolated L2 network
segment. Servers for external API access and providing VMs with connectivity
to/from networking outside the cloud. Floating IPs are implemented with L3
agent + NAT rules on Controller nodes

* Private network (br-prv):

This is for traffics from/to tenant VMS. In our case, it's VLAN (802.1q). 
OpenStack tenant can define their own L2 private network allowing IP overlap.

* Internal network:
    * PXE: Every node will boot from PXE network and it is only used for creating/booting new node
    * Management network: This is primarily targeted for openstack management, it's used
to access OpenStack services.
    * Storage network: This is used to provide storage services such as replication traffic
  from Ceph.

![mos_xs_net_topo](https://github.com/Annie-XIE/summary-os/blob/master/pic/MOS-XS-net-topo.png)

##### 2.3 Traffic flow

In this section, we will deeply go through how North-South/East-West traffic goes,
and explain the OVS rules underly.

    North-South traffic: Means traffic between instance and the external network (e.g. internet)
    East-West traffic: Means traffic between instances

* North-South traffice with instance having floating IP

In the above section, we have introduced different networks used in OpenStack cloud.

![north-south](https://github.com/Annie-XIE/summary-os/blob/master/pic/north-south-traffic-mark.png)

Let assume VM1(eth0 fixed IP: 192.168.30.4, floating IP: 10.71.17.81), VM1 ping www.google.com

In compute node:

Step-1. VM1(eth1) sent packet out through tap and qvb to br-int

Step-2. VM1's packages arrived port qvo, internal tag 16 will be added to the packages

br-int (In Dom0):

        fail_mode: secure
        Port br-int
            Interface br-int
                type: internal
        Port "qvof5602d85-2e"
            tag: 16
            Interface "qvof5602d85-2e"

Step-3. VM1's package arrived port patch-int triggering openflow rules, 
internal tag 16 was changed to physical vlan tag 1173.

        cookie=0x0, duration=12104.028s, table=0, n_packets=257, n_bytes=27404, idle_age=88, priority=4,in_port=7,dl_vlan=16 actions=mod_vlan_vid:1173,NORMAL

In network node:

Step-4. VM1's packages went through physical VLAN network to network node,
in network node's integration bridge br-int, it triggered openflow rules,
changing physical VLAN 1173 to internal tag again.

        cookie=0xbe6ba01de8808bce, duration=12594.481s, table=0, n_packets=253, n_bytes=29517, idle_age=131, priority=3,in_port=1,dl_vlan=1173 actions=mod_vlan_vid:6,NORMAL

Step-5. VM1's packages with internal tag 6 went through virtual router `qr` within qrouter namespace

br-int (DomU):

        Port "tapb977f7c3-e3"
            tag: 6
            Interface "tapb977f7c3-e3"
                type: internal
        Port "qr-4742c3a4-a5"
            tag: 6
            Interface "qr-4742c3a4-a5"
                type: internal

Step-6. VM1' packages went out via gateway `qg` within namespace

`ip netns exec qrouter-0f23c70d-5302-422a-8862-f34486b37b5d ifconfig`

    lo    Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
    qg-1270ddd4-bb Link encap:Ethernet  HWaddr fa:16:3e:5b:36:8c  
          inet addr:10.71.17.8  Bcast:10.71.17.255  Mask:255.255.254.0
          inet6 addr: fe80::f816:3eff:fe5b:368c/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:30644 errors:0 dropped:0 overruns:0 frame:0
          TX packets:127 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:2016118 (2.0 MB)  TX bytes:8982 (8.9 KB)

Step-7. VM1's package finally went out through br-ex, see the physical route

        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        0.0.0.0         10.71.16.1      0.0.0.0         UG    0      0        0 br-ex
        10.20.0.0       0.0.0.0         255.255.255.0   U     0      0        0 br-fw-admin
        10.71.16.0      0.0.0.0         255.255.254.0   U     0      0        0 br-ex
        192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 br-mgmt
        192.168.1.0     0.0.0.0         255.255.255.0   U     0      0        0 br-storage

* East-West traffic with instances having floating IP





#### 3. XenServer fuel plugin

#### 4. Future

Looking forward, we will enrich more neutron features on XenServer, such as VxLAN, VPNaaS, 
SDN, ....
