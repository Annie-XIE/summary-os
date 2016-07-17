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
and XenServer introduction, you can refer previous blog post
[Introduction to XenServer Fuel Plugin](https://github.com/citrix-openstack/blogentries/blob/master/Introduction_To_XenServer_Fuel_Plugin.md).

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

    North-South traffic
    East-West traffic
    OVS rules

* North-South traffic: Means traffic between VMs and the outside (e.g. internet)
* East-West traffic: Means traffic between different VMs






#### 3. XenServer fuel plugin

#### 4. Future

Looking forward, we will enrich more neutron features on XenServer, such as VxLAN, VPNaaS, 
SDN, ....
