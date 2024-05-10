function apply_xrs_dark, side, asic1Temp_dn, inttime, famps=famps

; use /famps to return a current
; default is to return DN

common apply_xrs_dark, darkaside1, darkbside1 ;, darkaside2, darkbside2
common apply_gain_cal, temperature_C, xrsgain
common exis_quicklook,exis_type

if size(exis_type,/type) eq 0 then exis_type = getenv('exis_type')
thistype = strlowcase(exis_type)

if thistype eq 'etu' or thistype eq 'sim' then thistype='fm1'

p = getenv('exis_cal_data')
if strlen(p) gt 3 then p=p+path_sep() else p='.'+path_sep()

; only use thermistor from asic1 to keep it simple
if size(darkaside1,/type) eq 0 then begin
   asidecalfile = 'exis_'+thistype+'_xrs_dark_asic1temp_aside.cal'
   status = 0 ; good
   if file_test(p+asidecalfile) eq 1 then darkaside1=(read_goes_l0b_file(p+asidecalfile,status)).data else begin
      status = 1 ; bad
      print,'ERROR: apply_xrs_dark_cannot find '+p+asidecalfile
   endelse
   if status ne 0 then begin
      print,'ERROR: apply_xrs_dark cannot find '+p+asidecalfile
      darkaside1 = (read_goes_l0b_file(dialog_pickfile(filter=asidecalfile, title='Find '+asidecalfile, get_path=last_path_used))).data
   endif

   bsidecalfile = 'exis_'+thistype+'_xrs_dark_asic1temp_bside.cal'
   status = 0 ; good
   if file_test(p+bsidecalfile) eq 1 then darkbside1 = (read_goes_l0b_file(p+bsidecalfile, status)).data else begin
      status = 1 ; bad
      print,'ERROR: apply_xrs_dark_cannot find '+p+bsidecalfile
   endelse
   if status ne 0 then begin
      if size(last_path_used,/type) eq 0 then last_path_used='./'
      darkbside1 = (read_goes_l0b_file(dialog_pickfile(filter=bsidecalfile, title='Find '+bsidecalfile, path=last_path_used))).data
   endif
endif


if side eq 1 then begin
   ; side A
   signal = reform(darkaside1[1:*,asic1Temp_dn])
endif else begin
   ; side B
   signal = reform(darkbside1[1:*,asic1Temp_dn])
endelse

if keyword_set(famps) ne 0 then begin
   ; convert to a current
   signal = apply_gain(signal, asic1Temp_dn, /xrs)
endif

return, signal
end
