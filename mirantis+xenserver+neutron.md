### Mirantis 8.0 with XenServer 6.5/7.0 using Neutron VLAN

Mirantis OpenStack is the most popular distribution in IaaS area and
has 100+ enterprise customers. 

XenServer as the leading open source virtualization platform, has released
its offical Fuel plugin based on Mirantis OpenStack 8.0, which provides neutron
VLAN support. This is the first release including neutron project on XenServer.
You can download from [fuel-plugin](https://www.mirantis.com/validated-solution-integrations/fuel-plugins/),
in section *Citrix XenServer Fuel Plugin*, select *MOS 8.0*.

In this blog, I will focus on network part since neutron is recently supported
together with XenServer. For basic Mirantis and XenServer introduction,
you can refer our previous [blog post](https://github.com/citrix-openstack/blogentries/blob/master/Introduction_To_XenServer_Fuel_Plugin.md) 

#### 1. How the network is deployed?

Phyical 

Network is a very complicated part in cloud computing area, so let's first
go through some basic knowledge on neutron.

Tenant network supported

Neutorn security group supported




##### 1.1 OpenStack deployment

![openstack_architecture]
(https://github.com/Annie-XIE/summary-os/blob/master/deployment-neutron-1.png)

##### 1.2 Neutron virtal network topo
![network node](https://github.com/Annie-XIE/summary-os/blob/master/pic/network-node.png)

![compute node](https://github.com/Annie-XIE/summary-os/blob/master/pic/compute-node.png)



#### 3. Architecture

#### 4. Future

Looking forward, we will add more features based on neutron, such as VxLAN
