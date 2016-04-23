#!/bin/bash

# source the ciop functions (e.g. ciop-log, ciop-getparam)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0

# add a trap to exit gracefully
function cleanExit ()
{
    local retval=$?
    local msg=""

    case $retval in
        $SUCCESS)    msg="Processing successfully concluded";;
        *)           msg="Error processing input";;
    esac
   
    [ $retval -ne 0 ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
    exit $retval
}

trap cleanExit EXIT

# create a shorter TMPDIR name for some ROI_PAC scripts/binaires
UUIDTMP="/tmp/`uuidgen`"
#ln -s $TMPDIR $UUIDTMP
mkdir ${UUIDTMP}
export TMPDIR=$UUIDTMP

ciop-log "DEBUG" "working in tmp dir [${TMPDIR}]"

mkdir -p $TMPDIR/data $TMPDIR/dem $TMPDIR/interf &> /dev/null


#cat > $TMPDIR/input


#inputFiles=`ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_A`
#ciop-log "INFO" "inputFiles $inputFiles"
#topsarFile=${inputFiles[0]}
#ciop-log "INFO" "topsarFile $topsarFile"

#for input in `cat $TMPDIR/input`
#do
#	ciop-log "INFO" "processing $input"
#	swath=`echo $input | sed "s/swath=//"`
#	polarization=`echo $input | sed "s/polarization//"`
#	ciop-log "INFO" "swath $swath"
#	ciop-log "INFO" "polarization $polarization"
#done

wps_result="$( ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_dem -w | tr -d '\r' | tr '\n' ';')"
ciop-log "DEBUG" "dem wps results 1 is ${wps_result}"
wps_result=`echo $wps_result | cut -d ";" -f 1`
ciop-log "DEBUG" "dem wps results is ${wps_result}"

# extract the result URL
#curl -L -o $TMPDIR/workdir/dem/dem.tgz "${wps_result}" 2> /dev/null
ciop-copy -O $TMPDIR/dem/ "${wps_result}"
#exit
#tar xzf $TMPDIR/workdir/dem/dem.tgz -C $TMPDIR/dem/
#[ "$?" != "0" ] && exit $ERR_NODEM

demFile="`find $TMPDIR/workdir/dem -name "*.dem"`"
ciop-log "INFO" "DEM : $demFile"



# import files from previous node
for input in `ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_A`
do 
	basefile=`basename $input`
	ciop-log "INFO" "using input from node_aux [${basefile}]"
	ciop-log "INFO" "input : $input"
	ciop-copy -O $TMPDIR /share/$input
	cat $TMPDIR/$basefile
	ls -l $TMPDIR/$basefile
done

cp $TMPDIR/topsar_param.in $TMPDIR/topsar_param_merge.in 

echo "WORKINGDIR	$TMPDIR" >> $TMPDIR/topsar_param_merge.in
echo "DEM		$demfile" >> $TMPDIR/topsar_param_merge.in
cat $TMPDIR/topsar_param_merge.in

ciop-publish $TMPDIR/topsar_param_merge.in

cd $TMPDIR

while read job; do
 	ciop-log "INFO" "job $job"
	swath=`echo $job | grep -o 'swath=[^ ]*' | cut -d "=" -f 2-`
	polarization=`echo $job | grep -o 'polarization=[^ ]*' | cut -d "=" -f 2-`
	ciop-log "INFO" "swath $swath"
	ciop-log "INFO" "polarization $polarization"
	#echo "$swath $polarization" | ciop-publish -s
	
	logFile="log_"`uuidgen`"_step-01.txt"
	csh $_CIOP_APPLICATION_PATH/ROI_PAC-Sentinel1/scripts/S1-ROI_PAC_01_stitch.csh $TMPDIR/topsar_param_merge.in $swath $polarization > $logFile
	cat $TMPDIR/$logFile
	ciop-log "INFO" "publishing log files"
	ciop-publish -m $TMPDIR/$logFile

done <$TMPDIR/joborder

exit

for job in `cat $TMPDIR/joborder`
do
	ciop-log "INFO" "job $job"
	swath=`cat $job | grep "swath=" | cut -d "=" -f 2-`
	polarization=`cat $job | grep "polarization=" | cut -d "=" -f 2-`
	ciop-log "INFO" "swath $swath"
	ciop-log "INFO" "polarization $polarization"
	#csh $_CIOP_APPLICATION_PATH/run.csh $swath $polarization
done

exit


# Loops over all inputs
for input in `ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_A`
do
	ciop-log "INFO" "retrieving $input"
	input=`ciop-copy -O $TMPDIR /share/$input`
	demfile=`cat $input | grep "dem=" | cut -d "=" -f 2-`
	ciop-log "INFO" "DEM is: $demfile [$CIOP_WF_RUN_ID]"
	slave=`cat $input | grep "slave=" | cut -d "=" -f 2-`
	ciop-log "INFO" "SLAVE is: $slave [$CIOP_WF_RUN_ID]"
	polarization=`cat $input | grep "polarization=" | cut -d "=" -f 2-`
        ciop-log "INFO" "POLARIZATION is: $polarization [$CIOP_WF_RUN_ID]"
	swathList=`cat $input | grep "swathList=" | cut -d "=" -f 2-`
        ciop-log "INFO" "SWATHLIST is: $swathList  [$CIOP_WF_RUN_ID]"

        ciop-log "INFO" "NODE B TMPDIR : $TMPDIR"

        echo "Node B master="$master"" > $TMPDIR/joborder_b
        echo "Node B slave="$slave"" >> $TMPDIR/joborder_b
        echo "Node B polarization="$polarization"" >> $TMPDIR/joborder_b
        echo "Node B swathList="$swathList"" >> $TMPDIR/joborder_b
        ls  $TMPDIR/joborder_b
        cat  $TMPDIR/joborder_b
        ciop-publish $TMPDIR/joborder_b
        echo "$TMPDIR/joborder_b" | ciop-publish -s


    # report activity in log
#    ciop-log "INFO" "Node B : The input file is: $inputfile"
#    slave="`ciop-getparam slave`"
#    ciop-log "INFO" "Node B : Slave: $slave"
done

exit $SUCCESS
