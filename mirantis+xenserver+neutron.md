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

#### 1. Mirantis OpenStack

As we know nova network is deprecated, Mirantis OpenStack 8.0 also dropped
nova network support and changed to neutron network totally. So let's have
a quick look.



![openstack_architecture]
(https://github.com/Annie-XIE/summary-os/blob/master/deployment-neutron-1.png)

#### 2. How neutron works under XenServer

Neutron provides several virtual network topologies compared with nova network, so let's
start from a cross tenant VM connectivy.

##### 2.1 networks

br-mgmt

br-storage


##### 2.2 Traffic flow

East-West traffic

North-South traffic



#### 3. XenServer fuel plugin

#### 4. Future

Looking forward, we will enable more neutron features on XenServer, such as VxLAN, VPNaaS, 
SDN, ....
