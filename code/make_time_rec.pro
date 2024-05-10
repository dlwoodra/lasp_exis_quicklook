pro make_time_rec_zeroUTepoch, sec_hdr, time_rec

;
; this is the old code for make_time_rec
;

  yyyydoy = days_to_yd( double( sec_hdr.day ), 2000001L )
  sod     = ( sec_hdr.millisec * 1.d-3 ) + ( sec_hdr.microsec * 1.d-6 )
  df = double(sec_hdr.day) + (sod/86400.d0)

  hh=string(fix(sod*24./86400.),form='(i2.2)')
  hresid=(sod*24./86400. mod 1)*60.
  mm=string(fix(hresid),form='(i2.2)')
  mresid = (hresid mod 1.) * 60.
  ss=string(fix(mresid),form='(i2.2)')
  sss='.'+string((mresid mod 1.)*1000.,form='(i3.3)')
  hms=hh+':'+mm+':'+ss+sss

  time_rec.yd = yyyydoy
  time_rec.sod = sod
  time_rec.df  = df
  time_rec.hms = hms

return
end

pro make_time_rec, sec_hdr, time_rec, zeroUTepoch=zeroUTepoch

  ; 6/1/13 DLW
  ; the epoch is noon UT on Jan 1, 2000 (default since June 1, 2013)
  ; the old epoch was 0 UT on Jan 1, 2000
  ; to get the timestamps right for previously created telemetry files
  ; we need to set the zeroUTepoch keyword to true

  if keyword_set(zeroUTepoch) then begin
     ; use the old code if specified
     make_time_rec_zeroUTepoch, sec_hdr, time_rec
     return
  endif
  
  yyyydoy = days_to_yd( double( sec_hdr.day )+0.5d0, 2000001.5d0 )
  ; preserve precision until the add is done
  sod = double(ulong64(sec_hdr.millisec)*1000ULL + sec_hdr.microsec)*1.d-6

; ACCOUNT FOR THE J2k EPOCH starting at noon Jan 1, 2000.
  halfdaysecD = 43200.d0

  if sod ge halfdaysecD then begin
     ; same day
     sod -= halfdaysecD
  endif else begin
     ; previous day
     sod += halfdaysecD
     yyyydoy  = get_prev_yyyydoy(yyyydoy,1)
  endelse

  pkt_microsec = (ulong64(sec_hdr.millisec) * 1000uLL) $ ; millisecond portion
                 + ulong64(sec_hdr.microsec)             ; microsecond portion
  microsec = pkt_microsec + 43200000000uLL ; epoch half day offset

  df = double(sec_hdr.day) + ( microsec * 1.d-6 )/86400.d

  ; assign to output structure
  time_rec.microSecondsSinceEpoch = microsec + (ulong64(sec_hdr.day)*86400000000ULL) ; ignore leap seconds
  time_rec.yd = yyyydoy
  time_rec.sod = sod
  time_rec.df  = df
  time_rec.hms = convert_sod_to_hms_string( sod )

return
end


