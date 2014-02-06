#!/usr/bin/env bash

# This can be used to find the hostname in AWS:
# PUBLIC_HOSTNAME="$(curl http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null)"

# open port 80
sudo iptables -I INPUT 5 -p tcp -m tcp --dport 80 -j ACCEPT
sudo /sbin/service iptables save
sudo service iptables restart


echo "Running initial-setup yum update..."
sudo rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
sudo yum -y update
sudo yum -y install wget
echo "...Finished running initial-setup yum update"
echo ""


echo "Installing PHP..."
sudo yum -y update
sudo yum -y install php55w php55w-opcache php55w-common php55w-cli php55w-pdo php55w-mcrypt php55w-mbstring php55w-xml php55w-pecl-memcache
sudo yum -y update
echo "...Finished installing PHP"
echo ""


echo "Installing PostGRES..."
curl -O http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm
rpm -ivh pgdg-centos92-9.2-6.noarch.rpm
sudo yum -y install postgresql92-server.x86_64 postgresql92-contrib.x86_64 postgresql92-devel.x86_64
sudo yum -y update
echo "...Finished installing PostGRES"
echo ""


echo "Installing Nginx..."
sudo yum -y install nginx

# configure nginx
sudo sed -i -e "1s/worker_processes  1/worker_processes  4/" /etc/nginx/nginx.conf

sudo sed -i -e "s/server_name  _;/#server_name  _;/" /etc/nginx/conf.d/default.conf
sudo sed -i -e "s/index  index.html index.htm;/index  index.php index.html index.htm;/" /etc/nginx/conf.d/default.conf
sudo sed -i -e "37s/#//" /etc/nginx/conf.d/default.conf
sudo sed -i -e "38s/#    root           html;/    root           \/usr\/share\/nginx\/laravel/public;/" /etc/nginx/conf.d/default.conf
sudo sed -i -e "39s/#//" /etc/nginx/conf.d/default.conf
sudo sed -i -e "40s/#//" /etc/nginx/conf.d/default.conf
sudo sed -i -e "41s/#    fastcgi_param  SCRIPT_FILENAME  \/scripts\$fastcgi_script_name;/    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;/" /etc/nginx/conf.d/default.conf
sudo sed -i -e "42s/#//" /etc/nginx/conf.d/default.conf
sudo sed -i -e "43s/#//" /etc/nginx/conf.d/default.conf

sudo service nginx start
sudo chkconfig --levels 235 nginx on
echo "...Finished installing Nginx"
echo ""


echo "Installing php-fpm..."
sudo yum -y install php-fpm

# configure php-fpm
sudo sed -i -e "s/user = nobody/user = nginx/" /etc/php-fpm.d/www.conf
sudo sed -i -e "s/group = nobody/group = nginx/" /etc/php-fpm.d/www.conf

service php-fpm start
sudo chkconfig --levels 235 php-fpm on
echo "...Finished installing php-fpm"
echo ""


echo "Installing Redis..."
sudo yum -y update
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm
sudo yum install redis -y
#start the service
service redis start
#start on boot
chkconfig redis on
echo "...Finished installing Redis"
echo ""


echo "Installing Elasticsearch..."
cd ~
sudo yum update
sudo yum -y install java-1.7.0-openjdk

wget http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.2.tar.gz -O elasticsearch.tar.gz
sudo tar -xf elasticsearch.tar.gz
sudo rm elasticsearch.tar.gz
sudo mv elasticsearch-* elasticsearch
sudo mv elasticsearch /usr/local/share
 
curl -L http://github.com/elasticsearch/elasticsearch-servicewrapper/tarball/master | tar -xz
sudo mv *servicewrapper*/service /usr/local/share/elasticsearch/bin/
sudo rm -Rf *servicewrapper*
sudo /usr/local/share/elasticsearch/bin/service/elasticsearch install

# configure elasticsearch
sudo sed -i -e "1s/<Path to ElasticSearch Home>/\/usr\/local\/share\/elasticsearch/" /usr/local/share/elasticsearch/bin/service/elasticsearch.conf
sudo sed -i -e "2s/1024/256/" /usr/local/share/elasticsearch/bin/service/elasticsearch.conf

sudo /etc/init.d/elasticsearch start
echo "...Finished installing Elasticsearch"
echo ""


echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
echo "...Finished installing Composer"
echo ""


echo "Installing Laravel 4..."
cd /usr/share/nginx/
composer create-project laravel/laravel laravel
echo "...Finished installing Laravel 4"
echo ""


echo "Fin."
