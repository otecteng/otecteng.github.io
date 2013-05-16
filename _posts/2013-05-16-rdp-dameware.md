---
layout: default
title: RDP-Dameware使用
---

##{{ page.title }}
<br/>
###1) Dameware 10061  
一台多媒体设备，xp系统，音频屡次被远程桌面客户端带走未释放，用户反映影响恶劣，:(。于是准备换[Dameware](http://www.dameware.com/)替换掉远程桌面的功能。新开一台xp虚拟机，使用Dameware Remote Control连接，报错10061,环境：防火墙已关闭，RPC已开启。解决方法：`计算机配置->Windows设置->安全设置->本地策略->安全选项->网络访问：本地帐户的共享和安全模式->经典-本地用户以自己的身份验证`  
<br/>

###2)命令行开启远程桌面  
可是这种方法需要先在远程桌面登录后配置，问题是，远程桌面被关掉了。使用下列命令试图打开远程桌面：
`wmic /node:"192.168.1.1" /USER:"administrator" PATH win32_terminalservicesetting WHERE (__Class!="") CALL SetAllowTSConnections 1`，结果报RPC服务不可用，检查防火墙服务，系统响应无法启动ICS。重新启动虚拟机后，系统响应为拒绝访问，偶日！还是从控制台等里上去修改了身份验证方式后wmic才能正常使用  
<br/>

###3)RDP的音频设置  
回到原来的问题，应该有个更方便的办法，运行`MMC -> 文件 -> 添加/删除管理单元 -> 添加 -> 组策略对象编辑器 -> 添加 -> 本地计算机 -> 完成 -〉关闭 -> 确定`， 回到MMC界面。选择`计算机配置-> 管理模板 -> Windows 组件 -> 终端服务 -> 客户端/服务器数据重定向，允许音频重定向，改成禁用，确定`。  



