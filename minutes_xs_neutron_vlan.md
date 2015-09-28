### 1. For single box installation, typically only one neutron-openvswitch-agent is needed.
But for XenServer case, we will need two, this is because the instances created by OpenStack
are actually connected to XenServer Dom0, so we need this additional one for control OVS 
within Dom0
