#!/bin/bash
#For i in {1..11}
#Do
#    for f in traces/New_Traces/SAMPLE$i/*
#COUNTER=0
#    for i in {1000...4000..200}
#   do
#        #echo $f
#        onlyFile=$(basename $f)
#	COUNTER=$[COUNTER+1]
#	#echo $COUNTER
#	#echo $onlyFile
#        dirStr="./$1u/"
##        dirStr="./traces/windowTraces/SAMPLE1/"
##        echo $f'writing to'$dirStr$onlyFile
#        cp "$i"u/metadata.csv "$i"u/metadata_"$i".csv
#    done
###done
ARRAY=(CP64 WM32 WM64 CONSTANT_RATIO)

for i in {0..3}
do
for f in ${ARRAY[$i]}/*
do
echo "python adjacency_matrix.py $f"
python adjacency_matrix.py $f
done
done
