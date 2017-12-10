#!/bin/bash
PRGPATH=$0
PRG=$(basename $0)
PRGBASE=$(basename $0 .sh)
SRC=$1
DEST=$2

usage() {
	# echo "Usage: clone-user src_user_name new_user_name"
	echo "Usage: $PRG src_user_name new_user_name"
	echo "  src_user_name - Specify user to copy from (must exist)"
	echo "  new_user_name - Specify new user to clone (must NOT exist already)"
	echo
}	

T1=`echo $SRC | tr [:upper:] [:lower:]`
if [ "$T1" = "-help" -o "$T1" = "--help" -o "$T1" = "-h" -o "$T1" = "/h" -o  "$T1" = "/?" ]
then
	usage
	exit 9
fi

if [ $# -ne 2 ]; then
	echo "$PRG: Error: ${PRG} wants two arguments (and only two)"
	echo
	usage
	exit 1
fi

if !(grep -q "^${SRC}:" /etc/passwd); then
	echo "$PRG: Error: ${SRC} user does not exist"
	echo
	usage
	exit 1
fi
if (grep -q "^${DEST}:" /etc/passwd); then
	echo "$PRG: Error: ${DEST} user already exists (IT MUST NOT BE THERE!)"
	echo
	usage
	exit 1
fi

SRC_GROUPS=$(id -Gn ${SRC} | sed "s/\<${SRC}\> //g" | sed "s/ \<${SRC}\>//g" |sed "s/ /,/g")
SRC_SHELL=$(awk -F : -v name=${SRC} '(name == $1) { print $7 }' /etc/passwd)

useradd --groups ${SRC_GROUPS} --shell ${SRC_SHELL} --create-home ${DEST}
passwd ${DEST}
