http://xenserver.org/

###XENSERVER DUNDEE BETA.2 可用

2015已接近尾声，2016正向我们招手，是时候向XenServer社区发节日礼物了。
今天，我们已经发布了Dundee项木的beta 2版本。这个版本和九月份的beta 1版本有些拖延，
这个延迟部分原因是我们花了不少精力来解决上报的各种问题。我们确信您会发现beta 2版本
和Steve Willson在博客中对思杰在XenServer项目上的贡献将会是一个很好的礼物。
作为礼物的一部分，我们计划做一系列博客来把一些主要改进点做深度介绍。
对于那些更关注亮点的朋友，让我们现在就开始

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

###CPU级别
XenServer已经支持从不同代的CPU中创建资源池

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
