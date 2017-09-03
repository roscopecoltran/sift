#!/bin/sh
### conf BPI ###
export PATH_LF="/srv/libraryfind"
### conf PARIS ###
#export PATH_LF="/home/dev/libraryfind"
### conf DEV ###
#export PATH_LF="/home/bpi/libraryfind"

DATE=$(date +%d-%m-%Y-%H-%M)

if [ -b $PATH_LF/log/rss_error.log ] 
then
	touch $PATH_LF/log/rss_error.log
fi

echo "****** Start log error rss $DATE *******" >> $PATH_LF/log/rss_error.log

cd $PATH_LF/components
ruby update_rss_feeds.rb 2>>$PATH_LF/log/rss_error.log
