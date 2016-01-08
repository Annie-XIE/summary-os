From http://xenserver.org/blog.html?view=entry&id=104


###XENSERVER产品DUNDEE预览版2发布

2015已接近尾声，2016正向我们招手，正是向XenServer社区发节日礼物的好时节。

今天，我们发布了下一代XenServer产品Dundee预览版2。我们花了大量精力解决已上报的各种问题，也导致该测试版本和九月份的预览版1相比有些延迟。我们确信该预览版2和Steve Wilson博客中对思杰在XenServer项目贡献的肯定是很好的新年礼物。作为礼物的一部分，我们计划发布一系列博客把主要改进点做深度介绍。对于那些更关注该预览版亮点的朋友，现在就让我为您做一一介绍。

###异构处理器集群
多年来XenServer一直支持用不同代的CPU创建处理器资源池，但是几年前采用因特尔CPU发生一些改变，这影响了混合使用最新的CPU和相对较老的CPU的能力。好消息是，使用Dundee预览版2，这种状况得到了彻底解决，且确确实实提高了性能。这个领域需要我们把事情完完全全的做正确，我们非常感激任何人运行Dundee体验该特性并上报成功或者上报遇到的问题。

###增强的扩展性

当代的服务器致力于增强其能力，我们不仅要与时俱进，更要确保用户能创建真正反应物理服务器能力的虚拟机。Dundee预览版2
目前支持512个物理CPU（pCPU），可创建高达1.5TB内存的用户虚拟机。您也许会问是否考虑增加虚拟CPU上限，我们已经把上限扩大到32个。在Xen项目的管理程序中，我们已经默认支持PML（Page Modification Logging）。
对PML设计的详细信息已经发布在Xen项目归档中等待审核。最后，XenServer的Dom0内核版本已经升级到3.10.93。

###支持新的SUSE版本

SUSE为其企业服务器版SLES（[SUSE Linux Enterprise Server](https://www.suse.com/products/server/)）和企业桌面版SLED（[SUSE Linux Enterprise Desktop](https://www.suse.com/products/desktop/)）发布了version 12 SP1，这两者在Dundee中都已得到支持。

###安全更新

自从Dundee预览版1在九月下旬发布后，若干安全相关的热补丁已经在XenServer 6.5 SP1中发布。
同样的补丁也应用到了Dundee并且已经包含在预览版2中。

###下载信息
您可以在[预览页](http://xenserver.org/overview-xenserver-open-source-virtualization/prerelease.html)(http://xenserver.org/preview) 下载Dundee预览版2，任何发现的问题都欢迎上报到我们的[故障库](https://bugs.xenserver.org/secure/Dashboard.jspa)(https://bugs.xenserver.org)。
