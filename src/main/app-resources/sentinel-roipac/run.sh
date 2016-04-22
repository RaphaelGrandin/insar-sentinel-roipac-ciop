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

# Loops over all inputs
for input in `ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_B`
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

        ciop-log "INFO" "NODE SENTINEL-ROIPAC TMPDIR : $TMPDIR"

    # report activity in log
#    ciop-log "INFO" "Node B : The input file is: $inputfile"
#    slave="`ciop-getparam slave`"
#    ciop-log "INFO" "Node B : Slave: $slave"
done

exit $SUCCESS
