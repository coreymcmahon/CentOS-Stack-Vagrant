#!/usr/bin/env bash

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
sudo yum -y install php55w-pdo php55w-pgsql
sudo yum -y update
echo "...Finished installing PHP"
echo ""


echo "Installing PostGRES..."
sudo curl -O http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
sudo rpm -ivh pgdg-centos93-9.3-1.noarch.rpm
sudo service postgresql-9.3 initdb

sudo chkconfig postgresql-9.3 on
sudo sed -i -e "s/peer/trust/" /var/lib/pgsql/9.3/data/pg_hba.conf
sudo sed -i -e "s/indent/trust/" /var/lib/pgsql/9.3/data/pg_hba.conf
sudo service postgresql-9.3 start

su - postgres
createdb laravel
exit

echo "...Finished installing PostGRES"
echo ""


echo "Installing Nginx..."
sudo yum -y install nginx

# configure nginx
sudo cp nginx.conf /etc/nginx/nginx.conf

sudo service nginx start
sudo chkconfig --levels 235 nginx on
echo "...Finished installing Nginx"
echo ""


echo "Installing php-fpm..."
sudo yum -y install php55w-fpm

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

# remember to set up your certificates

echo "Fin."
