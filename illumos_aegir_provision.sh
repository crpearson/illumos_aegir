#!/bin/sh
version=0.1

# Instructions from http://community.aegirproject.org/installing/manual
# this script is only for illumos based systems using pkgsrc
# I have removed all of the OS checks. If you are running an illumos distro with pkgsrc, you probably know it and don't need help

#############variables to change#####################
#the below line enables bash debugging
#set -x
#trap read debug

export aegir_ver=6.x-2.0-rc4
export DRUPAL_VER=6.x

#the following is the fqdn of the aegir front end
export AEGIR_HOST=`hostname`
export AEGIR_DB_PASS=your_db_password
export EMAIL=root@`hostname`
##########################end##################
export HOME=/var/aegir

echo " `basename $0` $version"

###alias
grep vi $HOME/.bashrc > /dev/null
if ! [ $? -eq 0 ]
then
cat >> $HOME/.bashrc << EOF
alias vi=vim
alias grep="grep --colour=auto"
EOF
fi

. $HOME/.bashrc

cd $HOME

echo " INFO: Installing drupal module : provision"
drush -y dl provision-$aegir_ver 

if [ "$aegir_ver" == "6.x-2.0-rc4" ]                                             
then                                                                             
	sed -i 's,https://drupal,http://drupal,g' $HOME/.drush/provision/aegir.make
fi

echo  " INFO: Running hostmaster install"
drush -y hostmaster-install $AEGIR_HOST --aegir_db_pass=$AEGIR_DB_PASS --client_email=$EMAIL

ln -s $HOME/hostmaster* hostmaster

#prepare crontab
echo " INFO: Updating crontab"
crontab -l | grep cron > /dev/null 2>&1
if ! [ $? -eq 0 ]
then
	crontab -l > /tmp/cron.aegir
	#echo "45 1 * * * /opt/local/bin/drush -y @sites up" >> /tmp/cron.aegir
	#echo "0 3 * * * /opt/local/bin/drush -y @hostmaster up" >> /tmp/cron.aegir
	echo "29 * * * * /opt/local/bin/drush -y @hostmaster cron > /dev/null" 
	crontab /tmp/cron.aegir
	rm -rf /tmp/cron.aegir
fi

echo "************************************************************************"
echo " INFO: Updating Drupal installation"
#enable the update module
#drush -y @hostmaster en update

#do the update
#drush -y @hostmaster up

echo "************************************************************************"
echo " INFO: Installation complete. Please read email for $EMAIL to continue"
echo "************************************************************************"
