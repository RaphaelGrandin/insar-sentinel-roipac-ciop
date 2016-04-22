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
while read master
do
    # report activity in log
	ciop-log "INFO" "Node A : Master: $master"
	slave="`ciop-getparam slave`"
	ciop-log "INFO" "Node A : Slave: $slave"
	polarization="`ciop-getparam polarization`"
        ciop-log "INFO" "Node A : polarization: $polarization"
	swathList="`ciop-getparam swathList`"
	ciop-log "INFO" "Node A : swathList: $swathList"

	#pass the aux reference to the next node
	#[ "$ref" != "" ] && echo "vor=$ref" | ciop-publish -s || exit $ERR_VOR
		
	# pass the SAR reference to the next node
	#echo "master=$master" | ciop-publish -s
        #echo "slave=$slave" | ciop-publish -s
        #echo "polarization=$polarization" | ciop-publish -s
        #echo "swathList=$swathList" | ciop-publish -s

	ciop-log "INFO" "NODE A TMPDIR : $TMPDIR"

	echo "master="$master"" > $TMPDIR/joborder
	echo "slave="$slave"" >> $TMPDIR/joborder
        echo "polarization="$polarization"" >> $TMPDIR/joborder
	echo "swathList="$swathList"" >> $TMPDIR/joborder
	ls  $TMPDIR/joborder
	cat  $TMPDIR/joborder	
	ciop-publish $TMPDIR/joborder
        echo "$TMPDIR/joborder" | ciop-publish -s


done

exit $SUCCESS
