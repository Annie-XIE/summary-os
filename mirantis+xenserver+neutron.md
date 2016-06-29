### Mirantis 8.0 with XenServer 6.5/7.0 using Neutron VLAN

Mirantis OpenStack is the most popular distribution in IaaS area and
has 100+ enterprise customers.

XenServer as the leading open source virtualization platform, has released
its offical Fuel plugin based on Mirantis OpenStack 8.0, which provide neutron
VLAN support. This is the first release including neutron project on XenServer.
You can download from [fuel-plugin](https://www.mirantis.com/validated-solution-integrations/fuel-plugins/),
in section *Citrix XenServer Fuel Plugin*, select *MOS 8.0*.

In this blog, I will focus on network part regarding neutron is recently supported
together with XenServer. For basic Mirantis Fuel and XenServer introduction,
you can refer our previous [blog post](https://github.com/citrix-openstack/blogentries/blob/master/Introduction_To_XenServer_Fuel_Plugin.md) 

#### 1. What serivec it can provide for us?

Before go deep into technial part, I will show you the common functions that we can use
with MOS8.0 under XenServer.



##### 1.1 OpenStack deployment

![openstack_architecture]
(https://github.com/Annie-XIE/summary-os/blob/master/deployment-neutron-1.png)

##### 1.2 Neutron virtal network topo
![network node](https://github.com/Annie-XIE/summary-os/blob/master/pic/network-node.png)

![compute node](https://github.com/Annie-XIE/summary-os/blob/master/pic/compute-node.png)



#### 3. Architecture

#### 4. Future

Looking forward, we will add more features based on neutron, such as VxLAN
