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

See the picture of openstack components deployment

![openstack_architecture]
(https://github.com/Annie-XIE/summary-os/blob/master/deployment-neutron-1.png)

#### 2. How neutron works under XenServer

Back to XenServer, as we know XenServer is type-1 hypervisor with the concept of
Dom0 (privileged domain) and DomU (unprivileged domain)
Neutron provides several virtual network topologies compared with nova network, so let's
start from a cross tenant VM connectivy.

##### 2.1 Logical networks

There are several networks involved with Neutron OpenStack environment.

    Public network
    Private network
    Internal network
        Management network
        Storage network
        PXE network

Internal network is a general term for all networks in your OpenStack environment except for Public and Private network. Internal networks include Storage, Management, and Admin (PXE) Fuel networks.

##### 2.2 Traffic flow

    OVS rules
    East-West traffic
    North-South traffic

Draw traffic flow graphs to explain the traffic and OVS rules, iptables, ...

#### 3. XenServer fuel plugin

#### 4. Future

Looking forward, we will enrich more neutron features on XenServer, such as VxLAN, VPNaaS, 
SDN, ....
