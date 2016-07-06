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

The picture from OpenStack offical website describes typical deployment with Neutron.

    Controller node: Central part, 
    Network node: Provide netwok sevice
    Compute node: Provide computing service, scalale, depends on the size of your cloud environment

Note: With Mirantis OpenStack, network node and controller node combined to controller node

![openstack_architecture]
(http://docs.openstack.org/security-guide/_images/1aa-network-domains-diagram.png)

#### 2. How neutron works under XenServer

Back to networking, in Neutron's world, there are several concepts we need to clarify first.

##### 2.1 Logical networks

With Mirantis OpenStack, there are several networks involved.

    Public network (br-ex)
    Private network (br-prv)
    Internal network
        Management network (br-mgmt)
        Storage network (br-storage)
        PXE network (none)

These networks will be created automaitcally by Fuel during installation and they
are all Linux bridges. 

* Public network (br-ex): 

* Private network (br-int):
  
  This is tenant networ, in our case, it's VLAN. OpenStack tenant can define their own
  L2 network. This allows IP belonging to different overlap.

* Internal network:

  As the word internal, this is only used in OpenStack, and traffic in these networks will not go out.
  * PXE: Every node will boot from PXE network and it is only used for creating/booting new node
  * Management network: This is for openstack internal management and communication
  * Storage network: This is for cinder?
 

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
