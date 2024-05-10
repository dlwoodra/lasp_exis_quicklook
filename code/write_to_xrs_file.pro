pro close_xrs_file
common write_to_xrs_file_cal, xrs_lun, last_hr, lastyd_h, format

close,xrs_lun
free_lun,xrs_lun

return
end

pro write_to_xrs_file, xrs

common write_to_xrs_file_cal, xrs_lun, last_hr, lastyd_h, format

if size(last_hr,/type) eq 0 then begin
   ; need to create a new file
   last_hr = -1 ; force a new file
   lastyd_h = -1
endif

default_file_name = getenv('exis_data_quicklook')+'/latest_xrs_hour.txt'

this_hr = long(xrs[0].time[0].sod[0]*24./86400.)
yd = (xrs.time.yd)[0]
thisyd_h = string(yd,form='(i7.7)') + '_' + string(this_hr,form='(i2.2)')


if thisyd_h ne lastyd_h then begin
   ; close last file and open a new one
   if size(xrs_lun,/type) ne 0 then begin
      ; old file needs to be closed
      close_xrs_file

      ; use year/doy hierarchy
      dest_path = getenv('exis_data_l0b_xrs') + '/' + $
                  ;string(yd/1000,form='(i4.4)') + '/' + $
                  ;string(yd mod 1000,form='(i3.3)') + '/'
                  strmid(lastyd_h,0,4) + '/' + $
                  strmid(lastyd_h,4,3) + '/'
      ; if dir doesn't exist, create it and all parents
      if file_test(dest_path) eq 0 then file_mkdir, dest_path
      n=0L
      strn = string(n,form='(i3.3)')
      dest = dest_path + 'xrs_' + lastyd_h + '_'+ strn +'.txt'
      while file_test(dest) eq 1 or file_test(dest+'.gz') eq 1 do begin
         ; increment the cycle number until we find a file that does
         ; not already exist
         n++
         strn = string(n,form='(i3.3)')
         dest = dest_path + 'xrs_' + lastyd_h + '_'+ strn +'.txt'
      endwhile
      ; now move the latest file to the new dir/location
      print,' WRITE_TO_XRS_FILE: moving '+default_file_name+' to '+dest
      file_move, default_file_name, dest
   endif ; otherwise there is no previous file to close
   ; now open the file
   openw, xrs_lun, default_file_name, /get_lun
   printf, xrs_lun, ';record={time_yd:0L, time_hms:"", time_sod:0.0, user_flags:0UL,' +$
        'TimeValid:0b, FSWBootRam:0b, ExisPowerAB:0b, ExisMode:0b, FM:0b, configID:0U, '+$
        'diodes:lonarr(12), '+$
        'offset:uintarr(12), '+$
        'asic_runCtrl:0b, asic_SciMode:0b, asic_pwrStatus:0b, asic_integTime:0b, ffPower:0b, '+$
        'ffLevel:0u, ifBoardTemp_dn:0u, fpgaTemp_dn:0u, pwrSupplyTemp_dn:0u, caseHtrTemp_dn:0u, asic1Temp_dn:0u, asic2Temp_dn:0u, filterTemp_dn:0u, magnetTemp_dn:0u, '+$
        'invalidFlags:0b, detChg_cnt:0u, ffChg_cnt:0u, '+$
;asicCalRamp:0b, asicCalCyclesRemaining:0u,'+$
        'asic_SciVDAC:0u, asic_calVMin:0u, asic_calVMax:0u, '+$
        'asic_calVstepUp:0b, asic_calTstepUp:0b, asic_calVstepDown:0b, asic_calTstepDown:0b, '+$
        'xrsEuvsMode:0b, fovFlags:0b, '+$
        'pri_hdr_ver_num:0b, pri_hdr_type:0b, pri_hdr_sec_hdr_flag:0b, pri_hdr_apid:0u,'+ $
        'pri_hdr_seq_flag:0b, pri_hdr_pkt_seq_count:0u, pri_hdr_pkt_len:0u,'+ $
        'sec_hdr_day:0UL, sec_hdr_millisec:0UL, sec_hdr_microsec:0u}'

;   printf,xrs_lun,';yyyydoy hms sod user_flags data[12] offset[12] runCtrl dataMode pwrCtrlStat integCnt tempa tempb tempslit vernum type sechdrflag apid seqflag pktseqcnt pktlen day ms microsec'
   ;       yd    hms    sod   userflags diodes offset
   format='(i7,x,a12,x, f12.6,x, z8,x, 4(z1,x), z2,x, z4,x, 12(i7,x), 12(z4,x), '+ $
          ; asic: runCtrl sciMode pwrStatus integTime ffpower
          '5(z2,x), '+$
          ; (ff_level, ifBoardTemp, fpgaTemp, pwrSupplyTemp, caseHtrTemp, asic1temp, asic2temp, filterTemp_dn,magnetTemp_dn)
          '9(i5,x), '+$
          ; invalidFlags,(detChg_cnt,ffChg_cnt),
          'i3,x, 2(i5,x), '+$
          ; (asic.cal.sciVDac, calVMin, calVMax), (VstepUp,TstepUp,VstepDown,TstepDown)
          '3(i5,x), 4(i3,x), '+$
          ; xrseuvsmodes, fov_flags
          '2(i3,x), '+$
          ; vnumtypesecflag apid, seq (pktseqcnt pktlen) day, ms, microsec
          '3(z1,x),         z3,x, z1,x, 2(z4.4,x),       z6,x, i10,x, i5 )'
   printf,xrs_lun,';format='+strcompress(format)
   printf,xrs_lun,';end_of_header'

endif

userf=xrs.sec_hdr.uf
cal = xrs.asic.cal
fsw = xrs.fsw
pri = xrs.pri_hdr
sec = xrs.sec_hdr
ptime=xrs.time

; write the data record
printf, xrs_lun, ptime.yd, ptime.hms, ptime.sod, sec.userflags, $
        userf.TimeValid, userf.FSWBootRam, userf.ExisPowerAB, userf.ExisMode, userf.FM, userf.configID, $
        xrs.diodes, $
        xrs.offset, $
        xrs.asic.runCtrl, xrs.asic.SciMode, xrs.asic.pwrStatus, xrs.asic.integTime, xrs.ff.power, $
        xrs.ff.level, xrs.ifBoardTemp, xrs.fpgaTemp, xrs.pwrSupplyTemp, xrs.caseHtrTemp, xrs.asic1temp, xrs.asic2temp, xrs.filterTemp, xrs.magnetTemp, $
        fsw.invalidFlags, fsw.detChg_cnt, fsw.ffChg_cnt, $
;xrs.asic.cal.asicCalRamp, xrs.asic.cal.asicCalCyclesRemaining, $
        cal.sciVDAC, cal.calVMin, cal.calVMax, $ ; 16-bit numbers
        cal.calVStepUp, cal.calTStepUp, cal.calVStepDown, cal.calTStepDown, $ ; 8-bit numbers
        fsw.xrseuvsmode, fsw.fovflags, $
        pri.ver_num, pri.type, pri.sec_hdr_flag, pri.apid, $
        pri.seq_flag, pri.pkt_seq_count, pri.pkt_len, $
        sec.day, sec.millisec, sec.microsec, $
        format=format
        
; remember the lastyd_h for moving the file
lastyd_h = thisyd_h
;stop
return
end
