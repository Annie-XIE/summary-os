http://xenserver.org/

###XENSERVER DUNDEE BETA.2 可用

2015已接近尾声，2016正向我们招手，正是向XenServer社区发节日礼物的好时节。今天，我们发布了Dundee项目beta.2版本，这和九月份的beta.1版本相比有些延迟，这个延迟部分原因是我们花了不少精力解决各种已上报的问题。我们确信您会发现beta.2版本和Steve Willson在博客中对思杰在
XenServer项目上的贡献将会是很好的礼物。作为礼物的一部分，我们计划做一系列博客来把一些主要改进点做深度介绍。对于那些更关注该版本亮点的朋友，让我们现在就开始为您一一介绍。

###CPU级别
多年来XenServer一直支持从不同代的CPU中创建处理器资源池的能力，但是几年前采用因特尔CPU发生一些改变，这影响了混合使用最新的CPU和相对较老的CPU的能力。好消息是，使用Dundee beta.2版本，这种状况得到了完全的解决，并且确确实实提高了性能。这个领域需要我们把事情完完全全的做正确，我们感激任何人运行Dundee来尝试这个特性并上报成功或者是上报问题。

###增强的扩展性

现代的服务器致力于增强其能力，这不仅仅是因为我们要与时俱进，更是因为我们要确保用户能创建真正反应物理服务器能力的虚拟机。Dundee beta.2
目前支持512个物理CPU（pCPU），能创建高达1.5TB内存的用户虚拟机。有人会问增加虚拟CPU上限，我们已经把其设置到最大32个。在Xen项目的管理程序中，我们已经默认支持页面修改记录（PML）。对PML的设计详细信息已经发布在Xen项目归档中等待审核。最后，我们的内核版本已经到了3.10.93。

###新的SUSE模板

SUSE为其企业服务器版（SLES）和企业桌面版（SLED）发布了version 12 SP1，这两者在Dundee中都支持模板。

###安全更新

自从Dundee beta.1在九月下旬发布后，若干安全相关的热补丁已经在XenServer 6.5 SP1中发布。
同样的补丁也应用到了Dundee并且已经包含在beta.2中。

###下载信息
您可以在预览页 (http://xenserver.org/preview) 下载Dundee beta.2版本，任何发现的问题都可以上报到我们的故障库(https://bugs.xenserver.org)。

- 更多请参考: http://xenserver.org/blog.html?view=entry&id=104#sthash.MNzSY31f.dpuf

###XENSERVER DUNDEE BETA.2 AVAILABLE

With 2015 quickly coming to a close, and 2016 beckoning, it's time to deliver a holiday present 
to the XenServer community. Today, we've released beta 2 of project Dundee. While the lag between 
beta 1 in September and today has been a bit longer than many would've liked, part of that lag was 
due to the effort involved in resolving many of the issues reported. The team is confident you'll 
find both beta 2 and Steve Wilson's blog affirming Citrix's commitment to XenServer to be a nice 
gift. As part of that gift, we're planning to have a series of blogs covering a few of the major 
improvements in depth, but for those of you who like the highlights - let's jump right in!

###CPU LEVELING

XenServer has supported for many years the ability to create resource pools with processors 
from different CPU generations, but a few years back a change was made with Intel CPUs which 
impacted our ability mix the newest CPUs with much older ones. The good news is that with Dundee 
beta.2, that situation should be fully resolved, and may indeed offer some performance improvements. 
Since this is an area where we really need to get things absolutely correct, we'd appreciate anyone 
running Dundee to try this out if you can and report back on successes and issues.

###INCREASED SCALABILITY

Modern servers keep increasing their capacity, and not only do we need to keep pace, but we need 
to ensure users can create VMs which mirror the capacity of a physical machines. Dundee beta.2 
now supports up to 512 physical cores (pCPUs), and can create guest VMs with up to 1.5 TB RAM. 
Some of you might ask about increasing vCPU limits, and we've bumped those up to 32 as well. 
We've also enabled Page Modification Logging (PML) in the Xen Project hypervisor as a default. 
The full design details for PML are posted in the Xen Project Archives for review if you'd like 
to get into the weeds of why this is valuable. Lastly we've bumped the kernel version to 3.10.93.

###NEW SUSE TEMPLATES

SUSE have released version 12 SP1 for both (SUSE Linux Enterprise Server) SLES and 
(SUSE Linux Enterprise Desktop) SLED, both of which are now supported templates in Dundee.

###SECURITY UPDATES

Since Dundee beta.1 was made available in late September, a number of security hotfixes for 
XenServer 6.5 SP1 have been released. Where valid, those same security patches have been 
applied to Dundee and are included in beta.2.

###DOWNLOAD INFORMATION

You can download Dundee beta.2 from the Preview Download page (http://xenserver.org/preview), 
and any issues found can be reported in our defect database (https://bugs.xenserver.org).  

- See more at: http://xenserver.org/blog.html?view=entry&id=104#sthash.MNzSY31f.dpuf
