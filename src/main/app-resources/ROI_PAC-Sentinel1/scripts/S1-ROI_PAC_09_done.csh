#!/bin/csh

####################################################
###   Sentinel-1 pre-processor for ROI_PAC
###   Raphael Grandin (IPGP)  -- April 2016
###   grandin@ipgp.fr
####################################################
### STEP 9
### Geocode the resulting interferogram
### Run ROI_PAC up to "done"
####################################################


# # # # # # # # # # # # # # # # # # #
# # Interpret the parameter file  # #

### Read parameter file
if ($#argv <= 2) then
    echo "Usage: $0 topsar_input_file.in iw1 hh"
    exit
endif
if ( ! -e $1 ) then
    echo "Input file not found ! Exit .."
    exit
else
    set topsar_param_file=$1
endif
set num_lines_param_file=`(wc $topsar_param_file | awk '{print $1}')`
if ( $num_lines_param_file == 0 ) then
    echo "Input file empty ! Exit .."
    exit
endif

### Read parameters
@ count = 1
set DIR_IMG_ante=""
set DIR_IMG_post=""
while ( $count <= $num_lines_param_file )
	set linecurrent=`(awk 'NR=='$count' {print $0}' $topsar_param_file)`
	set fieldname=`(echo $linecurrent | awk '{print $1}')`
	set fieldcontent=`(echo $linecurrent | awk '{print $2}')`
	if ( $fieldname == "WORKINGDIR" ) then
		set WORKINGDIR=$fieldcontent
	else if ( $fieldname == "DIR_ARCHIVE" ) then
		set DIR_ARCHIVE=$fieldcontent
	else if ( $fieldname == "DIR_IMG_ante" ) then
		set DIR_IMG_ante= ( $DIR_IMG_ante $fieldcontent )
	else if ( $fieldname == "DIR_IMG_post" ) then
		set DIR_IMG_post= ( $DIR_IMG_post $fieldcontent )
	else if ( $fieldname == "DEM" ) then
		set DEM=$fieldcontent
	else if ( $fieldname == "DEM_low" ) then
		set DEM_low=$fieldcontent
	else if ( $fieldname == "LABEL_ante" ) then
		set LABEL_ante=$fieldcontent
	else if ( $fieldname == "LABEL_post" ) then
		set LABEL_post=$fieldcontent
	else if ( $fieldname == "PATHDIR" ) then
		set dir=$fieldcontent
	else if ( $fieldname == "LOOKS_RANGE" ) then
		set LOOKS_RANGE=$fieldcontent
	else if ( $fieldname == "LOOKS_AZIMUTH" ) then
		set LOOKS_AZIMUTH=$fieldcontent
	else
		#echo "Unknown field : "$linecurrent
	endif
	@ count ++
end


### Verify that all the necessary variables are defined
if ( ! $?WORKINGDIR ) then
        echo "Field WORKINGDIR is empty ! Exit .."
        exit
endif
if ( ! $?DIR_ARCHIVE ) then
        echo "Field DIR_ARCHIVE is empty ! Exit .."
        exit
endif
if ( ! $?dir ) then
        echo "Field PATHDIR is empty ! Exit .."
        exit
endif
if ( ! $?DIR_IMG_ante ) then
        echo "Field DIR_IMG_ante is empty ! Exit .."
        exit
endif
if ( ! $?DIR_IMG_post ) then
        echo "Field DIR_IMG_post is empty ! Exit .."
        exit
endif
if ( ! $?LABEL_ante ) then
        echo "Field LABEL_ante is empty ! Exit .."
        exit
endif
if ( ! $?LABEL_post ) then
        echo "Field LABEL_post is empty ! Exit .."
        exit
endif
if ( ! $?DEM ) then
        echo "Field DEM is empty ! Exit .."
        exit
endif
if ( ! $?DEM_low ) then
        echo "Field DEM_low is empty ! Exit .."
        exit
endif

### Set number of looks to default values, if needed
if ( ! $?LOOKS_RANGE ) then
        set LOOKS_RANGE = 12
endif
if ( ! $?LOOKS_AZIMUTH ) then
        set LOOKS_AZIMUTH = 4
endif
if ( ! $?SKIP_BEG_ante ) then
        set SKIP_BEG_ante = 0
endif
if ( ! $?SKIP_BEG_post ) then
        set SKIP_BEG_post = 0
endif
if ( ! $?SKIP_END_ante ) then
        set SKIP_END_ante = 0
endif
if ( ! $?SKIP_END_post ) then
        set SKIP_END_post = 0
endif



set num_files_ante=$#DIR_IMG_ante
set num_files_post=$#DIR_IMG_post

#if ( $num_files_ante != $num_files_post ) then
#    echo "Number of files for ante and post images must be the same ! Exit .."
#    exit
#else
#    set num_files=$num_files_ante
#endif

echo "WORKINGDIR       "$WORKINGDIR
echo "DIR_ARCHIVE      "$DIR_ARCHIVE

@ scene = 1
while ( $scene <= $num_files_ante )
    echo "DIR_IMG_"$scene " ; ante : " $DIR_IMG_ante[$scene]
    @ scene ++
end
@ scene = 1
while ( $scene <= $num_files_post )
    echo "DIR_IMG_"$scene " ; post : "  $DIR_IMG_post[$scene]
    @ scene ++
end

set strip_list=""
set strip_list=$argv[2]
echo "Strip list : " $strip_list
@ num_strips = 1

set polar_list=$argv[3]
echo "Polar list : " $polar_list


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # Resume ROI_PAC processing and follow up to unwrapping step

# normally this directory should exist
if ( ! -e $WORKINGDIR/INTERFERO ) then
	echo "Directory "INTERFERO" does not exist!"
	echo "Something is wrong."
	echo "Exit..."
	exit
endif

@ count_strip = 1
while ( $count_strip <= $num_strips )
    set strip=$strip_list[$count_strip]
    set polar=$polar_list[$count_strip]

    echo strip $strip polar $polar

	cd $WORKINGDIR/INTERFERO

	# normally this directory should exist
	if ( ! -e $WORKINGDIR/INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar} ) then
		echo "Directory "INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar}" does not exist!"
		echo "Something is wrong."
		echo "Exit..."
		exit
	endif

	# # Go back to the processing directory
	cd $WORKINGDIR/INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar}

	# We need to re-write the .proc file to use the coarser DEM
	# (the coarser DEM is there to make the geocoding more efficient)
	rm -f int.proc
	echo SarDir1=$WORKINGDIR/INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante} >> int.proc
    echo SarDir2=$WORKINGDIR/INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_post} >> int.proc
    echo IntDir=$WORKINGDIR/INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/INT >> int.proc
	# the coarse DEM is used here
    echo "DEM="$DEM_low  >> int.proc
    echo Rlooks_int=1 >> int.proc
    echo Rlooks_sim=1 >> int.proc
	echo Rlooks_unw=$LOOKS_RANGE >> int.proc
    echo pixel_ratio=1 >> int.proc
    echo MakeRawOrbitType=HDR >> int.proc
    echo OrbitType=HDR >> int.proc
    echo flattening=orbit >> int.proc
	# for now, these values are hardcoded
    echo FilterStrength=0.9 >> int.proc
    echo Filt_method=adapt_filt >> int.proc
    echo sigma_thresh=0.9 >> int.proc
    echo UnwrappedThreshold=0.2 >> int.proc
	
    set offset_guess_x=`(awk '{if($5>10) print $2}' $WORKINGDIR/CORREL/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante}-${LABEL_post}_${strip}_${polar}_ampcor_gross.off | sort -n | awk ' { a[i++]=$1; } END { print a[int(i/2)]; }')`
    set offset_guess_y=`(awk '{if($5>10) print $4}' $WORKINGDIR/CORREL/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante}-${LABEL_post}_${strip}_${polar}_ampcor_gross.off | sort -n | awk ' { a[i++]=$1; } END { print a[int(i/2)]; }')`
    echo x_start=$offset_guess_x >> int.proc
    echo y_start=$offset_guess_y >> int.proc

	# # Do the geocoding
	rm -fr INT/geo_${LABEL_ante}-${LABEL_post}.unw
	process_2pass.pl int.proc unwrapped done >>& log_process2pass_${LABEL_ante}-${LABEL_post}_${strip}_${polar}.txt

	## Geocode incidence file

	# prepare incidence and squint files
	#cd $WORKINGDIR/SLC/${LABEL_ante}-${LABEL_post}_${strip}_${polar}
	#set XSIZE_SLC=`(grep WIDTH ${LABEL_ante}_${strip}_${polar}.slc.rsc | awk '{print $NF}')`
	#cpx2mag_phs ${LABEL_ante}_${strip}_${polar}.slc     mag /dev/null $XSIZE_SLC
	#rmg2mag_phs ${LABEL_ante}_${strip}_${polar}_los.unw inc squ       $XSIZE_SLC
        #mag_phs2rmg mag inc ${LABEL_ante}_${strip}_${polar}_inc.unw  $XSIZE_SLC
        #mag_phs2rmg mag squ ${LABEL_ante}_${strip}_${polar}_squ.unw  $XSIZE_SLC
        #cp -f ${LABEL_ante}_${strip}_${polar}.slc.rsc ${LABEL_ante}_${strip}_${polar}_inc.unw.rsc
        #cp -f ${LABEL_ante}_${strip}_${polar}.slc.rsc ${LABEL_ante}_${strip}_${polar}_squ.unw.rsc
	#echo "RLOOKS                                       1" >> ${LABEL_ante}_${strip}_${polar}_inc.unw.rsc
        #echo "ALOOKS                                       1" >> ${LABEL_ante}_${strip}_${polar}_inc.unw.rsc
        #echo "RLOOKS                                       1" >> ${LABEL_ante}_${strip}_${polar}_squ.unw.rsc
        #echo "ALOOKS                                       1" >> ${LABEL_ante}_${strip}_${polar}_squ.unw.rsc
	#rm -fr ${LABEL_ante}_${strip}_${polar}_inc_${LOOKS_RANGE}rlks.unw
	#rm -fr ${LABEL_ante}_${strip}_${polar}_squ_${LOOKS_RANGE}rlks.unw
	#look.pl ${LABEL_ante}_${strip}_${polar}_inc.unw $LOOKS_RANGE $LOOKS_AZIMUTH
        #look.pl ${LABEL_ante}_${strip}_${polar}_squ.unw $LOOKS_RANGE $LOOKS_AZIMUTH
#
#
	## cleanup
	#rm -f mag inc squ ${LABEL_ante}_${strip}_${polar}_inc.unw ${LABEL_ante}_${strip}_${polar}_squ.unw
#
	## do the geocoding
	#cd $WORKINGDIR/INTERFERO/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/INT
	#ln -sf $WORKINGDIR/SLC/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante}_${strip}_${polar}_inc_${LOOKS_RANGE}rlks.unw .
	#cp -f  $WORKINGDIR/SLC/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante}_${strip}_${polar}_inc_${LOOKS_RANGE}rlks.unw.rsc .
        #ln -sf $WORKINGDIR/SLC/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante}_${strip}_${polar}_squ_${LOOKS_RANGE}rlks.unw .
        #cp -f  $WORKINGDIR/SLC/${LABEL_ante}-${LABEL_post}_${strip}_${polar}/${LABEL_ante}_${strip}_${polar}_squ_${LOOKS_RANGE}rlks.unw.rsc .
	#rm -f geo_${LABEL_ante}_${strip}_${polar}_inc.unw
	#rm -f geo_${LABEL_ante}_${strip}_${polar}_squ.unw
	#geocode.pl geomap_${LOOKS_RANGE}rlks.trans ${LABEL_ante}_${strip}_${polar}_inc_${LOOKS_RANGE}rlks.unw geo_${LABEL_ante}-${LABEL_post}_${strip}_${polar}_inc.unw
        #geocode.pl geomap_${LOOKS_RANGE}rlks.trans ${LABEL_ante}_${strip}_${polar}_squ_${LOOKS_RANGE}rlks.unw geo_${LABEL_ante}-${LABEL_post}_${strip}_${polar}_squ.unw

	@ count_strip ++
end

exit


# * Copyright (C) 2016 R.GRANDIN
# #
# # * grandin@ipgp.fr
# #
# # * This file is part of "Sentinel-1 pre-processor for ROI_PAC".
# #
# # *    "Sentinel-1 pre-processor for ROI_PAC" is free software: you can redistribute
# #      it and/or modify it under the terms of the GNU General Public License
# # 	 as published by the Free Software Foundation, either version 3 of
# # 	 the License, or (at your option) any later version.
# #
# # *    "Sentinel-1 pre-processor for ROI_PAC" is distributed in the hope that it
# #      will be useful, but WITHOUT ANY WARRANTY; without even the implied
# # 	 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# # 	 See the GNU General Public License for more details.
# #
# # *     You should have received a copy of the GNU General Public License
# #      along with "Sentinel-1 pre-processor for ROI_PAC".
# # 	 If not, see <http://www.gnu.org/licenses/>.
#
