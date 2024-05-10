pro close_tdrift_file
common write_to_tdrift_file_cal, tdrift_lun, last_hr, lastyd_h, format, epoch_in_unixtime

close,tdrift_lun
free_lun,tdrift_lun

return
end

pro write_to_tdrift_file, tdrift

common write_to_tdrift_file_cal, tdrift_lun, last_hr, lastyd_h, format, epoch_in_unixtime

if size(last_hr,/type) eq 0 then begin
   ; need to create a new file
   last_hr = -1 ; force a new file
   lastyd_h = -1
   current_unixtime=systime(1) ; current unix seconds since 1970
   current_jd=systime(/jul,/utc) ; current julian date in UT, (assume instantaneous with unix time)
   epoch_in_jd=julday(1,1,2000,0.,0.,0.) ; GOES-R TLM epoch
   epoch_in_unixtime= current_unixtime - ((current_jd - epoch_in_jd)*86400.d)
endif

default_file_name = getenv('exis_data_quicklook')+'/latest_tdrift_hour.txt'

this_hr = long(tdrift[0].time[0].sod[0]*24./86400.)
yd = (tdrift.time.yd)[0]
thisyd_h = string(yd,form='(i7.7)') + '_' + string(this_hr,form='(i2.2)')


if thisyd_h ne lastyd_h then begin
   ; close last file and open a new one
   if size(tdrift_lun,/type) ne 0 then begin
      ; old file needs to be closed
      close_tdrift_file

      ; use year/doy hierarchy
      dest_path = getenv('exis_data_l0b_tdrift') + '/' + $
                  ;string(yd/1000,form='(i4.4)') + '/' + $
                  ;string(yd mod 1000,form='(i3.3)') + '/'
                  strmid(lastyd_h,0,4) + '/' + $
                  strmid(lastyd_h,4,3) + '/'
      ; if dir doesn't exist, create it and all parents
      if file_test(dest_path) eq 0 then file_mkdir, dest_path
      n=0L
      strn = string(n,form='(i3.3)')
      dest = dest_path + 'tdrift_' + lastyd_h + '_'+ strn +'.txt'
      while file_test(dest) eq 1 or file_test(dest+'.gz') eq 1 do begin
         ; increment the cycle number until we find a file that does
         ; not already exist
         n++
         strn = string(n,form='(i3.3)')
         dest = dest_path + 'tdrift_' + lastyd_h + '_'+ strn +'.txt'
      endwhile
      ; now move the latest file to the new dir/location
      print,' WRITE_TO_TDRIFT_FILE: moving '+default_file_name+' to '+dest
      file_move, default_file_name, dest
   endif ; otherwise there is no previous file to close
   ; now open the file
   openw, tdrift_lun, default_file_name, /get_lun
   printf, tdrift_lun, ';record={time_yd:0L, time_hms:"", time_sod:0.0, user_flags:0UL, '+$
           'TimeValid:0b, FSWBootRam:0b, ExisPowerAB:0b, ExisMode:0b, FM:0b, configID:0U, '+$
           'localTimeState:0b, pendingDay:0L, pending_sod:0.d, freeWheelCount:0U, '+$
           'SpwLinkRxTimeTick:0b, lastDay:0L, last_sod:0.d, '+$
           'scTimeMsgNotRecvdCnt:0b, scTimeCodeNotRecvdCnt:0b, '+$
           'spwLinkRxTimePrevMaxMicrosec:0UL, '+$
           'pri_hdr_apid:0u, '+$
           'pri_hdr_pkt_seq_count:0u, '+$
           'sec_hdr_day:0UL, sec_hdr_millisec:0UL, sec_hdr_microsec:0u, RTepochdays:0, RTepochdaysod:0.d }'
;   printf,tdrift_lun,';yyyydoy-hms sod user_flags power inttime test cal data[4] offset[4] runCtrl dataMode pwrCtrlStat integCnt cal_cycles cal_vMin cal_vMax cal_vStepUp cal_tStepUp cal_vStepDown cal_tStepDown temp quat[4] vernum type sechdrflag apid seqflag pktseqcnt pktlen day ms microsec'
   ;       yd    hms     sod   userflags timevalid fswboot powerAB Mode  FM  configid
   format='(i7,x,a12,x, f9.3,x, z8,x, 4(z1,x), z2,x, z4,x, '+ $
          ;localTimeState, 
          'z2,x, '+$
          ;pday, psod, 
          'z6,x, f12.6,x, '+$
          ;freewheelcnt, spwlinktick, 
          'i5,x, z2,x, '+$
          ;lday, lsod, 
          'z6,x, f12.6,x, '+$
          ;(sctimemsgcnt, sctimecodecnt), spwlinkmicro
          '2(z2,x), z8,x, '+$
          ; apid, pktseqcnt day,   ms, microsec, RTepochdays, RTepochdaysod
          'z3,x,  z4.4,x,   z6,x, i10,x, i5, x, i5,x, f12.6 )'
   printf,tdrift_lun,';format='+strcompress(format)
   printf,tdrift_lun,';end_of_header'
endif

delta_unix      = systime(1) - epoch_in_unixtime
RTepochdays   = fix(delta_unix/86400.d)
RTepochdaysod = (delta_unix mod 86400.d)
;print,delta_unix

userf=tdrift.sec_hdr.uf
;cal = tdrift.asic.cal
;fsw = tdrift.fsw
pri = tdrift.pri_hdr
sec = tdrift.sec_hdr
ptime=tdrift.time

; write the data record
for i=0,4 do $
  printf, tdrift_lun, ptime.yd, ptime.hms, ptime.sod, sec.userflags, $
        userf.TimeValid, userf.FSWBootRam, userf.ExisPowerAB, userf.ExisMode, userf.FM, userf.configID, $
        tdrift.td[i].localTimeState, $

        tdrift.td[i].pendDay, $
        double(tdrift.td[i].pendMillisec*0.001d + tdrift.td[i].pendMicrosec*0.000001d),$

        tdrift.td[i].freeWheelCnt, $
        tdrift.td[i].spwLinkRxTimeTick, $

        tdrift.td[i].lastDay, $
        double(tdrift.td[i].lastMillisec*0.001d + tdrift.td[i].lastMicrosec*0.000001d),$

        tdrift.td[i].scTimeMsgNotRecvdCnt, $
        tdrift.td[i].scTimeCodeNotRecvdCnt, $
        tdrift.td[i].spwLinkRxTimePrevMaxMicrosec, $

        pri.apid, $
        pri.pkt_seq_count, $ 
        sec.day, sec.millisec, sec.microsec, RTepochdays, RTepochdaysod, $
        format=format
        
; remember the lastyd_h for moving the file
lastyd_h = thisyd_h
;stop
return
end
