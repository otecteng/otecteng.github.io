sudo apt-get install -y apache2
sudo apt-get install -y libapache2-mod-php5 php5
echo "AddType application/x-httpd-php .php .phtml .php3" >> /etc/apache2/apache2.conf
sudo apt-get -y install apache2 mysql-server php5 php5-mysql php5-gd phpmyadmin
sudo apt-get -y install zend-framework
sudo apt-get -y install unzip
wget http://download.comsenz.com/DiscuzX/3.1/Discuz_X3.1_SC_UTF8.zip
unzip Discuz_X3.1_SC_UTF8.zip
cd /var/www/
sudo mkdir bbs
sudo cp -a ~/upload/* /var/www/bbs/
sudo chmod -R 777 /var/www
