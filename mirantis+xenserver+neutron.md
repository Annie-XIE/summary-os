## Mirantis 8.0 with XenServer 6.5/7.0 using Neutron VLAN

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

### 1. Neutron brief

Basically Neutron is an OpenStack project which provides "networking as a service" (NaaS)
with code-name Neutron. It's a standalone service alongside other services such as Nova (compute), 
Glance (image), Cinder (storage). It provides high level abstraction of network resources,
such as network, subnet, port, router, etc. Further it enforces SDN, delegating its implementation
and functionalities to the plugin, which is not possible in nova-network.

The picture from OpenStack offical website describes typical deployment with Neutron.

* Controller node: Provide management functions, such as API servers and scheduling
services for Nova, Neutron, Glance and Cinder. It's the central part where most standard
OpenStack services and tools run.
* Network node: Provide network sevices, runs networking plug-in, layer 2 agent,
and several layer 3 agents. Handles external connectivity for virtual machines.
    * Layer 2 services include provisioning of virtual networks and tunnels. 
    * Layer 3 services include routing, NAT, and DHCP.
* Compute node: Provide computing service, it manages the hypervisors and virtual machines.

Note: With Mirantis OpenStack, network node and controller node combined to controller node

![openstack_architecture]
(http://docs.openstack.org/security-guide/_images/1aa-network-domains-diagram.png)

### 2. How neutron works under XenServer

Back to XenServer and Neutron, let's start from those networks.

#### 2.1 Logical networks

With Mirantis OpenStack, there are several networks involved.

    OpenStack Public network (br-ex)
    OpenStack Private network (br-prv)
    Internal network
        OpenStack Management network (br-mgmt)
        OpenStack Storage network (br-storage)
        Fuel Admin(PXE) network (br-fw-admin)

* OpenStack Public network (br-ex): 

This network should be represented as tagged or untagged isolated L2 network
segment. Servers for external API access and providing VMs with connectivity
to/from networking outside the cloud. Floating IPs are implemented with L3
agent + NAT rules on Controller nodes

* Private network (br-prv):

This is for traffics from/to tenant VMS. Under XenServer, we use OpenvSwitch VLAN (802.1q). 
OpenStack tenant can define their own L2 private network allowing IP overlap.

* Internal network:
    * OpenStack Management network: This is targeted for openstack management, it's used
to access OpenStack services, can be tagged or untagged vlan network.
    * Storage network: This is used to provide storage services such as replication traffic
  from Ceph, can tagged or untagged vlan network.
    * Fuel Admin(PXE) network: This is used fro creating and booting new nodes.
All controller and compute nodes will boot from this PXE network and will get
its IP address via Fuel's internal dhcp server.

![mos_xs_net_topo](https://github.com/Annie-XIE/summary-os/blob/master/pic/MOS-XS-net-topo.png)

#### 2.2 Traffic flow

In this section, we will deeply go through on North-South/East-West traffic, explain the OVS rules underly.

* North-South traffic: traffic between VMs and the external network (e.g. internet)

* East-West traffic: traffic between VMs

##### 2.2.1 North-South traffice

In the above section, we have introduced different networks used in OpenStack cloud.
Let's assume VM1 with fixed IP: 192.168.30.4, floating IP: 10.71.17.81,
when VM1 ping www.google.com, how the traffic goes.

![north-south](https://github.com/Annie-XIE/summary-os/blob/master/pic/north-south-traffic-mark.png)

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

`ip netns exec qrouter-0f23c70d-5302-422a-8862-f34486b37b5d route`

        Kernel IP routing table
        Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
        default         10.71.16.1      0.0.0.0         UG    0      0        0 qg-1270ddd4-bb
        10.10.0.0       *               255.255.255.0   U     0      0        0 qr-b747d7a6-ed
        10.71.16.0      *               255.255.254.0   U     0      0        0 qg-1270ddd4-bb
        192.168.30.0    *               255.255.255.0   U     0      0        0 qr-4742c3a4-a5

Step-6. VM1' packages be SNAT and then went out via gateway `qg` within namespace

       -A neutron-l3-agent-PREROUTING -d 10.71.17.81/32 -j DNAT --to-destination 192.168.30.4
       -A neutron-l3-agent-float-snat -s 192.168.30.4/32 -j SNAT --to-source 10.71.17.81

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

        0.0.0.0         10.71.16.1      0.0.0.0         UG    0      0        0 br-ex
        10.20.0.0       0.0.0.0         255.255.255.0   U     0      0        0 br-fw-admin
        10.71.16.0      0.0.0.0         255.255.254.0   U     0      0        0 br-ex
        192.168.0.0     0.0.0.0         255.255.255.0   U     0      0        0 br-mgmt
        192.168.1.0     0.0.0.0         255.255.255.0   U     0      0        0 br-storage

For package back from external network to VM, vice versa.

##### 2..2 East-West traffic with instances

When talking about East-West traffic, the packages route will quite different
depending on where the VMs residing and whether the VMs belonging to the same tenant.

![east-west](https://github.com/Annie-XIE/summary-os/blob/master/pic/East-West-traffic-mark.png)

With the above graph, 

(1) VM1 and VM2 locate in the same host

If they connect to same network, traffic between them won't go out, just VM1 -> br-int(compute-node1) -> VM2

If they connect to different network, traffic between them will go out, VM1 -> network-node -> VM2

(3) VM1 and VM3 locate in different host, traffic between them must go through network node

### 3. Future

Looking forward, we will implement VxLAN and GRE network, also enrich more neutron features,
such as VPNaaS, LBaaS, FWaaS, SDN ...
