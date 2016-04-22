### Migrate OpenStack DomU to another host

Given you need to migrate your DomU with OpenStack installed to another host,
you need to set `XEN_INTEGRATION_BRIDGE` in localrc if neutron network is used.
It is the bridge for `XEN_INT_BRIDGE_OR_NET_NAME` network created in Dom0


-### Install OpenStack on an existing DomU VM
-
-Given you have an installed DomU already and there is a requirement to install
-OpenStack on this DomU.
- - Download devstack, see `Step 2: Download devstack`
- - Configure localrc,
- see `Step 3: Configure your localrc inside the devstack directory`
- - Set XEN_INTEGRATION_BRIDGE in localrc if neutron network is used. It is the
- bridge for XEN_INT_BRIDGE_OR_NET_NAME network created in Dom0
