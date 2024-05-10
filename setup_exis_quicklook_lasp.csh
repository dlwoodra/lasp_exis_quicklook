#!/bin/csh

# Filename: setup_exis_quicklook_nsof.csh
# 
# DLW 12/05/11 Updated to add time drift directories
# DLW 10/27/15 Updated for delivery
# DLW 06/28/16 Updated to add umask 000
#
# $Id: setup_exis_quicklook_nsof.csh 80205 2018-04-06 18:46:29Z dlwoodra $

umask 000

#
# define EXIS environment type
#
setenv exis_type "fm3"
# valid types for exis_type are
#    sim : data simulator
#    hwp : hardware prototype
#    etu : engineering test unit (taped scraps to a table)
#    fm1 : first flight model (GOES-R)
#    fm2 : second flight model (GOES-S)
#    fm3 : second flight model (GOES-T)
#    fm4 : second flight model (GOES-U)
# allow command line override of environment type
if ( ${#argv} != 0 ) setenv exis_type `echo ${argv[1]} | tr '[FM]' '[fm]'`

# define temporary dir and filename
setenv existmpdir ${HOME}/tmpdata/
setenv existmpfilename ${existmpdir}`whoami`_exis_${exis_type}_tmp_tlmfile

if ( ! -e ${existmpdir} ) mkdir ${existmpdir} # create it if needed

if ( ${exis_type} == "fm1" ) setenv scnum 16
if ( ${exis_type} == "fm2" ) setenv scnum 17
if ( ${exis_type} == "fm3" ) setenv scnum 18
if ( ${exis_type} == "fm4" ) setenv scnum 19

echo " Setup for "${exis_type}" - GOES-"${scnum}

# define directory hierarchy
setenv exis_root `pwd`

#
# define the top level data directory, use a different one for each type
#
#setenv exis_data ${exis_root}/data/${exis_type}

setenv exis_cal_data ${exis_root}/cal/${exis_type}

#setenv exis_data_tlm ${exis_data}/tlm

## quicklook data files
#setenv exis_data_quicklook ${exis_data}/quicklook
#setenv exis_data_l0b       ${exis_data}/l0b
#setenv exis_data_l0b_xrs   ${exis_data_l0b}/xrs
#setenv exis_data_l0b_sps   ${exis_data_l0b}/sps
#setenv exis_data_l0b_euvsa ${exis_data_l0b}/euvsa
#setenv exis_data_l0b_euvsb ${exis_data_l0b}/euvsb
#setenv exis_data_l0b_euvsc ${exis_data_l0b}/euvsc
#setenv exis_data_l0b_tdrift   ${exis_data_l0b}/tdrift

setenv exis_code      ${exis_root}/code

# enforce strictly limited paths
setenv IDL_PATH "<IDL_DEFAULT>:+${PWD}"

unalias cd
set prompt = "%S%s%B%UEXIS_${exis_type}>%u%b "

exit 0
