#!/bin/csh

# Filename: setup_exis.csh
# 
# DLW 08/31/09 Initial setup for zuul
# DLW 07/27/10 Updated to work with zuul or any other computer
# DLW 12/05/11 Updated to add time drift directories
#
# $Id: setup_exis.csh 32948 2012-05-21 17:01:40Z dlwoodra $

#if ( ${HOST} != "zuul.lasp.colorado.edu" ) then
#    echo "ERROR: this host is "${HOST}
#    echo " You need to login to zuul.lasp.colorado.edu"
#    exit 1
#endif

#
# define EXIS environment type
#
setenv exis_type "sim"
#setenv exis_type "etu"
#setenv exis_type "fm1"
#setenv exis_type "hwp"
# valid types for exis_type are
#    sim : data simulator
#    hwp : hardware prototype
#    etu : engineering test unit (taped scraps to a table)
#    fm1 : first flight model
#    fm2 : second flight model

# allow command line override of environment type
if ( ${#argv} != 0 ) setenv exis_type ${argv[1]}

# define simulator directories
if ( ${HOST} != "zuul.lasp.colorado.edu" ) then
    # not zuul
    setenv exis_root /export/home/ops/goesr/quicklook/output_data
else
    # zuul
    setenv exis_root /goesr-work
endif

#
# define the top level data directory, use a different one for each type
#
setenv exis_data ${exis_root}/data/${exis_type}  #sim

setenv exis_data_tlm ${exis_data}/tlm

# quicklook data files
setenv exis_data_quicklook ${exis_data}/quicklook
setenv exis_data_l0b       ${exis_data}/l0b
setenv exis_data_l0b_xrs   ${exis_data_l0b}/xrs
setenv exis_data_l0b_sps   ${exis_data_l0b}/sps
setenv exis_data_l0b_euvsa ${exis_data_l0b}/euvsa
setenv exis_data_l0b_euvsb ${exis_data_l0b}/euvsb
setenv exis_data_l0b_euvsc ${exis_data_l0b}/euvsc
setenv exis_data_l0b_tdrift   ${exis_data_l0b}/tdrift

# GPA processed data
setenv exis_data_l1b          ${exis_data}/l1b
setenv exis_data_l1b_xrs      ${exis_data_l1b}/xrs
setenv exis_data_l1b_sps      ${exis_data_l1b}/sps
setenv exis_data_l1b_euvsa    ${exis_data_l1b}/euvsa
setenv exis_data_l1b_euvsb    ${exis_data_l1b}/euvsb
setenv exis_data_l1b_euvsc    ${exis_data_l1b}/euvsc
setenv exis_data_l1b_spectrum ${exis_data_l1b}/spectrum


setenv exis_code      ${exis_root}/code
setenv exis_code_sim  ${exis_code}/sim
setenv exis_code_gpds ${exis_code}/EXIS_level_1b

# if IDL_PATH is not defined, then define it
#if ( ${?IDL_PATH} == 0 ) setenv IDL_PATH "<IDL_DEFAULT>"

# instead, just enforce strictly limited paths
setenv IDL_PATH "<IDL_DEFAULT>"

# if the IDL_PATH environment variable does not have exis code, add it
if ( ${IDL_PATH} !~ *exis_code* ) then
    setenv IDL_PATH '+${exis_code}:'${IDL_PATH}
endif

setenv IDL_PATH '+'`pwd`':'${IDL_PATH}

setenv IDL_PATH ${IDL_PATH}":+${HOME}/projects/idldoc"

unalias cd
set prompt = "%S%s%B%UEXIS_${exis_type}>%u%b "

exit (0)
