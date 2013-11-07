# encoding: utf-8
require 'listen'
require 'sequel'
require 'logger'

SITE_NAME = '秋月路/盛夏路'
LINE_HEIGHT = 83
IMAGE_HEIGHT=2048
IMAGE_WIDTH =2448
PATH_WF = '/home/liteng/gentek/wf/'
PATH_KK = '/home/liteng/gentek/kk/'

DB = Sequel.connect('sqlite://master.db')

class Camera < Sequel::Model(:cameras)
end
class Lane < Sequel::Model(:lanes)
  def before_create # or after_initialize
    super
    self.off_set_x ||= 0
    self.off_set_y ||= 0
  end
end
class CarInfo < Sequel::Model(:cars)
end

@@logger = Logger.new(STDOUT)
class CarInfoProcessor
  attr_accessor :xh,:hphm,:hpzl,:tgsj,:clsd,:xzsd,:clcd,:csys,:wjkzm,:wflx,
                :wfxw,:hdsj,:lkhm,:sbhm,:csdm,:clbz,:splx,:splj,:zpfx,
                :path ,
                :snap_time_1,:snap_time_2,:snap_time_3
  @@counter = 0
  #:id,:code,:speed,:car_iid,:time_snap,:time_report
  def read_inf(file)
    lines = File.read(file).encode("UTF-8","GBK",:invalid => :replace).split(/\r\n/)
    #lines.each {|l| print l}
    #p lines
    c = Camera.find("path like ?",File.dirname(file))
    @lane = Lane.find(camera_iid:c.camera_iid,camera_idx:lines[13].split('：')[1])
    self.lkhm = @lane.global_idx #车道号码 #we convert this + 
    self.get_wflx(lines[14].split('：')[1].to_i) #违法分类

    self.hphm = lines[29].split('：')[1] #车牌号码
    self.hpzl = lines[22].split('：')[1].to_i #号牌种类
    self.tgsj =DateTime.strptime(lines[8].split('：')[1][0..-4],'%Y-%m-%d %H:%M:%S') #通过时间 2013-08-23 13:16:58:670

    self.clsd =lines[16].split('：')[1].to_f #车辆速度
    self.xzsd =lines[17].split('：')[1].to_i #限速
    self.clcd =0 #lines[32] #车长
    self.csys =lines[33] #lines[34] #车身颜色
    self.wjkzm="" # #//文件扩展名

    self.hdsj =lines[15].split('：')[1].to_i #红灯时间
    self.sbhm ="" #设备号码
    self.csdm ="" #厂商代码
    self.clbz ="" #lines[17] #车辆厂商标志
    self.splx ="" #视频类型
    self.splj ="" #保存视频文件的相对路径
    self.zpfx =lines[4].split('：')[1]  #抓拍方向

    points = lines[25].split('：')[1].split(' ').map{|x| x[1..-1].to_f}
    @pos_plate = {
      pos_x:points[0]*IMAGE_WIDTH,pos_y:points[1]*IMAGE_HEIGHT,
      width:IMAGE_WIDTH*(points[2]-points[0]),height:IMAGE_HEIGHT*(points[3]-points[1])
    }

    (self.snap_time_1 = lines[8].split('：')[1])[-4]='.'
    (self.snap_time_2 = lines[9].split('：')[1])[-4]='.'
    (self.snap_time_3 = lines[10].split('：')[1])[-4]='.'

    self.path = file[0..-5]

    @@logger.info "#{Time.now}--file=#{file}--#{lines[13]}"
    self
  end
  
  def get_wflx(wflx)
    if ([8,9,10].include?(wflx)) 
      self.wflx = 4
      self.wfxw = "13022"
    end
    if ([13,14].include?(wflx))
      self.wflx = 23
      self.wfxw = "12080"
    end
  end

  def save
    p "path is #{path}"
  	#we do image convert here
    line_height = LINE_HEIGHT
    cmd = "convert -fill yellow -font simsun.ttc -pointsize #{line_height}"
    pix_1 = "#{path}-1.jpg"
    pix_2 = "#{path}-2.jpg"
    pix_3 = "#{path}-3.jpg"
    `#{cmd} -annotate +#{@lane.off_set_x}+#{@lane.off_set_y + line_height} 抓拍方向：#{zpfx} -annotate +#{@lane.off_set_x}+#{@lane.off_set_y + line_height*2} "#{snap_time_1}" #{pix_1} #{pix_1}`
    `#{cmd} -annotate +#{@lane.off_set_x}+#{@lane.off_set_y + line_height} 抓拍方向：#{zpfx} -annotate +#{@lane.off_set_x}+#{@lane.off_set_y + line_height*2} "#{snap_time_2}" #{pix_2} #{pix_2}`
    `#{cmd} -annotate +#{@lane.off_set_x}+#{@lane.off_set_y + line_height} 抓拍方向：#{zpfx} -annotate +#{@lane.off_set_x}+#{@lane.off_set_y + line_height*2} "#{snap_time_3}" #{pix_3} #{pix_3}`    
    
    `convert -size 4896x#{line_height} xc:black black.jpg`
    `convert -font simsun.ttc -fill white -annotate +3+#{line_height} "#{SITE_NAME} #{lkhm} #{snap_time_1[0..-4]} 红灯时间:#{hdsj}" -pointsize #{line_height} black.jpg black.jpg`
    
    dst="#{PATH_WF}#{@lane.global_idx}-#{tgsj.strftime('%Y%m%d%H%M%S')}-#{@@counter}"
    #print "convert -crop #{@pos_plate[:width]}x#{@pos_plate[:height]}+#{@pos_plate[:pos_x]}+#{@pos_plate[:pos_y]} -resize #{IMAGE_WIDTH}x#{IMAGE_HEIGHT}^ -quality 80 #{pix_1} #{dst}.jpg"
    `convert -crop #{@pos_plate[:width]}x#{@pos_plate[:height]}+#{@pos_plate[:pos_x]}+#{@pos_plate[:pos_y]} -resize #{IMAGE_WIDTH}x#{IMAGE_HEIGHT} -quality 80 #{pix_1} #{dst}.jpg`
    `convert +append #{dst}.jpg #{pix_1} #{dst}.jpg`
    `composite -gravity SouthWest black.jpg #{dst}.jpg #{dst}.jpg`

    `convert +append #{pix_2} #{pix_3} #{dst}-1.jpg`
    `composite -gravity SouthWest black.jpg #{dst}-1.jpg #{dst}-1.jpg`

    CarInfo.create(hphm:hphm,hpzl:hpzl,tgsj:tgsj,clsd:clsd,
                    xzsd:xzsd,clcd:clcd,wflx:wflx,hdsj:hdsj,
                    lkhm:lkhm,csys:csys,path:path,path_wf:dst)
    @@counter = (@@counter + 1)%10
  end
end

begin
n = 0
callback = Proc.new do |modified, added, removed|
  # This proc will be called when there are changes.
  n = n + 1
  p "#{Time.now}--------#{n}"
  files = added.grep(/3.jpg/)
  p files
  files.each do |f|
  	pattern = f[0..-7]
  	info = CarInfoProcessor.new().read_inf("#{pattern}.inf").save
    p info
  end
end

listener = Listen.to(Camera.all.map{|c| c.path},:filter => /-3\.jpg/,&callback)
listener.start # not blocking
sleep
end
