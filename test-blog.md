# Debugging on VMs cannot get IP from DHCP agent with XenServer + Neutron

XenServer+Neutron do work years before, but the support break when more
and more changes made in neutron. I began getting XenServer+Neutron back
to work with previous blog
[openstack-networking-quantum-on-xenserver](http://blogs.citrix.com/2013/06/14/openstack-networking-quantum-on-xenserver-from-notworking-to-networking/)

        Deployment environment:
            XenServer: 6.5
            OpenStack: latest master code
            Network: ML2 plugin, OVS driver, VLAN type
            Single Box installation
 
I had made some changes in DevStack script to let XenServer+Neutron be
installed and ran properly.
Below are some debugging processes I made when new launched VMs cannot get IP
from DHCP agent automatically.

### Brief description of VMs getting IP from DHCP process
When VMs are booting, they will try to send DHCP request broadcast message
within the same domain and waiting for DHCP server's reply. 

If VMs cannot get IP address, our straightforward reaction is to check whether 
the packages from the VMs can be recieved by DHCP server, see this picture 
[traffic flow](https://github.com/Annie-XIE/summary-os/blob/master/flow-VM-to-DomU.png)

#### Dump traffic in Network Node
Since I use DevStack with single box installation, all nodes reside in the same DomU.
##### 1. Check namespace that DHCP agent uses
execute `sudo ip netns` in DomU, you probably get outputs like these

        qrouter-17bdbe51-93df-4bd8-93fd-bb399ed3d4c1
        qdhcp-49a623fd-c168-4f27-ad82-946bfb6df3d7

*Note: qdhcp-xxx is the namespace for DHCP agent*

##### 2. Check interface DHCP agent uses for L3 packages
execute `sudo ip netns exec qdhcp-49a623fd-c168-4f27-ad82-946bfb6df3d7 ifconfig`, 
you can get interface like tapXXX 

      lo        Link encap:Local Loopback
                inet addr:127.0.0.1  Mask:255.0.0.0
                inet6 addr: ::1/128 Scope:Host
                UP LOOPBACK RUNNING  MTU:65536  Metric:1
                RX packets:0 errors:0 dropped:0 overruns:0 frame:0
                TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
                collisions:0 txqueuelen:0
                RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

      tap7b39ecad-81 Link encap:Ethernet  HWaddr fa:16:3e:e3:46:c1
                inet addr:10.0.0.2  Bcast:10.0.0.255  Mask:255.255.255.0
                inet6 addr: fe80::f816:3eff:fee3:46c1/64 Scope:Link
                inet6 addr: fdff:631:9696:0:f816:3eff:fee3:46c1/64 Scope:Global
                UP BROADCAST RUNNING  MTU:1500  Metric:1
                RX packets:42606 errors:0 dropped:0 overruns:0 frame:0
                TX packets:38 errors:0 dropped:0 overruns:0 carrier:0
                collisions:0 txqueuelen:0
                RX bytes:4687150 (4.6 MB)  TX bytes:4867 (4.8 KB)

##### 3. Monitor traffic flow with DHCP agent's interface tapXXX
execute `sudo ip netns exec qdhcp-49a623fd-c168-4f27-ad82-946bfb6df3d7 tcpdump -i tap7b39ecad-81 -s0 -w dhcp.cap` 
to monitor traffics flow with this interface

Theoretically, when launching a new instance, you should see DHCP request and
reply messages like [traffic dump](https://github.com/Annie-XIE/summary-os/blob/master/dhcp-dump.png)

#### Dump traffic in Compute Node

Meanwhile, you will definitely want to dump traffics at the VM side. 
This should be done in compute node, and with xenserver this is actually in Dom0. 

When new instance is launched, there will be a new virtual interface created named “vifX.0”. 
For example, if the latest interface is vif20.0, the next one will mostly be vif21.0.
Then you can try `tcpdump -i vif21.0`. It may fail at first because the virtual interface
is not created ready yet! But trying several times, once the virtual interface is created, 
you can monitor the packages. 

Theoretically you should see DHCP request and reply in Dom0, like you see in DHCP agent side.

*Note: If you cannot catch the dump package at the instance’s launching time, you can 
also try this using `ifup eth0` by login the instance via XenCenter. `ifup eth0` 
will also trigger the instance sending DHCP request.*

##### 1. Check DHCP request go out at VM side
In most case, you should see the DHCP request package sent out from Dom0, this means
that the VM itself is OK. It has sent out DHCP request message. 

Note: Some images will try to send DHCP request from time to time until it get the respond
message. However, some images won’t. They will only try several times, e.g. three time. 
Even if it cannot get DHCP responds it won’t try again any more. In some scenario, 
this will let the instance lost the chance of sending DHCP request. And that’s why 
some people on the internet suggest changing images when launching instance cannot get IP. 

##### 2. Check DHCP request go in at DHCP server side
But in my case, I cannot see any DHCP request from the DHCP agent side

Where the request package goes? It’s possible that the packages are dropped? 
Then who dropped these packages? Why drop them? 

If we think it a bit more, it’s either L2 or L3 that dropped. With this in mind, 
we can begin to check one by one.
For L3/L4,  I don’t set firewall and the security group’s default rule is to let 
all packages go through. So, I don’t spent so much effort on this part.

For L2, since we use  OVS, I begin to check OVS rules. It will take you much time 
if you are not familiar with OVS. At least I spent much time on it for totally 
understanding the mechanism and the rules.

The main aim is to check that all existing rules in Dom0 and DomU, and then try 
to find out which rule let the packages dropped.

#### Check OVS flow rules

##### 1. OVS flow rules in Network Node
execute `sudo ovs-ofctl show br-int` to get the port information on bridge br-int

      stack@DevStackOSDomU:~$ sudo ovs-ofctl show br-int
      OFPT_FEATURES_REPLY (xid=0x2): dpid:0000ba78580d604a
      n_tables:254, n_buffers:256
      capabilities: FLOW_STATS TABLE_STATS PORT_STATS QUEUE_STATS ARP_MATCH_IP
      actions: OUTPUT SET_VLAN_VID SET_VLAN_PCP STRIP_VLAN SET_DL_SRC SET_DL_DST SET_NW_SRC SET_NW_DST SET_NW_TOS SET_TP_SRC SET_TP_DST ENQUEUE
        1(int-br-eth1): addr:1a:2d:5f:48:64:47
            config:     0
            state:      0
            speed: 0 Mbps now, 0 Mbps max
        2(tap7b39ecad-81): addr:00:00:00:00:00:00
          config:     PORT_DOWN
          state:      LINK_DOWN
          speed: 0 Mbps now, 0 Mbps max
        3(qr-78592dd4-ec): addr:00:00:00:00:00:00
          config:     PORT_DOWN
          state:      LINK_DOWN
          speed: 0 Mbps now, 0 Mbps max
        4(qr-55af50c7-32): addr:00:00:00:00:00:00
          config:     PORT_DOWN
          state:      LINK_DOWN
          speed: 0 Mbps now, 0 Mbps max
        LOCAL(br-int): addr:9e:04:94:a4:95:bb
          config:     PORT_DOWN
          state:      LINK_DOWN
          speed: 0 Mbps now, 0 Mbps max
      OFPT_GET_CONFIG_REPLY (xid=0x4): frags=normal miss_send_len=0

execute `sudo ovs-ofctl dump-flows br-int` to get the flow rules

      stack@DevStackOSDomU:~$ sudo ovs-ofctl dump-flows br-int
      NXST_FLOW reply (xid=0x4):
        cookie=0x9bf3d60450c2ae94, duration=277625.02s, table=0, n_packets=31, n_bytes=4076, idle_age=15793, hard_age=65534, priority=3,in_port=1,dl_vlan=1041 actions=mod_vlan_vid:1,NORMAL
        cookie=0x9bf3d60450c2ae94, duration=277631.928s, table=0, n_packets=2, n_bytes=180, idle_age=65534, hard_age=65534, priority=2,in_port=1 actions=drop
        cookie=0x9bf3d60450c2ae94, duration=277632.116s, table=0, n_packets=42782, n_bytes=4706099, idle_age=1, hard_age=65534, priority=0 actions=NORMAL
        cookie=0x9bf3d60450c2ae94, duration=277632.103s, table=23, n_packets=0, n_bytes=0, idle_age=65534, hard_age=65534, priority=0 actions=drop
        cookie=0x9bf3d60450c2ae94, duration=277632.09s, table=24, n_packets=0, n_bytes=0, idle_age=65534, hard_age=65534, priority=0 actions=drop

These rules in DomU looks like normal without suspicious, so go on with Dom0 and try to find more.

##### 2. OVS flow rules in Compute Node
As analysis with this picture [traffic flow](https://github.com/Annie-XIE/summary-os/blob/master/flow-VM-to-DomU.png), 
the traffic direction from VM to DHCP is xapiX->xapiY(Dom0), then ->br-eth1->br-int(DomU). 

So, maybe some rules filtered the packages at layer 2 level by OVS. I do suspect 
xapiY although I cannot say direct reasons. So checked rules in xapiY, in our 
case it is xapi3 actually.

execute `ovs-ofctl show xapi3` get port information

      [root@rbobo ~]# ovs-ofctl show xapi3
      OFPT_FEATURES_REPLY (xid=0x2): dpid:00008ec00170b013
      n_tables:254, n_buffers:256
      capabilities: FLOW_STATS TABLE_STATS PORT_STATS QUEUE_STATS ARP_MATCH_IP
      actions: OUTPUT SET_VLAN_VID SET_VLAN_PCP STRIP_VLAN SET_DL_SRC SET_DL_DST SET_NW_SRC SET_NW_DST SET_NW_TOS SET_TP_SRC SET_TP_DST ENQUEUE
        1(vif15.1): addr:fe:ff:ff:ff:ff:ff
          config:     0
          state:      0
          speed: 0 Mbps now, 0 Mbps max
        2(phy-xapi3): addr:d6:37:17:1d:01:ee
          config:     0
          state:      0
          speed: 0 Mbps now, 0 Mbps max
        LOCAL(xapi3): addr:5a:46:65:a2:3b:4f
          config:     0
          state:      0
          speed: 0 Mbps now, 0 Mbps max
      OFPT_GET_CONFIG_REPLY (xid=0x4): frags=normal miss_send_len=0

execute `ovs-ofctl dump-flows xapi3` to get flow rules

      [root@rbobo ~]# ovs-ofctl dump-flows xapi3
      NXST_FLOW reply (xid=0x4):
        cookie=0x0, duration=278700.004s, table=0, n_packets=42917, n_bytes=4836933, idle_age=0, hard_age=65534, priority=0 actions=NORMAL
        cookie=0x0, duration=276117.558s, table=0, n_packets=31, n_bytes=3976, idle_age=16859, hard_age=65534, priority=4,in_port=2,dl_vlan=1 actions=mod_vlan_vid:1041,NORMAL
        cookie=0x0, duration=278694.945s, table=0, n_packets=7, n_bytes=799, idle_age=65534, hard_age=65534, priority=2,in_port=2 actions=drop

Please pay attention to port `2(phy-xapi3)`, it has two specific rules:

• The higher priority=4 will be matched firstly, if the dl_vlan=1, it will modify the tag 
and then with normal process, which will let the flow through

• The lower priority=2 will be matched secondly, it will drop the flow.
So, will the flows be dropped? If the flow doesn’t have dl_vlan=1, it will be dropped definitely.

*Note:*

*(1) For dl_vlan=1, this is the virtual LAN tag id which corresponding to the Port tag*

*(2) I didn’t realize the problem is lacking tag for the new launched instance for 
a long time due to my lack of OVS mechanism. Thus I don’t have such sense of checking 
the port’s tag with this problem at first. So next time when we meet this problem, 
we can check these part first.*

With this question, I checked the new launched instance’s port information, 
ran command `ovs-vsctl show` in Dom0, you can get outputs like these:

    Bridge "xapi5"
        fail_mode: secure
        Port "xapi5"
            Interface "xapi5"
                type: internal
        Port "vif16.0"
            Interface "vif16.0"
        Port "int-xapi3"
            Interface "int-xapi3"
                type: patch
                options: {peer="phy-xapi3"}

For port vif16.0, it really doesn’t have tag with value 1, so the flow will be dropped without doubt.

*Note: When launching a new instance under xenserver, it will have a virtual network
interface named vifx.0, and from OVS’s point of view, it will also create a port 
and bound that interface correspondingly.*

#### Check why tag is not set
The next step is to find out why the new launched instance don’t have tag in OVS.
There is no obvious findings for new comers like me. Just read the code over and over 
and make assumptions and test and so forth.

But after trying this and that a while, I did find each time when I resart 
neutron-openvswitch-agent(*q-agt*) in Compute Node, the VM can get IP if I execute `ifup etho` command.

So, there must be something which is done when *q-agt* restart and
is not done when launching a new instance. With this findings, it's much more targeted
while reading codes.

Finally I found that, with XenServer, when new instance is launched, 
*q-agt* cannot detect new added port and it will not add tag to this port consequently.

But why *q-agt* cannot detect port changes?
We have a session from DomU to Dom0 to monitor port changes, seems it cannot work as we expected.

With this in mind, I first ran command `ovsdb-client monitor Interface name,ofport` 
in Dom0, you probably get outputs like this:

                [root@rbobo ~]# ovsdb-client monitor Interface name,ofport
                row                                  action  name        ofport
                ------------------------------------ ------- ----------- ------
                54bcda61-de64-4d0e-a1c8-d339a2cabb50 initial "eth1"      1     
                987be636-b352-47a3-a570-8118b59c7bbc initial "xapi3"     65534 
                bb6a4f70-9f9c-4362-9397-010760f85a06 initial "xapi5"     65534 
                9ddff368-0be5-4f23-a03c-7940543d0ccc initial "vif15.2"   1     
                ba3af0f5-e8ed-4bdb-8c3d-67a638b81091 initial "phy-xapi3" 2     
                b57284cf-1dcd-4a10-bee1-42516afe2573 initial "eth0"      1     
                38a0dd37-173f-421c-9aba-3e03a5b8c900 initial "vif16.0"   2     
                58b83fe4-5f33-40f3-9dd9-d5d4b3f25981 initial "xenbr0"    65534 
                6c792964-3930-477c-bafa-5415259dea96 initial "int-xapi3" 1     
                caa52d63-59ed-4917-9ec3-1ea957470d5e initial "vif15.1"   1     
                d8805d05-bbd2-40cb-b219-eb9177c217dc initial "vif15.0"   6     
                8131dcd2-69ea-401a-a65e-4d4a17203e0c initial "xapi4"     65534 
                086e6e3a-1ab2-469f-9604-56bbd4c2fe86 initial "xenbr1"    65534 

Then I launched a new instance try to find whether OVS monitor can give new output
for the new launched instance, and I do get outputs like:

                row                                  action name      ofport
                ------------------------------------ ------ --------- ------
                249c424a-4c9a-47b4-991a-bded9ec63ada insert "vif17.0" []    
                
                row                                  action name      ofport
                ------------------------------------ ------ --------- ------
                249c424a-4c9a-47b4-991a-bded9ec63ada old              []    
                                     new    "vif17.0" 3    

So, this means the OVS monitor itself works well! There maybe other errors with the
code that makes the monitoring. Seems it much more nearer with the root cause:)

Finally, I found with XenServer, our current implementation cannot get the OVS monitor's
output, and thus *q-agt* cannot know there is new port added. But lucky enough, 
L2 Agent provide another way of getting the ports changes, and thus we can first use 
that way instead.

Finally, I found with XenServer, our current implementation cannot get the OVS monitor's
output, and thus q-agt cannot know there is new port added. But lucky enough, L2 Agent provide
another way of getting the ports changes, and thus we can first use that way instead.

Setting minimize_polling=false in the L2 agent's configuration file ensures the Agent does not
rely on "ovsdb-client monitor", which means that the port will be identified and the tag gets added!

In this case, this is all that was needed to get an IP address and everything else worked normally.

