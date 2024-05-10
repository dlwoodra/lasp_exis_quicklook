pro close_sps_file
common write_to_sps_file_cal, sps_lun, last_hr, lastyd_h, format, epoch_in_unixtime

close,sps_lun
free_lun,sps_lun

return
end

pro write_to_sps_file, sps

common write_to_sps_file_cal, sps_lun, last_hr, lastyd_h, format, epoch_in_unixtime

if size(last_hr,/type) eq 0 then begin
   ; need to create a new file
   last_hr = -1 ; force a new file
   lastyd_h = -1
   current_unixtime=systime(1) ; current unix seconds since 1970
   current_jd=systime(/jul,/utc) ; current julian date in UT, (assume instantaneous with unix time)
   epoch_in_jd=julday(1,1,2000,0.,0.,0.) ; GOES-R TLM epoch
   epoch_in_unixtime= current_unixtime - ((current_jd - epoch_in_jd)*86400.d)
endif

default_file_name = getenv('exis_data_quicklook')+'/latest_sps_hour.txt'

this_hr = long(sps[0].time[0].sod[0]*24./86400.)
yd = (sps.time.yd)[0]
thisyd_h = string(yd,form='(i7.7)') + '_' + string(this_hr,form='(i2.2)')


if thisyd_h ne lastyd_h then begin
   ; close last file and open a new one
   if size(sps_lun,/type) ne 0 then begin
      ; old file needs to be closed
      close_sps_file

      ; use year/doy hierarchy
      dest_path = getenv('exis_data_l0b_sps') + '/' + $
                  ;string(yd/1000,form='(i4.4)') + '/' + $
                  ;string(yd mod 1000,form='(i3.3)') + '/'
                  strmid(lastyd_h,0,4) + '/' + $
                  strmid(lastyd_h,4,3) + '/'
      ; if dir doesn't exist, create it and all parents
      if file_test(dest_path) eq 0 then file_mkdir, dest_path
      n=0L
      strn = string(n,form='(i3.3)')
      dest = dest_path + 'sps_' + lastyd_h + '_'+ strn +'.txt'
      while file_test(dest) eq 1 or file_test(dest+'.gz') eq 1 do begin
         ; increment the cycle number until we find a file that does
         ; not already exist
         n++
         strn = string(n,form='(i3.3)')
         dest = dest_path + 'sps_' + lastyd_h + '_'+ strn +'.txt'
      endwhile
      ; now move the latest file to the new dir/location
      print,' WRITE_TO_SPS_FILE: moving '+default_file_name+' to '+dest
      file_move, default_file_name, dest
   endif ; otherwise there is no previous file to close
   ; now open the file
   openw, sps_lun, default_file_name, /get_lun
   printf, sps_lun, ';record={time_yd:0L, time_hms:"", time_sod:0.0, user_flags:0UL, '+$
           'TimeValid:0b, FSWBootRam:0b, ExisPowerAB:0b, ExisMode:0b, FM:0b, configID:0U, '+$
           'diodes:lonarr(6), '+$
           'offset:uintarr(6), '+$
           'asic_runCtrl:0b, asic_SciMode:0b, asic_pwrStatus:0b, asic_integTime:0b, '+$
           'ifBoardTemp_dn:0u, fpgaTemp_dn:0u, pwrSupplyTemp:0u, caseHtrTemp:0u, spsTemp_dn:0u, '+$
           'invalidFlags:0b, detChgCnt:0u, '+$
           ;'asicCalRamp:0b, asicCalCyclesRemaining:0u, ' +$
           'asic_SciVDAC:0u, asic_calVMin:0u, asic_CalVMax:0u, '+$
           'asic_calVstepUp:0b, asic_calTstepUp:0b, asic_calVstepDown:0b, asic_calTStepDown:0b, '+$
           'xrsEuvsMode:0b, fovFlags:0b, '+$
           'pri_hdr_ver_num:0b, pri_hdr_type:0b, pri_hdr_sec_hdr_flag:0b, pri_hdr_apid:0u, '+$
           'pri_hdr_seq_flag:0b, pri_hdr_pkt_seq_count:0u, pri_hdr_pkt_len:0u, '+$
           'sec_hdr_day:0UL, sec_hdr_millisec:0UL, sec_hdr_microsec:0u, RTepochdays:0, RTepochdaysod:0.d }'
;   printf,sps_lun,';yyyydoy-hms sod user_flags power inttime test cal data[4] offset[4] runCtrl dataMode pwrCtrlStat integCnt cal_cycles cal_vMin cal_vMax cal_vStepUp cal_tStepUp cal_vStepDown cal_tStepDown temp quat[4] vernum type sechdrflag apid seqflag pktseqcnt pktlen day ms microsec'
   ;       yd    hms     sod   userflags  6diodes 6offset
   format='(i7,x,a12,x, f9.3,x, z8,x, 4(z1,x), z2,x, z4,x 6(i7,x), 6(z4,x), '+ $
          ; asic: runCtrl datamode pwrStatus integTime
          '4(z2,x), '+$
          ; ifBoardTemp_dn, fpgaTemp_dn, pwrSupplyTemp_dn, caseHtrTemp,spsTemp_dn
          '5(i5,x), '+$
          ; asic.cal: invalidFlags, detChg_cnt, 
          'i3,x, i5,x, '+$
          ; (asic.cal.sciVDac, calVMin, calVMax), (VstepUp,TstepUp,VstepDown,TstepDown)
          '3(i5,x), 4(i3,x),'+$
          ; xrseuvsmodes, fov_flags
          '2(i3,x), '+$
          ; vnumtypesecflag apid, seq (pktseqcnt pktlen) day, ms, microsec, RTepochdays, RTepochdaysod
          '3(z1,x),         z3,x, z1,x, 2(z4.4,x),       z6,x, i10,x, i5, x, i5,x, f12.6 )'
   printf,sps_lun,';format='+strcompress(format)
   printf,sps_lun,';end_of_header'
endif

delta_unix      = systime(1) - epoch_in_unixtime
RTepochdays   = fix(delta_unix/86400.d)
RTepochdaysod = (delta_unix mod 86400.d)
;print,delta_unix

userf=sps.sec_hdr.uf
cal = sps.asic.cal
fsw = sps.fsw
pri = sps.pri_hdr
sec = sps.sec_hdr
ptime=sps.time

; write the data record
printf, sps_lun, ptime.yd, ptime.hms, ptime.sod, sec.userflags, $
        userf.TimeValid, userf.FSWBootRam, userf.ExisPowerAB, userf.ExisMode, userf.FM, userf.configID, $
        sps.diodes, $
        sps.offset, $
        sps.asic.runCtrl, sps.asic.SciMode, sps.asic.pwrStatus, sps.asic.integTime, $
        sps.ifBoardTemp, sps.fpgaTemp, sps.pwrSupplyTemp, sps.caseHtrTemp, sps.temperature, $
        fsw.invalidFlags, fsw.detChg_cnt, $
        ;sps.asic.cal.asicCalRamp, sps.asic.cal.asicCalCyclesRemaining, $
        cal.sciVDAC, cal.calVMin, cal.calVMax, $ ; 16-bit numbers
        cal.calVStepUp, cal.calTStepUp, cal.calVStepDown, cal.calTStepDown, $ ; 8-bit numbers
        fsw.xrseuvsmode, fsw.fovflags, $
        pri.ver_num, pri.type, pri.sec_hdr_flag, pri.apid, $
        pri.seq_flag, pri.pkt_seq_count, pri.pkt_len, $
        sec.day, sec.millisec, sec.microsec, RTepochdays, RTepochdaysod, $
        format=format
        
; remember the lastyd_h for moving the file
lastyd_h = thisyd_h
;stop
return
end
