#!/bin/csh

#
# This shell script starts the quicklook software.
#

# retrieve constants for scnum, existmpfilename
if ( ${?exis_type} == 1 ) then
  # if exis_type is already set, keep it
  source setup_exis_quicklook_lasp.csh ${exis_type}
else
  source setup_exis_quicklook_lasp.csh
endif

setenv searchdir ${existmpdir}

# adding a 0.1 second delay to each sps packet (valid range is 0 to 0.25)
idl -e exis_quicklook,'"'${existmpfilename}'",/LCR,/no_files,slowFileReplay=0.1'

exit 0
