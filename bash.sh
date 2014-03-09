#!/usr/bin/env bash

cd ~

# open port 80
sudo iptables -I INPUT 5 -p tcp -m tcp --dport 80 -j ACCEPT
sudo /sbin/service iptables save
sudo service iptables restart

# ------------------------------------------------------------------------------

echo "Running initial-setup yum update..."
sudo rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
sudo yum -y updates
sudo yum -y install wget git
echo "...Finished running initial-setup yum update"
echo ""

# ------------------------------------------------------------------------------

echo "Installing PHP..."
sudo yum -y update
sudo yum -y install php55w php55w-opcache php55w-common php55w-cli php55w-pdo php55w-mcrypt php55w-mbstring php55w-xml php55w-pecl-memcache php55w-gd
sudo yum -y install php55w-pdo php55w-pgsql
sudo yum -y update
echo "...Finished installing PHP"
echo ""

# ------------------------------------------------------------------------------

echo "Installing latest version of epel-release rpm..."
sudo cat <<EOM >/etc/yum.repos.d/epel-bootstrap.repo
[epel]
name=Bootstrap EPEL
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgcheck=0
EOM
sudo yum --enablerepo=epel -y install epel-release
sudo rm -f /etc/yum.repos.d/epel-bootstrap.repo
echo "...Finished installing latest version of epel-release rpm"
echo ""

# ------------------------------------------------------------------------------

echo "Installing PostGRES/GIS..."
curl -O http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
sudo rpm -ivh pgdg-centos93-9.3-1.noarch.rpm
sudo yum -y install postgresql93-server postgis2_93

# initialize db and set up service
sudo service postgresql-9.3 initdb

# configure
sudo sed -i -e "s/peer/trust/" /var/lib/pgsql/9.3/data/pg_hba.conf
sudo sed -i -e "s/ident/trust/" /var/lib/pgsql/9.3/data/pg_hba.conf

# start service
sudo service postgresql-9.3 start
sudo chkconfig --levels 235 postgresql-9.3 on

# create database
sudo -u postgres -s createdb laravel
psql -U postgres -d laravel -c "CREATE EXTENSION postgis;"
echo "...Finished installing PostGRES/GIS"
echo ""

# ------------------------------------------------------------------------------

echo "Installing Nginx..."
sudo yum -y install nginx

# copy the nginx config across (doing this via GitHub for portability)
curl -O https://raw.github.com/coreymcmahon/CentOS-Stack-Vagrant/master/nginx.conf
sudo rm -f /etc/nginx/nginx.conf
sudo cp nginx.conf /etc/nginx/nginx.conf

# start the service 
sudo service nginx start
sudo chkconfig --levels 235 nginx on
echo "...Finished installing Nginx"
echo ""

# ------------------------------------------------------------------------------

echo "Installing php-fpm..."
sudo yum -y install php55w-fpm

# configure php-fpm
sudo sed -i -e "s/user = nobody/user = nginx/" /etc/php-fpm.d/www.conf
sudo sed -i -e "s/group = nobody/group = nginx/" /etc/php-fpm.d/www.conf

# start the service 
sudo service php-fpm start
sudo chkconfig --levels 235 php-fpm on
echo "...Finished installing php-fpm"
echo ""

# ------------------------------------------------------------------------------

echo "Installing Redis..."
sudo yum -y update
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm
sudo yum install redis -y

## start the service 
sudo service redis start
sudo chkconfig --levels 235 redis on
echo "...Finished installing Redis"
echo ""

# ------------------------------------------------------------------------------

echo "Installing Elasticsearch..."
cd ~
sudo yum update
sudo yum -y install java-1.7.0-openjdk

# wget http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.2.tar.gz -O elasticsearch.tar.gz
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.1.tar.gz -O elasticsearch.tar.gz
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

# start the service 
sudo service elasticsearch start
sudo chkconfig --levels 235 elasticsearch on
echo "...Finished installing Elasticsearch"
echo ""

# ------------------------------------------------------------------------------

echo "Installing Python, pip and supervisord..."

sudo yum -y install python-setuptools
sudo easy_install pip
sudo pip install virtualenvwrapper
sudo pip install supervisor

sudo cat <<EOM >>~/.bashrc
export WORKON_HOME=$HOME/.virtualenvs
source /usr/bin/virtualenvwrapper.sh
EOM

echo_supervisord_conf > supervisord.conf
sudo cp supervisord.conf /etc/supervisord.conf
sudo mkdir /etc/supervisord.d/

sudo cat <<EOM >>/etc/supervisord.conf
[include]
files = /etc/supervisord.d/*.conf
EOM

# copy the supervisord daemon config across (doing this via GitHub for portability)
curl -O https://raw.github.com/coreymcmahon/CentOS-Stack-Vagrant/master/supervisord
sudo cp supervisord /etc/rc.d/init.d/supervisord

sudo chmod +x /etc/rc.d/init.d/supervisord
sudo chkconfig --add supervisord
sudo chkconfig supervisord on

# "additional don't forget to specify the --env and --tries"
sudo cat <<EOM >/etc/supervisord.d/laravel-listener.conf
[program:laravel-listener]
command=php artisan queue:listen
directory=/usr/share/nginx/laravel
stdout_logfile=/usr/share/nginx/laravel/app/storage/logs/myqueue_supervisord.log
redirect_stderr=true
EOM

sudo service supervisord start

echo "...Finished installing Python, pip and supervisord"
echo ""

# ------------------------------------------------------------------------------

echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
echo "...Finished installing Composer"
echo ""

# ------------------------------------------------------------------------------

echo "Installing Laravel 4..."
cd /usr/share/nginx/
composer create-project laravel/laravel laravel
sudo chmod 777 -R /usr/share/nginx/laravel/app/storage/
echo "...Finished installing Laravel 4"
echo ""

# remember to set up your certificates

# ------------------------------------------------------------------------------

sudo touch /usr/share/nginx/laravel/app/storage/logs/myqueue_supervisord.log
chmod 777 /usr/share/nginx/laravel/app/storage/logs/myqueue_supervisord.log
sudo supervisorctl add laravel-listener
sudo supervisorctl start laravel-listener

echo "Fin."
