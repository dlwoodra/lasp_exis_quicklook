; docformat = 'rst'

;+
; :Author:
;    Don Woodraska
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
; 
; :Version:
;    $Id$
;
;  Use 'svn propset svn:keywords "Id" thisfilename.pro' to enable substitution.
;
;  Other file tags include hidden, history, private, property, properties,
;  refer to the help link in the documentation for more info.
;
;  This is the bottom of the file header comment and ends with semicolon minus
;-

;+
; This procedure compares the environment variable exis_type for consistency
; with the value of the user_flags.fm_designator. This stops if there is a
; mismatch when files would be written to disk.
;
; :Params:
;    apid: in, required, type=int
;       The 11-bit value from the primary CCSDS Header. Only SPS, XRS,
;       EUVS-A, EUVS-B, the 8th EUVS-C, and time drift APIDs are
;       compared. All other APIDs are not checked.
;    tlm_fm: in, required, type=byte
;       The 8-bit value of user flags for the FM. The known values are
;       1=FM1, 2=FM2, 3=FM3,4=FM4,255=SIM. Other values that may be found 
;       are 208=dev board, 224=etu, 225-227=exise1,2,3, 241,241=fsde1,2
;
; :Keywords:
;    do_files : in, optional, type=boolean
;        If set, then output files would be produced. Used to short circuit
;        evaluation and return faster.
;
; :Examples:
;    Pass in the byte from teh decomposed fm_designator in the user flags.
;       IDL> check_tlm_env_fm_consistency, user_flags.fm_designator, do_files=do_files
;
;    There is no result. This programs halts execution or continues.
;
;-
pro check_tlm_env_fm_consistency, apid, tlm_fm, do_files=do_files

  ;Only check packets known to contain a valid tlm_fm
  ;whitelist=[899,908,905,925,903,929,901]
  ;               SPS,    XRS,   EUVSA,   EUVSB,  EUVSC7,  tdrift
  whitelist=['03a0'xL,'03a1'xL,'03a2'xL,'03a3'xL,'03b7'xL,'388c'xL]
  w=where(apid eq whitelist,count)
  if count ne 1 then return

  ;tlm_fm = fix(user_flags.fm_designator) ; from telemetry

  if do_files eq 0 then return

  the_type = getenv('exis_type')

  ; we only care about mismatched tlm if results are stored in files
  ; it's ok to run any telemetry in any FM env as long as
  ; do_files is in the reset state(value=0)
  case the_type of
     'fm1':  env_fm=1
     'fm2':  env_fm=2
     'fm3':  env_fm=3
     'fm4':  env_fm=4
     'etu':  env_fm=8     ;6-MAR-2015: Changed to '8'
;     'etu':  env_fm=15     ;11-MAR-2013: Changed to '15'
     'sim':  env_fm=255
     else: begin
        print,'ERROR: unknown environment variable for exis_type :'+the_type
        stop
     endelse
  endcase
  if (tlm_fm ne env_fm) then begin
     ;Warn and stop on non-Nick packets with wrong FM - see notebook 10/2/2012
     ;print,'unexpected fm number, expected '+getenv('exis_type')+' saw ',tlm_fm

     print,'The FM value in telemetry does not match the environment.'
     print,' Check that setup_exis... was sourced properly for the right FM'
     print,' env = '+getenv('exis_type')
     print,' sec hdr fm = ',tlm_fm
     print,''
     print,' stopping'

     stop

  endif

return
end
