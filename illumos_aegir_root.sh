#!/bin/sh
version=0.1

# this script is only for illumos based systems using pkgsrc
# I have removed all of the OS checks. If you are running an illumos distro with pkgsrc, you probably know it and don't need help

##############variables to change#########################


interface=net0


###############end#######################

echo " `basename $0` $version"


#variables
export WEBHOME=/var/aegir
export PATH=/opt/local/bin:/usr/local/sbin:/usr/local/bin:/opt/local/sbin:/opt/local/bin:/usr/sbin:/usr/bin:/sbin

# DaFu? php53-process, php53-xml, php-drush-drush
pkgin -y in apache-2.2 \
postfix \
unzip \
mysql-server \
php53 \
php53-posix \
php53-pdo \
php53-mysql \
php53-json \
scmgit \
php53-mbstring \
bzr \
cvs \
php53-gd \
php53-pear \
php53-apc \
php53-curl \
php53-dom \
php53-iconv \
php53-memcache \
php53-pdo_mysql \
php53-zlib

awk '/extension=modulename.extension/{print $0 \
RS "extension=apc.so" \
RS "extension=curl.so" \
RS "extension=dom.so" \
RS "extension=gd.so" \
RS "extension=pdo.so" \
RS "extension=mysql.so" \
RS "extension=zlib.so" \
RS "extension=iconv.so" \
RS "extension=pdo_mysql.so" \
RS "extension=json.so" \
RS "extension=mbstring.so" \
RS "extension=posix.so" \
RS "extension=memcache.so";
next}1' /opt/local/etc/php.ini > /var/tmp/scratch && mv /var/tmp/scratch /opt/local/etc/php.ini

echo " INFO: Raising PHP's memory limit to 512M"
sed -i 's/^memory_limit = .*$/memory_limit = 512M/g' /opt/local/etc/php.ini 

echo " INFO: Restarting httpd and mysqld"
svcadm enable mysql
svcadm restart mysql


mysql -uroot -e 'show databases;' > /dev/null 2>&1
if [ $? -eq 0 ]
then 
	/opt/local/bin/mysql_secure_installation
else
	echo " INFO: MySQL previous configured. Skipping"
fi

echo " INFO: AEgir User creation"
mkdir -p $WEBHOME
useradd -d $WEBHOME -G www aegir
#groupadd aegir
#groupadd apache
chmod -R 755 $WEBHOME
echo "aegir" >> /etc/cron.d/cron.allow

! [ -d $WEBHOME ] && mkdir $WEBHOME
chown aegir.www $WEBHOME

grep aegir /opt/local/etc/sudoers > /dev/null
if ! [ $? -eq 0 ]
then
        echo "aegir ALL=NOPASSWD: /opt/local/sbin/apachectl" >> /opt/local/etc/sudoers
        sed -i 's/^Defaults    requiretty/#Defaults    requiretty/g' /opt/local/etc/sudoers
fi

if ! [ -d /etc/httpd/conf.d/aegir.conf ]
then 
	mkdir -p /opt/local/etc/httpd/conf.d
        ln -s $WEBHOME/config/apache.conf /opt/local/etc/httpd/conf.d/aegir.conf
        sed -i 's/^#Include etc\/httpd\/httpd-vhosts.conf/Include etc\/httpd\/conf.d\/aegir.conf/g' /opt/local/etc/httpd/httpd.conf
        
fi

#dns configuration - add to /etc/hosts
hostfile(){
echo " INFO: Adding `hostname` entry to /etc/hosts"
ip=`ifconfig $interface | grep -w inet | awk '{print $2}' | cut -d: -f2`
echo -e "$ip\t`hostname`" >> /etc/hosts
}

grep `hostname` /etc/hosts
#resolveip `hostname` > /dev/null
if ! [ $? -eq 0 ]
then
	grep `hostname` /etc/hosts > /dev/null
	if ! [ $? -eq 0 ]
	then
		hostfile
	else
		echo " ERROR: `hostname` does not resolve even though it is /etc/hosts"
	fi
fi


drush_upgrade(){ #upgrade drush to latest
pear upgrade
pear channel-discover pear.drush.org
pear install drush/drush
}

drush_upgrade

# Hack
chgrp www /opt/local/lib/php/drush/lib
chown 775 /opt/local/lib/php/drush/lib
# /Hack
