#!/bin/sh

### conf BPI ###
export PATH_LF="/srv/libraryfind"

### conf PARIS ###
#export PATH_LF="/home/dev/libraryfind"

### conf DEV ###
#export PATH_LF="/home/bpi/libraryfind"

DATE=$(date +%d-%m-%Y-%H-%M)

cd $PATH_LF/components
pushd $PATH_LF/components
popd

if [ -b $PATH_LF/log/erreur_stats.log ] 
then
	touch $PATH_LF/log/erreur_stats.log
fi

echo "****** Start log error cron stats $DATE *******" >> $PATH_LF/log/erreur_stats.log

# Mise à jour des statistiques
ruby save_log.rb 2>>$PATH_LF/log/erreur_stats.log