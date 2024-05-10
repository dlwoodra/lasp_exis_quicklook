; docformat = 'rst'

;+
; :Author:
;    Don Woodraska
;
; :Version:
;    $Id: read_goes_l0b_day.pro 77457 2016-12-07 18:18:23Z dlwoodra $
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado. 
;    All rights reserved. This software was developed at the 
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;
;-

;+
; Convert the CCSDS secondary header into a microseconds counter since Jan 1 2000 at 12:00:00 UTC
; 
; :Params:
;    packetarray: in, required, type="structure array"
;      Array (or scalar) of decomposed packets containing tags names sec_hdr_microsec, sec_hdr_millisec, and sec_hdr_day
;
; :Returns:
;    64-bit unsigned long array of microseconds (LSB is 1 microsecond)
; 
; :Examples:
;    Read some data.::
;       IDL> packets = read_goes_l0b_file(filenamestring)
;
;    Now create a microsecond counter for each packet.::
;       IDL> microsec = get_microsecond_counter_from_packet_header( packets )
;
;-
function get_microsecond_counter_from_packet_header, packetarray
  microsec =   ulong64(packetarray.sec_hdr_microsec)
  microsec += (ulong64(packetarray.sec_hdr_millisec)*1000ULL)
  microsec += (ulong64(packetarray.sec_hdr_day)*86400ULL*1000000ULL)
  return, microsec
end

;+
; Merge results for two files of packets together. Most of the time multiple data files are created when 
; the SDP operator halts the quicklook processing to push data to the offsite server. Sometimes it's caused 
; by the OASIS operator taking OIS down. Regardless, the usual case involves non-overlapping data. These 
; results are just concatenated together. However, after reprocessing from OIS raw record files, you can 
; get complete overlap and occasionally gaps filled. This function finds data from the second argument 
; that extends prior to, or after, the first argument and prepends or appends accordingly. For this 
; reason, the most complete array of structure should be the first one. If the data is very intermittent 
; (not observed yet) then reprocessing should be done from OIS raw record files. Because of the ISIS bug 
; that can cause time to jump backwards, or pause, the time seems to be unique but is not guaranteed to be 
; monotonically increasing. 
; 
; :Params:
;    refdata_in: in, required, type="structure array"
;      Array (or scalar) of decomposed packets containing tags names sec_hdr_microsec, sec_hdr_millisec, and sec_hdr_day
;    filedata_in: in, required, type="structure array"
;      Array (or scalar) of decomposed packets containing tags names sec_hdr_microsec, sec_hdr_millisec, and sec_hdr_day
;
; :Returns:
;    Array of merged structures
;
; :Uses:
;    get_microsecond_counter_from_packet_header
;  
;-
function merge_refdata_filedata_private, refdata_in, filedata_in

  refdata  =  refdata_in
  filedata = filedata_in

  refmicro  = long64(get_microsecond_counter_from_packet_header( refdata ))
  filemicro = long64(get_microsecond_counter_from_packet_header( filedata ))

  ; note that we are forcing signed 64-bit integers so we can use 
  ; them directly to calculate differences and get negative values
  ; this clips the positive range to 2^63-1 (around year 29,4471)
  ; so this is not a real limit that can be practically reached

  if refmicro[n_elements(refmicro)-1] lt filemicro[0] then begin
     ; there is no overlap, append filedata and return
     result = [refdata, filedata]
     return, result
  endif else begin
     if filemicro[n_elements(filemicro)-1] lt refmicro[0] then begin
        ; there is no overlap, prepend filedata and return
        result = [filedata, refdata]
        return,result
     endif
  endelse
  
  result = refdata

  ; after reprocessing, there is always overlap
  pre = where(filemicro lt refmicro[0],n_pre)
  if n_pre gt 0 then result = [filedata[pre], result] ; prepend

  post = where(filemicro gt refmicro[n_elements(refmicro)-1],n_post)
  if n_post gt 0 then result = [result, filedata[post]] ; append

  return, result

return,refdata
end

;+
; Read all of the files of a specified component for one UT day.
; The type of data (SIM, ETU, FM1, etc) is dictated by the $exis_data
; environment variable. This environment variable is set by setup_exis.csh.
;
; :Examples:
;    For example::
; 
;       IDL> sps   = read_goes_l0b_day( 2012104, /sps )
;       IDL> xrs   = read_goes_l0b_day( 2012104, /xrs )
;       IDL> euvsa = read_goes_l0b_day( 2012104, /euvsa )
;       IDL> euvsb = read_goes_l0b_day( 2012104, /euvsb )
;       IDL> euvsc = read_goes_l0b_day( 2012104, /euvsc )
;
; :Uses:
;    read_goes_l0b_file, merge_refdata_filedata_private
;
; :Returns:
;    Array of data structures with one structure for line of data in each file.
;
; :Params:
;    yyyydoy : in, required, type=long
;      a 4-digit year and a 3-digit day of year
;
; :Keywords:
;    sps : in, optional, type=boolean
;      Set to read all files for the SPS component for the day.
;      This is the default option if no other keywords are set.
;    xrs : in, optional, type=boolean
;      Set to read all files for the XRS component for the day.
;      This overrides the SPS keyword.
;    euvsa : in, optional, type=boolean
;      Set to read all files for the EUVSA component for the day.
;      This overrides the SPS and XRS keywords.
;    euvsb : in, optional, type=boolean
;      Set to read all files for the EUVSB component for the day.
;      This overrides the SPS, XRS, and EUVSA keywords.
;    euvsc : in, optional, type=boolean
;      Set to read all files for the EUVSC component for the day.
;      This overrides the SPS, XRS, EUVSA and EUVSB keywords.
;    apid146 : in, optional, type=boolean
;      Set to read all files for the APID146  for the day.
;      This overrides the SPS, XRS, EUVSA, EUVSB, and EUVSC keywords.
;    status : out, optional, type=integer
;      Returns 0 for success, non-zero for no data found
;    
;
;-
function read_goes_l0b_day, yyyydoy, sps=sps, xrs=xrs, $
                            euvsa=euvsa, euvsb=euvsb, euvsc=euvsc, $
                            apid146=apid146, $
                            status=status
opstatus=-1

; assume sps
type='sps'
if keyword_set(xrs) then type='xrs'
if keyword_set(euvsa) then type='euvsa'
if keyword_set(euvsb) then type='euvsb'
if keyword_set(euvsc) then type='euvsc'
if keyword_set(apid146) then type='apid146'

stryd = string(yyyydoy/1000L,form='(i4.4)') + '/' + $
  string(yyyydoy mod 1000L,form='(i3.3)')

p = getenv('exis_data')+'/l0b/'+type+'/'+stryd+'/'

; leave a space at the end of checksumcmd so files can be appended
trailercmd=''
case !version.os of
   'linux': checksumcmd = '/usr/bin/md5sum ' ; linux
   'darwin': checksumcmd = '/sbin/md5 ' ; mac
   'Win32': begin
      checksumcmd = 'CertUtil -hashfile ' ; windows
      trailercmd = ' MD5 | findstr /R /V /C:"[MC][De][5r]"'
      ; the certutil returns 3 lines, discard the first and last
   end
   else: checksumcmd = '/usr/bin/md5sum ' ; assume linux-like
endcase

for hh=0,23 do begin

   ; filename pattern has the form component_yyyydoy_hh_vvv.txt
   ; component is xrs, sps, euvsa, euvsb, euvsc, or tdrift
   ; yyyydoy is the 7-digit year and day of year (day ranges from 1-366 inclusive)
   ; hh is a 2-digit integer hour from 0-23 inclusive
   ; vvv is a cycle number that is incremented if quicklook detects a previous file for that hour

   filepatt = '*_'+strtrim(yyyydoy,2)+'_'+string(hh,form='(i2.2)')+'_???.txt*' ; this hour only, all versions

   files = file_search(p+filepatt,count=filecount)

   ; skip any files that have identical checksums
   if filecount gt 1 then begin
      ; calculate a checksum on each file
      ;cmd = '/usr/bin/cksum '+files      ; array of commands
      ;cmd = '/usr/bin/md5sum '+files      ; array of commands
      cmd = checksumcmd+files+trailercmd      ; array of commands
      farr = strarr(filecount)  ; string array to hold the checksum results
      for ifile=0L,filecount-1 do begin
         spawn, cmd[ifile], result ; call linux tool to calculate the file checksum
         farr[ifile] = strjoin(strsplit(result[0],' ',/extract)) ; remove any spaces
      endfor
      ; trim off duplicate files that have identical checksums
      ;chksum    = strmid(farr,0,10)  ; checksum result
      chksum    = strmid(farr,0,32)  ; MD5 result
      keepidx   = uniq( chksum, sort(chksum) ) ; array of indices with unique checksums
      files     = files[keepidx]
      filecount = n_elements(files)

      ; read highest versions first since those are most complete
      ; after reprocessing, so reverse the file order
      files = files[reverse(sort(files))]
   endif


   if filecount eq 1 then begin
      ; only one file for this hour was found
      print,'reading '+file_basename(files[0])
      filedata = read_goes_l0b_file(files[0],status)
      if status eq 0 then begin
         if size(data,/type) eq 0 then begin
            data=filedata
         endif else data=[temporary(data),filedata]
      endif ; status
   endif else begin
      if filecount gt 1 then begin

         print,'reading '+file_basename(files[0])
         refdata = read_goes_l0b_file(files[0],status)

         for ifile=1L,filecount-1 do begin
            print,'reading '+file_basename(files[ifile])
            filedata=read_goes_l0b_file(files[ifile],status)

            refdata = merge_refdata_filedata_private( refdata, filedata )

         endfor ; for ifile
         
         ; merge the refdata with the return variable, data
         if size(data,/type) eq 0 then data = refdata else data = [temporary(data),refdata]

      endif ; if filecount gt 1
   endelse ; if filecount eq 1
endfor ; for hh

if size(data,/type) eq 0 then data = -1 else status=0

return,data
end
