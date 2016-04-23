#!/bin/csh

echo "Arg 1 : " $1 >  toto.txt
echo "Arg 2 : " $2 >> toto.txt
echo "Arg 3 : " $3 >> toto.txt

pwd >> toto.txt
ls $1 >> toto.txt

