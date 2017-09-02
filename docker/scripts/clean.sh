#!/bin/sh
set -x
set -e

clear
echo

### Strip, clean, install modules
{ find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; }

if [ -d /usr/local/bin ]; then
	chmod u+x /usr/local/bin/* 
fi

if [ -d /etc/s6.d ]; then
	chmod u+x /etc/s6.d/*/*
fi

