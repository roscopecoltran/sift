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



if [ -b $PATH_LF/log/log_doc_stat.log ] 
then
	touch $PATH_LF/log/log_doc_stat.log
fi

echo "****** Start log error cron document stat $DATE *******" >> $PATH_LF/log/log_doc_stat.log

# lancement de la génération  des CSV des stats des document les plus recherches 
ruby search_stats.rb 1>>$PATH_LF/log/log_doc_stat.log
