---
layout: default
title: 使用Google Speech API给视频加字幕
---

##{{ page.title }}  
<br/>

###缘起
先推荐两个不错的rails-cast的网站，[railscast-china](http://railscasts-china.com/) ，[happycasts](http://happycasts.net/)，听力不咋样的人看[railscasts](http://railscasts.com/)吃力,心想要是有个英文字幕也好啊，Google Voice Search貌似做的挺好了， Google Speech API也有不少的介绍（[推荐这篇吧](http://blog.csdn.net/dlangu0393/article/details/7214728)），那我就尝试一下把视频加上字幕看看效果。  
思路就是分割音频后用Google Speech API去识别，时间轴的问题先不考虑。  
实验品就是happycasts上的[这一段](http://happycasts.net/episodes/67)。

###过程
  
<br>

####下载视频后，使用ffmpeg分离音视频

	ffmpeg -i 067-google-analytics.mov -vn -acodec pcm_s16le -ac 1 audio.wav  

####分割音频文件，转换成FLAC格式
Google Speech API接收的文件大小有限制，所以，我们还需要先进行文件分割。这里罗嗦一下，花了我好多时间，最后也没算弄好哦。我原先的思路是断句分割，去翻了[Exploring Everyday Things with R and Ruby](http://shop.oreilly.com/product/0636920022626.do)，记得书里好像正好有这么一段，果然找到对wav进行频率分析的一段，挺简单，搬过来，曲线画出来还挺好看。（图在excel里画得，晚点补上）加上阀值，分割段落，碰到麻烦了，出现很多小段落，比如说，peter点了一下鼠标，或者敲了一下键盘，就碰上一个分割。现在暂时按时间分割。<font color="#990000">这里求救！</font>

	File.open("audio.wav") do |file|
  		header = file.read(42)
  		file.seek(42)
  		length = file.read(4).unpack('l')[0] 
  		n = length / (226640*4) 
  		(0..n).each do |i|
			File.open("#{i}.wav","wb") do |clip|
				clip.write(header)
				f_start,f_end = i*10*22664*4,(i+1)*10*22664*4
				f_end = length if f_end > length 
				clip.write(Array(f_end-f_start).pack('V'))
				file.seek(42+4+f_start)
				clip.write(file.read(f_end-f_start))
				clip.close	
			end    
  		end
	end

格式也有人说wav就可以，可是我还是转成FLAC格式了  

	Dir.glob("*.wav").each do|f|
		`ffmpeg -i #{f} -ab 16k -y #{f}.flac` if f =~ /^[0-9]/
	end

####送到Google speech api去解析

	Dir.glob("*.flac").sort{|x,y| x.to_i <=> y.to_i}.each do|f|
		`wget -O #{f}.txt --user-agent="Mozilla/5.0" --post-file=#{f} --header="Content-Type: audio/x-flac; rate=44100" "http://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&lang=zh-CN&maxresults=1"`
	end

	Dir.glob("*.flac.txt").sort{|x,y| x.to_i <=> y.to_i}.each do|f|
		res=File.open(f).read
		next if res.length == 0
		res = JSON.parse(res)
		text = res["hypotheses"][0]["utterance"] if res["hypotheses"].length > 0
		p text
	end


###结果(大家可以看看能不能看懂)：

	"大家好当我们网站上线之后那肯定我们每天有那么我们的网站到底有没有多少流量然后用不到网站上到底对比"
	"今天内容了还有继续求那我们就需要一款网站流量统计工具今天我们的视频那就别来介绍 google translate"
	"你现在聊了怎么在自己的网站上应用 google analytics 具体的步骤能可以参考这个认定标签 sina"
	"可以找到该经典 kitty cat 中国人就是深不抵不能设置一个账户别说没有 gmail 账户的话就可以直接登录"
	"你在我的名现在已经有创意的三个坑梓山港货给我打开 sd 卡子这个是账户名厦门 dnf 70"
	"w. 名字这对我们具体的网站也就是这日子我说的价格 empty 美国"
	"男人穿金口在哪脑电开机铁剂个 ry pot 点击 admin 然后呢在春季你不理"
	"可以找到爱情的这个手机真挺好的那我们要做的就是在我们需要跟中的这个网站的事"
	"我有的页面什么都加上对一段代码的天气麻烦但实际上我们大部分网站的其实都是由"
	"怎么办见了这人吗我的没看李湘吗你现在在哪里能我知你真的要修改的地方来就一处"
	"在我们的模版之中吗加入我们这个真辛苦的女友然后那我们就拥有了"
	"google maps 提供给我们的很丰盛的一个数据报告说明打开工具体的几个孩子了统计信息手写的可以看到每日的"
	"这个方亮白可以选择 1 小时或者月安卓越来做统计真的可以选择时间跨度"
	"仙美地信息了也都是非常的一幕僚人的日子那我们可以看到还是有多少这个朋友过来帝国"
	"yy yyy 打电话给决定我的这个网站用不用很好的这个可以支持这些信息的都有助于"
	"再见我们的商业策略惠氏网站的技术架构上边的这点之间别特别的 tion s your 非常惊艳的这么一个功能"
	"min ster school 用户的操作的流程是啊你看是网站的地点时间的禁用物质中能看到有多少男士来及管理"
	"有多少是国外的一个访问来的时候能坦的主路点都是那个了之后的有多少人感觉到失望爱人的离开了"
	"会继续访问继续访问的他一个侏儒电子部电视哪一个你的信息呢我可以看出用户最喜欢的食物"
	"网站上的你一些朋友你心里面地方标准地方的我看评价有所加强第五人问津的竟然有里面的我现在的位置"
	"歌曲删掉 hp tc 西南第一任何的网站开发怎么都是非常有诱惑力的飞车不要再有有一句然后尽快的使用"
	"google analytics 2009 谢谢谢谢来讲下周见"

