#!/bin/tcsh

if ( ${#argv} != 0 ) setenv exis_type `echo ${argv[1]} | tr '[FM]' '[fm]'`

# retrieve constants for scnum, existmpfilename
if ( ${?exis_type} == 1 ) then
  # if exis_type was provided, use it
  source setup_exis_quicklook_lasp.csh ${exis_type}
else
    # use default FM
  source setup_exis_quicklook_lasp.csh
endif

set tlmdir = /Volumes/home/exissdp/Downloads/latest_exis_tlm/

# loop forever
while ( 1 )

    echo "rsync from exissdp via $tlmdir"

    if ( ! -d ${tlmdir} ) then
	echo "ERROR: sync_tlm_from_zuulvm.csh - mount not found, Go->Connect to server and select home"
	exit 1
    endif

    rsync -av ${tlmdir}"?R_EXIS-L0_G${scnum}_s*nc" ${existmpdir}


    # recall quicklook reads the nc file directly withthe /LCR switch

    # purge old files
    purge_old_files:
    set allncfiles = `find ${existmpdir} -name "OR_EXIS-L0_G${scnum}*" | sort`
    set n_nc_files = ${#allncfiles}

    if ( $n_nc_files > 3 ) then
	rm $allncfiles[1]
	goto purge_old_files
    endif

    # sleep 10 seconds, repeat
    echo ""
    echo " ...waiting 10 seconds before checking for a new file..."
    
    sleep 10

end

exit 0

