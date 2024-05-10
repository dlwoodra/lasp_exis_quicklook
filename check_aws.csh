#!/bin/tcsh

if ( ${#argv} != 0 ) setenv exis_type `echo ${argv[1]} | tr '[FM]' '[fm]'`

# retrieve constants for scnum, existmpfilename
if ( ${?exis_type} == 1 ) then
  # if exis_type was provided, use it
  source ~/exis/exis_quicklook_package_2021054/setup_exis_quicklook_lasp.csh ${exis_type}
else
    # use default FM
  source ~/exis/exis_quicklook_package_2021054/setup_exis_quicklook_lasp.csh
endif


# G16,17,18 are all the same format
set satstr = "geoproducts-ops/op/GOES-"$scnum

# G19 is different
if ( ${exis_type} == "fm4" ) set satstr = "geoproducts-plt/plt/GOES-19"


# loop forever
while ( 1 )

    echo "listing files on aws"

    set datestr=`date -u +%Y/%b/%Y%m%d | tr "JFMASOND" "jfmasond"`

    # currentfile has no path
    set currentfile=`aws s3 ls s3://${satstr}/l0/EXIS/${datestr}/ | grep nc | awk '{print $4}' | sort | tail -1`

    echo "found ${currentfile}"

    # does the file not exist locally
    if ( ! -e "${existmpdir}${currentfile}" ) then

	# retrieve this one file, takes about 7 seconds
	date
	echo ""
	echo "downloading $currentfile"

	aws s3 cp "s3://${satstr}/l0/EXIS/${datestr}/${currentfile}" "${existmpdir}"
	echo "file downloaded"
	echo ""

        # recall quicklook reads the nc file directly withthe /LCR switch

	# purge old files
	purge_old_files:
	set allncfiles = `find ${existmpdir} -name "OR_EXIS-L0_G${scnum}*" | sort`
	set n_nc_files = ${#allncfiles}
	#echo "n_nc_files = $n_nc_files"

	if ( $n_nc_files > 3 ) then
	    rm $allncfiles[1]
	    goto purge_old_files
	endif
    
	date
    else
	echo "latest file already processed"
    endif

    # sleep 10 seconds, repeat
    echo ""
    echo " ...waiting 10 seconds before checking for a new file..."
    
    sleep 10

end

exit 0

