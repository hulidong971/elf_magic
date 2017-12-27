#!/bin/sh

OBJCOPY_CMD=objcopy
READELF_CMD=readelf
MAGIC_FILE=magic.bin
MOD_DIR=${PWD}/modules

function update_magic()
{
	if [ ! -f $1 -o -L $1 ]
	then
		return
	fi
	${READELF_CMD} -h $1 >& /dev/null || return
	EXETYPE=0
	tmp=$(${READELF_CMD} -h $1 | grep "Type:" | grep "EXEC") && test -n tmp  && EXETYPE=1
	tmp=$(${READELF_CMD} -h $1 | grep "Type:" | grep "REL") && test -n tmp && EXETYPE=2
	if [ ${EXETYPE} -eq 0 ]
	then
		return
	fi
	tmp=$(${READELF_CMD} -s $1 | grep ".mymagic") && test -n tmp &&  EXETYPE=3
	if [ ${EXETYPE} -eq 3 ]
	then
		${OBJCOPY_CMD}  --remove-section  .mymagic $1
	fi
	${OBJCOPY_CMD}  --add-section .mymagic=${MAGIC_FILE} $1
}

function check_app_magic()
{
	DIR1=${PWD}/bin
 	DIR2=${PWD}/sbin
	for DIR in ${DIR1} ${DIR2}
	do
		for FILE in $(ls)
		do
			update_magic ${DIR}/${FILE}
		done
	done
}

function check_mod_magic()
{
	if [ -f $1 ]
	then
		update_magic $1
	fi
	if [ -d $1 ]
	then
		for FILE in $(ls $1)
		do
			check_mod_magic $1/${FILE}
		done
	fi
}

check_app_magic
check_mod_magic ${MOD_DIR}
