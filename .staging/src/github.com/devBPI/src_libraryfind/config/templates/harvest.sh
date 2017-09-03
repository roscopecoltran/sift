#!/bin/sh

### conf BPI ###
export PATH_LF="/srv/libraryfind"

### conf PARIS ###
#export PATH_LF="/home/dev/libraryfind"

### conf DEV ###
#export PATH_LF="/home/bpi/libraryfind"


cd $PATH_LF/components
pushd $PATH_LF/components
popd



if [ -b $PATH_LF/log/erreur.log ] 
then
	touch $PATH_LF/log/erreur.log
fi

echo "****** Start log error cron harvest $DATE *******" >> $PATH_LF/log/erreur.log

# notifications par mail
/opt/ruby-enterprise-1.8.7-2012.02/bin/ruby check_notices_availability.rb 2>>$PATH_LF/log/notify.log

# lancement de la moisson quotidienne
/opt/ruby-enterprise-1.8.7-2012.02/bin/ruby harvest.rb 2>>$PATH_LF/log/erreur.log