Problem

VM with volume live migration failed with XenAPI as nova compute driver, see https://bugs.launchpad.net/nova/+bug/1704071
The root cause of this problem is that xapi will do restrict check when doing live migration, i.e. {vdi: sr} mapping, {vif: network} mapping. But when VM with a volume try to do pre live migrate check, there is no iscsi SR at the destination host, so xapi will raise VDI_NOT_IN_MAP exception. You can refer the below picture for details, the problem is in the ones marked exclamation point.

![XenAPI-live-migration](https://github.com/Annie-XIE/summary-os/blob/master/pic/xenapi-live-migration.png)

But at the moment, we don't have good choice for xapi's exception, so swallow this exception
