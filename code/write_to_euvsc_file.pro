pro close_euvsc_file
common write_to_euvsc_file_cal, euvsc_lun, last_hr, lastyd_h, format

close,euvsc_lun
free_lun,euvsc_lun

return
end

pro write_to_euvsc_file, euvsc

common write_to_euvsc_file_cal, euvsc_lun, last_hr, lastyd_h, format

if size(last_hr,/type) eq 0 then begin
   ; need to create a new file
   last_hr = -1 ; force a new file
   lastyd_h = -1
endif

default_file_name = getenv('exis_data_quicklook')+'/latest_euvsc_hour.txt'

this_hr = long(euvsc[0].time[0].sod[0]*24./86400.)
yd = (euvsc.time.yd)[0]
thisyd_h = string(yd,form='(i7.7)') + '_' + string(this_hr,form='(i2.2)')


if thisyd_h ne lastyd_h then begin
   ; close last file and open a new one
   if size(euvsc_lun,/type) ne 0 then begin
      ; old file needs to be closed
      close_euvsc_file

      ; use year/doy hierarchy
      dest_path = getenv('exis_data_l0b_euvsc') + '/' + $
                  strmid(lastyd_h,0,4) + '/' + $
                  strmid(lastyd_h,4,3) + '/'
                  ;string(yd/1000,form='(i4.4)') + '/' + $
                  ;string(yd mod 1000,form='(i3.3)') + '/'
      ; if dir doesn't exist, create it and all parents
      if file_test(dest_path) eq 0 then file_mkdir, dest_path
      n=0L
      strn = string(n,form='(i3.3)')
      dest = dest_path + 'euvsc_' + lastyd_h + '_'+ strn +'.txt'
      while file_test(dest) eq 1 or file_test(dest+'.gz') eq 1 do begin
         ; increment the cycle number until we find a file that does
         ; not already exist
         n++
         strn = string(n,form='(i3.3)')
         dest = dest_path + 'euvsc_' + lastyd_h + '_'+ strn +'.txt'
      endwhile
      ; now move the latest file to the new dir/location
      print,' WRITE_TO_EUVSC_FILE: moving '+default_file_name+' to '+dest
      file_move, default_file_name, dest
   endif ; otherwise there is no previous file to close
   ; now open the file
   openw, euvsc_lun, default_file_name, /get_lun
   printf, euvsc_lun, ';record={time_yd:0L, time_hms:"", time_sod:0.0, user_flags:0UL,'+ $
        'TimeValid:0b, FSWBootRam:0b, ExisPowerAB:0b, ExisMode:0b, FM:0b, configID:0U, '+$
        'data:lonarr(512), '+$
        'cal_ModeReg:0b, cal_RunCtrl:0b, cal_PwrStatus:0b, cal_integTime:0b, cal_deadTime:0b, '+$
        'ff_power:0b, ff_level:0u, ifBoardTemp_dn:0u, fpgaTemp_dn:0u, pwrSupplyTemp_dn:0u, caseHtrTemp_dn:0u, euvsCHtrTemp_dn:0u, c1Temp_dn:0u, c2Temp_dn:0u, adcTemp_dn:0u, slitTemp_dn:0u,'+$ ; added slittemp
        'invalidFlags:0b, detChg_cnt:0u, ffChg_cnt:0u, '+$
        'door_status:0b, filter_status:0b, door_pos:0b, filter_pos:0b, '+$
        'xrsEuvsMode:0b, fovFlags:0b, '+$
        'pri_hdr_ver_num:0b, pri_hdr_type:0b, pri_hdr_sec_hdr_flag:0b, pri_hdr_apid:0u,'+ $
        'pri_hdr_seq_flag:0b, pri_hdr_pkt_seq_count:0u, pri_hdr_pkt_len:0u,'+ $
        'sec_hdr_day:0UL, sec_hdr_millisec:0UL, sec_hdr_microsec:0u}'

;   printf,euvsc_lun,';yyyydoy hms sod user_flags power inttime test channel data[512] flushCntModes runPwrCtrlStat deadCnt integCnt door_pos filter_pos temp1 temp2 tempADC ff0pwr ff0level ff1pwr ff1level vernum type sechdrflag apid seqflag pktseqcnt pktlen day ms microsec'

;       yd-hms        sod   userflags diodes
   format='(i7,x,a12,x, f9.3,x, z8,x, 4(z1,x), z2,x, z4,x, 512(i7,x), '+ $
; (calM,calC,calP,calI,dead,ffpower), (fflevel , ifboardTemp,
; fpgatemp,pwrSupplyTemp,caseHtrTemp,euvsCHtrTemp, c1Temp, c2Temp,
; adcTemp, slitTemp)
          '6(z2,x), 10(z4,x),'+$
; invalidFlags,(detChg_cnt,ffChg_cnt),(door_status,filter_status,door_pos,filter_pos)
          'i3,x, 2(i5,x), 4(z2,x),'+$
          ; xrseuvsmodes, fov_flags
          '2(i3,x), '+$
; vnumtypesecflag   apid, seq (pktseqcnt pktlen) day, ms, microsec
          '3(z1,x), z3,x, z1,x, 2(z4.4,x),       z6,x, i10,x, i5 )'
   printf,euvsc_lun,';format='+strcompress(format)
   printf,euvsc_lun,';end_of_header'

endif

userf=euvsc.sec_hdr.uf ; extracted userflags
mech=euvsc.exis_mech
reg=euvsc.reg
fsw=euvsc.fsw
pri=euvsc.pri_hdr
sec=euvsc.sec_hdr
ptime=euvsc.time

; write the data record
printf, euvsc_lun, ptime.yd, ptime.hms, ptime.sod, sec.userflags, $
        userf.TimeValid, userf.FSWBootRam, userf.ExisPowerAB, userf.ExisMode, userf.FM, userf.configID, $
        euvsc.data, $
        reg.ModeReg, reg.ControlStatReg, reg.pwrStatus, reg.integTime, reg.deadTime, $
        euvsc.ff.power, euvsc.ff.level, euvsc.ifBoardTemp, euvsc.fpgaTemp, euvsc.pwrSupplyTemp, euvsc.caseHtrTemp, euvsc.euvscHtrTemp, euvsc.c1Temp, euvsc.c2Temp, euvsc.adcTemp, euvsc.slitTemp, $
        fsw.invalidFlags, fsw.detChg_cnt, fsw.ffChg_cnt, $
        mech.doorStatus, mech.filterStatus, $
        mech.doorPosition, mech.filterPosition, $
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
