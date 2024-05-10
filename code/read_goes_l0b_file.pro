; docformat = 'rst'

;+
; :Author:
;    Don Woodraska
;
; :Version:
;    $Id: read_goes_l0b_file.pro 63522 2014-10-07 22:37:40Z dlwoodra $
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado. 
;    All rights reserved. This software was developed at the 
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
;
;-

;+
; Read in any generic level 0b ASCII TXT file created by the
; EXIS quicklook software. Each line in the TXT files corresponds
; to one structure in the output.
;
; :Examples:
;    For example::
; 
;     IDL> file = '/goesr-work/data/fm1/l0b/xrs/2012/104/xrs_2012104_23_000.txt'
;     IDL> data = read_goes_l0b_file( file, status )
;     IDL> help, data, /struct
;     ** Structure <1d967f98>, 48 tags, length=184, data length=167, refs=1:
;       TIME_YD         LONG           2012104
;       TIME_HMS        STRING    '23:00:00.831'
;       TIME_SOD        FLOAT           82800.8
;       USER_FLAGS      ULONG       3238068233
;       TIMEVALID       BYTE         1
;       FSWBOOTRAM      BYTE         1
;       EXISPOWERAB     BYTE         0
;       EXISMODE        BYTE         1
;       FM              BYTE         1
;       CONFIGID        UINT             9
;       DIODES          LONG      Array[12]
;       OFFSET          UINT      Array[12]
;       ASIC_RUNCTRL    BYTE         1
;       ASIC_SCIMODE    BYTE         1
;       ASIC_PWRSTATUS  BYTE        15
;       ASIC_INTEGTIME  BYTE         3
;       FFPOWER         BYTE         0
;       FFLEVEL         UINT             0
;       IFBOARDTEMP_DN  UINT         19868
;       FPGATEMP_DN     UINT         21199
;       PWRSUPPLYTEMP_DN
;                       UINT         20064
;       CASEHTRTEMP_DN  UINT         21143
;       ASIC1TEMP_DN    UINT         24388
;       ASIC2TEMP_DN    UINT         24384
;       FILTERTEMP_DN   UINT         24001
;       MAGNETTEMP_DN   UINT         27945
;       INVALIDFLAGS    BYTE         0
;       DETCHG_CNT      UINT         35226
;       FFCHG_CNT       UINT         65535
;       ASIC_SCIVDAC    UINT             0
;       ASIC_CALVMIN    UINT             0
;       ASIC_CALVMAX    UINT             0
;       ASIC_CALVSTEPUP BYTE         7
;       ASIC_CALTSTEPUP BYTE         0
;       ASIC_CALVSTEPDOWN
;                       BYTE         0
;       ASIC_CALTSTEPDOWN
;                       BYTE         0
;       XRSEUVSMODE     BYTE         0
;       FOVFLAGS        BYTE         0
;       PRI_HDR_VER_NUM BYTE         0
;       PRI_HDR_TYPE    BYTE         0
;       PRI_HDR_SEC_HDR_FLAG
;                       BYTE         1
;       PRI_HDR_APID    UINT           929
;       PRI_HDR_SEQ_FLAG
;                       BYTE         3
;       PRI_HDR_PKT_SEQ_COUNT
;                       UINT          2459
;       PRI_HDR_PKT_LEN UINT           113
;       SEC_HDR_DAY     ULONG             4486
;       SEC_HDR_MILLISEC
;                       ULONG         82800831
;       SEC_HDR_MICROSEC
;                       UINT           141
;
; :Uses:
;    NA
;
; :Returns:
;    Array of data structures based on the file contents.
;
; :Params:
;    file : in, optional, type=string
;      Case-sensitive name of a file to read.
;      If no path is provided in the string, the current directory is searched
;      If file is not specified, then DIALOG_PICKFILE is called to select
;      the file. The path is remembered and used by default for the next call. 
;      Effective Jan 10, 2014, the software now supports reading gzip compress 
;      text files. The gz extension is used to identify compressed files.
;    status : out, optional, type=integer
;      This variable contains either a 0 for success, or a -1 for a complete failure.
;      Sometimes the file may end with only a partial record, and return a status of -2.
;      The previous records (if any) are returned under that condition.
;
; :Keywords:
;    fileheader : out, optional, type=stringarray
;      This return variable contains a string for each header line in the file.
;    verbose : in, optional, type=boolean
;      This keyword enables verbose messages to be printed.
;
; :Categories:
;    util, general
;
;-
function read_goes_l0b_file, file, status, fileheader=fileheader, verbose=verbose

common read_goes_l0b_file, the_last_path_used

status=0

if n_params() gt 2 then begin
   print,'USAGE: data = read_goes_l0bfile( filename, status )'
   print,' filename: a string containing the fully qualified path and filename'
   print,' status: 0 means OK, anything else is an error'
   status=-1
   return,-1
endif

if n_params() eq 0 then begin
   if size(the_last_path_used,/type) eq 0 then the_last_path_used='./'
   file = dialog_pickfile(filter='*.txt',$
                          title='Select a GOES-R EXIS Level 0B text file', $
                         get_path=the_last_path_used, $
                         path=the_last_path_used)
endif

if file_test(file) ne 1 then begin
   tmpfile=file+'.gz' ; look for gz file instead
   if file_test(tmpfile) ne 1 then begin
      print,'ERROR: read_goes_l0b_file - file not found'
      print,' file specified was '+file
      stop
      status=-1
      return,-1
   endif else file=tmpfile ; use gz file
endif

compress=0 ; assume no compression
if strlowcase(strmid(file,strlen(file)-2,2)) eq 'gz' then compress=1

if keyword_set(verbose) then print,'INFO: read_goes_l0b_file - reading '+file

openr,lun,file,/get_lun,compress=compress
; look for lines with "record=" and "format="
s=';'
fileheader=''
line_count=0L
while s ne ';end_of_header' do begin
   readf,lun,s
   fileheader=[fileheader,s]
   line_count++
   if strmid(s,1,7) eq 'format=' then begin
     tmp = strsplit(s, "=", /EXTRACT)
     format = tmp[1]
   endif
   if strmid(s,1,7) eq 'record=' then rec_str = strmid(s,8,strlen(s)-8)
endwhile

n_rec = file_lines(file) - line_count

if (!version.os_family eq 'unix') and (compress eq 1) then begin
  cmd='gzip -dc '+file+' | wc -l' ; unzip and count lines
  spawn, cmd, result, err
  if err ne "" then begin
    print,'ERROR: read_goes_l0b_file has an error'
    print,'gzip error: ', err
    stop
  endif
  n_rec = long(result[0]) ; there is code below to remove extra records
  ; so we don't really need to subtract - linecount
endif else begin
  if compress eq 1 then n_rec = (n_rec*20L)>241 ; guess 20:1 compression as upper limit
  ; the LZSS breaks data into 2 minute files, so the worst case
  ; scenario is a 4 Hz (SPS) file with 240 samples, then add 1
  ; unfilled records are trimmed at the end anyway
endelse

if n_rec lt 1 then begin
  print,'ERROR: read_goes_l0b_file - no data in file '+strtrim(file,2)
  status=-1
  return,-1
endif

;create the base record
rec_result=execute('rec='+rec_str) ; create rec

;replicate the record
data = replicate(rec,n_rec)

;read data into each record
tmp = rec
on_ioerror, do_cleanup
error_flag=1 ; set so ioerrors are detected
counter=0L
while not eof(lun) and counter lt n_rec do begin
   ;readf,lun,tmp,form=format ; old way fails on blank lines
   readf,lun,s ; read a line as a string
   ; now figure out how to put the string into the structure tmp
   if strlen(s) gt 0 then begin
      if strmid(s,0,1) ne ';' then begin
         reads, s, tmp, form=format ; read the string and write it to the tmp structure
         data[counter++] = tmp
      endif
   endif
endwhile
; remove any empty records (if any) that correspond to blank lines
if n_elements(data) gt counter then begin
   data = data[0:counter-1]
endif
error_flag=0
do_cleanup:
if error_flag eq 1 then begin
   print,'ERROR: READ_GOES_L0B_FILE - an error occured while reading the file '+file
   print,' the file is corrupted/incomplete and could not be completely read'
   if counter gt 0 then begin
      data=data[0:counter-1]
      status=-2 ;partial error state
   endif else begin
      data = -1 ;could try to return an empty rec
      status=-1 ;fail error state
   endelse
endif
tmp=0b ;erase

close,lun
free_lun,lun

return,data
end
