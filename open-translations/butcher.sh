#!/bin/sh
LANG=${1:-no}
T=/tmp/security_is_for_the....$$

[ -d $LANG ] || {
	echo "Can't find lang dir $LANG"
	exit 1
}

echo "butchering $LANG"
for x in $LANG/*.po ; do
	python butcher.py $x $T
	mv $T $x
done
