---
layout: default
title: Opennebula测试系统的安装
---

##{{ page.title }}  
<br/>

之前我们的[Opennebula](http://opennebula.org)系统由1个管理节点和2个计算节点组成，都运行在centos上，试用了几个月效果挺好，后来就把主要的项目测试都跑在上面，再后来把svn和maven nexus都用kvm来跑了。系统用了大概半年，一直都不错，但是上周管理节点的存储意外坏掉，花了大约一周的时间才把所有的内容恢复，基本过程比较顺利，有一些细节问题需要记录一下备忘。
    
###基本结构  
采用ubuntu11.04+opennebula3.0,安装过程基本参照婉兮清扬的[这篇文章](http://www.qyjohn.net/?p=1581)，修改了两个地方:  
管理节点的nfs设置，原文  

    /srv/cloud  *(rw,fsid=0,nohide,sync,root_squash,no_subtree_check)  

修改为  

    /srv/cloud  *(rw,fsid=0,nohide,async,no_root_squash,no_subtree_check)  

如果no_root_squash不设置的话，计算节点上的chown oneadmin:cloud /srv/cloud/会执行失败。async的设置是我觉得kvm运行的有点慢，就设置了一下，不知道是不是真的有必要设置。  
<br>

计算节点的kvm设置：  
需要增加一个link，否则在virsh的create时会报/usr/libexec/qemu-kvm找不到的错误，这点原文没讲到。  
	
	ln -sf /usr/share/qemu-kvm /usr/libexec/qemu-kvm  

<br>


###制作虚拟机模板时遇到的几个问题  
vnc端口错误，模板文件设置了vnc端口，导致第2个实例无法启动，没有vnc时又很难排错，这个问题困扰了我两天，最后解决的办法很简单，不要设置vnc的端口即可。
disk bus的选择：默认选择总是ide(?)，在运行windows2003的实例时很慢，刚开始以为是nfs的设置问题，后来将disk bus从ide更换成virtio，速度就比较理想了，同样的问题也出现在ubuntu的实例上.

###几个重要的日志的位置  
以oneadmin用户为登录用户，~/var/下面的oned.log和sched.log，跟opennebula相关的问题从里面基本上都能找到答案。计算节点的/var/log/libvirt/qemu目录下的实例日志，对于单个实例的运行失败查错很有用。  
<br>

###vmcontext的编写  
ubuntu按照opennebula的文档做就可以了，centos5.8的vmcontext按照文档没做好，最后懒得想，直接放到rc.local里去运行，结果还不错，windows server2003和windows 7的vmcontext用ruby各写了一个脚本，放到计划任务启动项执行。  

