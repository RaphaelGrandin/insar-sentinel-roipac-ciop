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

# Loops over all inputs
while read masterList
do
    # report activity in log
	ciop-log "INFO" "Node A : Master: $masterList"
	slaveList="`ciop-getparam slave`"
	ciop-log "INFO" "Node A : Slave: $slaveList"
	polarization="`ciop-getparam polarization`"
        ciop-log "INFO" "Node A : polarization: $polarization"
	swathList="`ciop-getparam swathList`"
	ciop-log "INFO" "Node A : swathList: $swathList"


	echo "PATHDIR		$_CIOP_APPLICATION_PATH/ROI_PAC-Sentinel1" > $TMPDIR/topsar_param.in
	echo $masterList | awk 'BEGIN{FS=";"} {for(i=1;i<=NF;i++) printf("DIR_IMG_ante\t\t%s\n", $i)}' >> $TMPDIR/topsar_param.in
	echo $slaveList | awk 'BEGIN{FS=";"} {for(i=1;i<=NF;i++) printf("DIR_IMG_post\t\t%s\n", $i)}' >> $TMPDIR/topsar_param.in
	masterFile=`grep DIR_IMG_ante $TMPDIR/topsar_param.in | head -1 | awk '{print $2}'`
	dateMaster=`basename $masterFile | awk '{print substr($1,18,8)}'`
	slaveFile=`grep DIR_IMG_post $TMPDIR/topsar_param.in | head -1 | awk '{print $2}'`
	dateSlave=`basename $slaveFile | awk '{print substr($1,18,8)}'`
#	grep DIR_IMG_ante $TMPDIR/topsar_param.in | head -1 | awk '{print $2}'
#	grep DIR_IMG_ante $TMPDIR/topsar_param.in | head -1 | awk '{print $2}' | basename
#	grep DIR_IMG_ante $TMPDIR/topsar_param.in | head -1 | awk '{print $2}' | basename | awk '{print substr($1,18,8)}'
#	dateMaster=`grep DIR_IMG_ante $TMPDIR/topsar_param.in | head -1 | awk '{print $2}' | basename | awk '{print substr($1,18,8)}'`
#	dateSlave=`grep DIR_IMG_post $TMPDIR/topsar_param.in | head -1 | awk '{print $2}' | basename | awk '{print substr($1,18,8)}'`
	echo "LABEL_ante        $dateMaster" >> $TMPDIR/topsar_param.in
	echo "LABEL_post        $dateSlave" >> $TMPDIR/topsar_param.in
	cat $TMPDIR/topsar_param.in

	ciop-publish $TMPDIR/topsar_param.in

	#pass the aux reference to the next node
	#[ "$ref" != "" ] && echo "vor=$ref" | ciop-publish -s || exit $ERR_VOR
		
	# pass the SAR reference to the next node
	#echo "master=$master" | ciop-publish -s
        #echo "slave=$slave" | ciop-publish -s
        #echo "polarization=$polarization" | ciop-publish -s
        #echo "swathList=$swathList" | ciop-publish -s

	ciop-log "INFO" "NODE A TMPDIR : $TMPDIR"

	#echo "master="$master"" > $TMPDIR/joborder
	#echo "slave="$slave"" >> $TMPDIR/joborder
        #echo "polarization="$polarization"" > $TMPDIR/joborder
	echo $swathList | awk -v polarization=$polarization 'BEGIN{FS=";"} {for(i=1;i<=NF;i++) printf("swath=%s polarization=%s\n", $i, polarization)}' > $TMPDIR/joborder
	#echo "swathList="$swathList"" >> $TMPDIR/joborder
	ls  $TMPDIR/joborder
	cat  $TMPDIR/joborder	
	ciop-publish $TMPDIR/joborder
        #cat "$TMPDIR/joborder" | ciop-publish -s


done

exit $SUCCESS
