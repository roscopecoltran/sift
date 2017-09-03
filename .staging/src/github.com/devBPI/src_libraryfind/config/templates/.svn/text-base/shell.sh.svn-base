# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
# === Color ===
red='\e[0;31m'
RED='\e[1;31m'
green='\e[0;32m'
GREEN='\e[1;32m'
blue='\e[0;34m'
BLUE='\e[1;34m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
yellow='\e[0;33m'
YELLOW='\e[1;33m'
NC='\e[0m'

# Global
rule=''

get_rule()
{
	part="[-a-zA-Z0-9 \'\"@_.,:\/?\\$]"
	#part="(.)*"
	regxp="$part+:{1}$part+"
	var=$@;
	count=1
	rule=''
	test=`echo $var | cut -d ';' -f $count | grep -oE "$regxp"`;
	while [ "$test" ]
	do
		left=`echo $test | cut -d ":" -f 1 | tr -d ' '`
		right=`echo $test | cut -d ":" -f 2-999`
		right=`echo $right | sed s/'\/'/'\\\\\/'/g | sed s/'42\$42'/';'/`
		#echo -e $right

		echo -e $yellow"Variable Identifier : \t"$green \'$left\' $yellow"\tValue :\t"$red""$right""$NC
		rule=`echo " -e s/@$left@/$right/g" $rule | tr -d '\n'`
		#echo -e $rule
		count=`expr $count + 1`
		test=`echo $var | cut -d ';' -f $count | grep -oE "$regxp" | tr -d '\n'`;
	done
	return ;
}

#  _________________________________
# |                                 |
# |     Traitement principal        |
# |_________________________________|
#



# nom des fichier a cree
conf="conf_atos_dev.yml"
if [ "$1" != "" ]
then
	conf=$1
fi
listFile=`grep -E '^# *[a-zA-Z]' $conf | sed -e s/^#' '*//g | tr '\n' ';' | tr -s ';'`
# boucle des fichiers

i=1
tmpFile=`echo  $listFile | cut -d ';' -f $i`
while [ "$tmpFile" ] 
do
	i=`expr $i + 1`
	# print dealing file name
	tmpFile=`echo $tmpFile | sed -e s/'.yml'/'_template.yml'/g`
	echo -e "\n"$yellow"Generation du fichier template :\t" $green $tmpFile $NC"\n"
	var=`cat $conf | sed s/';'/'42\$42'/ | tr '\n' ';' | tr -s ';' |  cut -d '#' -f $i`
	var=`echo $var | cut -d ';' -f 2-999`
	get_rule $var
	#echo -e $rule
	b=`echo $tmpFile | sed s/_template//`
	c=`echo -e "sed" $rule $tmpFile " > ../"$b`
	#varo=`sed $rule $tmpFile > ../`echo $tmpFile | sed s/_template//``
	#echo -e $varo
	#echo -e $c
	eval "$c"
	tmpFile=`echo  $listFile | cut -d ';' -f $i`
done

