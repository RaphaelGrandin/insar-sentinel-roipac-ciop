#!/bin/bash

# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_AUX=4
ERR_VOR=6
ERR_INVALIDFORMAT=2
ERR_NOIDENTIFIER=5
ERR_NODEM=7


# add a trap to exit gracefully
function cleanExit ()
{
    local retval=$?
    local msg=""
    case "$retval" in
        $SUCCESS) msg="Processing successfully concluded";;
        $ERR_AUX) msg="Failed to retrieve auxiliary products";;
        $ERR_VOR) msg="Failed to retrieve orbital data";;
        $ERR_INVALIDFORMAT) msg="Invalid format must be roi_pac or gamma";;
        $ERR_NOIDENTIFIER) msg="Could not retrieve the dataset identifier";;
        $ERR_NODEM) msg="DEM not generated";;
        *) msg="Unknown error";;
    esac

    [ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
    exit $retval
}

trap cleanExit EXIT

# create a shorter TMPDIR name for some ROI_PAC scripts/binaires
UUIDTMP="/tmp/`uuidgen`"
#ln -s $TMPDIR $UUIDTMP
mkdir ${UUIDTMP}
export TMPDIR=$UUIDTMP

ciop-log "DEBUG" "working in tmp dir [${TMPDIR}]"

# prepare ROI_PAC environment variables
export INT_BIN=/usr/bin/
export INT_SCR=/usr/share/roi_pac
export PATH=${INT_BIN}:${INT_SCR}:${PATH}

cat > $TMPDIR/input

# create environment
mkdir -p $TMPDIR/workdir/data $TMPDIR/workdir/dem $TMPDIR/workdir/interf &> /dev/null
ls $TMPDIR/workdir/interf
echo $TMPDIR

export DATDIR=$TMPDIR/workdir/data
export DEMDIR=$TMPDIR/workdir/dem
export ORBDIR=$TMPDIR/workdir/interf/ORB
export SLCDIR=$TMPDIR/workdir/interf/SLC
export INTDIR=$TMPDIR/workdir/interf/INT

#main
while read master
do
	ciop-log "INFO" "Master: $master"
	slave="`ciop-getparam slave`"
	ciop-log "INFO" "Slave: $slave"
	#runAux $master
	#resMaster=$?
	#[ "$resMaster" -ne 0 ] && exit $resMaster
	#runAux $slave
	#resSlave=$?
	#exit $resSlave
done


# get all SAR products
# for input in `cat $TMPDIR/input | grep 'sar='`
# do
#     sar_url=`echo $input | sed "s/^sar=//"`
#
#     # get the date in format YYMMDD
#     sar_date=`opensearch-client $sar_url startdate | cut -c 3-10 | tr -d "-"`
#     sar_date_short=`echo $sar_date | cut -c 1-4`
#
#     ciop-log "DEBUG" "SAR input ${sar_url}"
#     ciop-log "INFO" "SAR date: $sar_date and $sar_date_short"
#
#     # get the dataset identifier
#     sar_identifier=`opensearch-client $sar_url identifier`
#     ciop-log "INFO" "SAR identifier: $sar_identifier"
#
#     sar_folder=$DATDIR
#
#     # get Sentinel-1 SAFE products
#     sar_url=`opensearch-client $sar_url enclosure`
#     sar="`ciop-copy -o $sar_folder $sar_url`"
#
# done

ciop-log "INFO" "Import of Sentinel-1 SAFE folder complete."


ciop-log "INFO" "That's all folks"
