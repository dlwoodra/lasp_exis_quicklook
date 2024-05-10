pro update_quicklook_dir

exis_type = strupcase(getenv('exis_type'))

close,/all ; force any open file units to be closed so files are complete

; get file list
files = file_search(getenv('exis_data_quicklook')+'/latest_*_hour.txt',count=count)

if count eq 0 then begin
   print,'quicklook directory is empty'
   return
endif

for i=0L,count-1 do begin
   ; type
   ; bug fix in case the path has an underscore (strip off the path)
   type = (strsplit(file_basename(files[i]),'_',/extract))[1]
   case type of
      'sps':    outdir=getenv('exis_data_l0b_sps')+'/'
      'tdrift': outdir=getenv('exis_data_l0b_tdrift')+'/'
      'xrs':    outdir=getenv('exis_data_l0b_xrs')+'/'
      'euvsa':  outdir=getenv('exis_data_l0b_euvsa')+'/'
      'euvsb':  outdir=getenv('exis_data_l0b_euvsb')+'/'
      'euvsc':  outdir=getenv('exis_data_l0b_euvsc')+'/'
   endcase
   ; read the file
   data = read_goes_l0b_file(files[i],status)
   yd = data[0].time_yd
   hourstr = string(long(data[0].time_sod / 60. / 60.),form='(i2.2)')
   ofile=type+'_'+strtrim(yd,2)+'_'+hourstr+'_000.txt'
   opath=outdir+strtrim(yd/1000,2)+'/'+string(yd mod 1000,form='(i3.3)')+'/'
   if file_test(opath) eq 0 then file_mkdir,opath
   cnt=0L
   while file_test(opath+ofile) eq 1 do begin
      ofile=type+'_'+strtrim(yd,2)+'_'+hourstr+'_'+string(cnt++,form='(i3.3)')+'.txt'
   endwhile
   
   print,'copying '+files[i]+' to '+opath+ofile
   file_copy,files[i],opath+ofile

endfor

; make CSV files
if strmatch(exis_type,'SIM') eq 1 then make_day_csv, yd, /sim
if strmatch(exis_type,'ETU') eq 1 then make_day_csv, yd, /etu
if strmatch(exis_type,'FM1') eq 1 then make_day_csv, yd, /fm1
if strmatch(exis_type,'FM2') eq 1 then make_day_csv, yd, /fm2
if strmatch(exis_type,'FM3') eq 1 then make_day_csv, yd, /fm3
if strmatch(exis_type,'FM4') eq 1 then make_day_csv, yd, /fm4


; calculate previous day
year = yd / 1000L
doy  = yd mod 1000L
doy--
if doy eq 0 then begin
   year--
   doy = 365
   if year mod 4 eq 0 then begin
      ; leap year
      doy = 366
   endif
endif
prevyd=year*1000L + doy

; remake CSV files
if strmatch(exis_type,'SIM') eq 1 then make_day_csv, prevyd, /sim
if strmatch(exis_type,'ETU') eq 1 then make_day_csv, prevyd, /etu
if strmatch(exis_type,'FM1') eq 1 then make_day_csv, prevyd, /fm1
if strmatch(exis_type,'FM2') eq 1 then make_day_csv, prevyd, /fm2
if strmatch(exis_type,'FM3') eq 1 then make_day_csv, prevyd, /fm3
if strmatch(exis_type,'FM4') eq 1 then make_day_csv, prevyd, /fm4

return
end
