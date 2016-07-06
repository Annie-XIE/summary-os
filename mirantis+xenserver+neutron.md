### Mirantis 8.0 with XenServer 6.5/7.0 using Neutron VLAN

Mirantis OpenStack is the most popular distribution in IaaS area and
has 100+ enterprise customers.
XenServer as the leading open source virtualization platform, has released
its offical [Fuel](https://wiki.openstack.org/wiki/Fuel) plugin based on Mirantis
OpenStack 8.0, which provides neutron VLAN support. 

This plugins is the first release including neutron project on XenServer.
You can download from [mirantis fuel plugin page](https://www.mirantis.com/validated-solution-integrations/fuel-plugins/),
in section *Citrix XenServer Fuel Plugin*, select *MOS 8.0*.

In this blog, I will focus on network part since neutron is introduced first time in
our XenServer Fuel plugin. For basic Mirantis and XenServer introduction,
you can refer to our previous blog post
[Introduction to XenServer Fuel Plugin](https://github.com/citrix-openstack/blogentries/blob/master/Introduction_To_XenServer_Fuel_Plugin.md).

#### 1. Neutron brief

Basically Neutron is an OpenStack project to provide "networking as a service" (NaaS)
with code-name Neutron. It's a standalone service alongside other services such as Nova (Compute), 
Glance (Image), Cinder (Storage). It provides high level abstraction of network resources,
such as Network, Subnet, Port, Router, etc. Also Neutron enforces SDN, delegating its implementation
and functionalities to the plugin.

The picture from OpenStack offical website describes typical deployment with Neutron

![openstack_architecture]
(http://docs.openstack.org/security-guide/_images/1aa-network-domains-diagram.png)

* Management network

Used for internal communication between OpenStack Components. The IP addresses on this network
should be reachable only within the data center and is considered the Management Security Domain.

* Guest network

Used for VM data communication within the cloud deployment. The IP addressing requirements of this
network depend on the OpenStack Networking plug-in in use and the network configuration choices of
the virtual networks made by the tenant. This network is considered the Guest Security Domain.

* External network

Used to provide VMs with Internet access in some deployment scenarios. The IP addresses on this
network should be reachable by anyone on the Internet. This network is considered to be in the
Public Security Domain.

* API network

Exposes all OpenStack APIs, including the OpenStack Networking API, to tenants. The IP addresses
on this network should be reachable by anyone on the Internet. This may be the same network as the
external network, as it is possible to create a subnet for the external network that uses IP
allocation ranges to use only less than the full range of IP addresses in an IP block. This network
is considered the Public Security Domain.

#### 2. How neutron works under XenServer

Back to networking, in Neutron's world, there are several concepts we need to clarify first.

##### 2.1 Logical networks

Mirantis There are several networks involved with Neutron OpenStack environment.

    Public network
    Private network
    Internal network
        Management network
        Storage network
        PXE network

Public network: 

Internal network is a general term for all networks in your OpenStack environment except for Public and Private network. Internal networks include Storage, Management, and Admin (PXE) Fuel networks.

![mos_xs_net_topo](https://github.com/Annie-XIE/summary-os/blob/master/pic/MOS-XS-net-topo.png)


##### 2.2 Traffic flow

    OVS rules
    East-West traffic
    North-South traffic

In this section, we will go through deep on how East-West/North-South traffic goes




#### 3. XenServer fuel plugin

#### 4. Future

Looking forward, we will enrich more neutron features on XenServer, such as VxLAN, VPNaaS, 
SDN, ....
