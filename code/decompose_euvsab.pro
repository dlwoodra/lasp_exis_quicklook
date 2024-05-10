; $Id: decompose_euvsab.pro 32846 2012-05-11 19:21:37Z dlwoodra $

pro decompose_euvsab, buf, euvs_rec, euvsb=euvsb

@gpds_defines.pro

; extract data from byte-array (buf) and populate euvs_rec

  lo=19
  checksum = buf[lo]

  ; check the checksum (starts on byte 20)
  if checksum ne calculate_checksum(buf[20:*]) then begin
     print,'ERROR: CHECKSUM FAILED - EUVS-AB packet failed the checksum test'
  endif

  lo = 20
  hi = 91
  euvs_data = (ishft(ulong(buf[lo:hi:3]) AND 'F'xUL,16)) + $
              ishft(ulong(buf[lo+1:hi:3]),8) + $
              ulong(buf[lo+2:hi:3])

  euvs_rec.diodes = euvs_data

  lo = 92
  hi = 139
  euvs_rec.offset = (ishft(uint(buf[lo:hi:2]) AND '3F'xu,8)) + $
                    uint(buf[lo+1:hi:2])

  lo = 140
  euvs_rec.asic.runCtrl    = buf[lo++]
  euvs_rec.asic.SciMode    = buf[lo++]
  euvs_rec.asic.pwrStatus  = buf[lo++]
  euvs_rec.asic.integTime  = buf[lo++]

  euvs_rec.ff.power = buf[lo++]
  euvs_rec.ff.level = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 147
  euvs_rec.ifBoardTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 149
  euvs_rec.fpgaTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 151
  euvs_rec.pwrSupplyTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 153
  euvs_rec.caseHtrTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 155
  euvs_rec.aTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 157
  euvs_rec.bTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 159
  euvs_rec.slitTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 161
  euvs_rec.fsw.invalidFlags = buf[lo++]

  lo = 162
  euvs_rec.fsw.detChg_cnt   = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 164
  euvs_rec.fsw.ffChg_cnt    = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

;  euvs_rec.asic.cal.asicCalRamp  = buf[lo++]
;  euvs_rec.asic.cal.asicCalCyclesRemaining = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 166
  euvs_rec.asic.cal.SciVDAC  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 168
  euvs_rec.asic.cal.CalVMin  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 170
  euvs_rec.asic.cal.CalVMax  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 172
  euvs_rec.asic.cal.calVStepUp  = buf[lo++]
  euvs_rec.asic.cal.calTStepUp  = buf[lo++]
  euvs_rec.asic.cal.calVStepDown  = buf[lo++]
  euvs_rec.asic.cal.calTStepDown  = buf[lo++]


  lo = 176
  euvs_rec.exis_mech.doorStatus   = buf[lo++]
  euvs_rec.exis_mech.filterStatus = buf[lo++]
  euvs_rec.exis_mech.doorPosition      = buf[lo++]
  euvs_rec.exis_mech.filterPosition    = buf[lo++]

  euvs_rec.fsw.xrsEuvsMode  = buf[lo++]
  euvs_rec.fsw.FOVFlags  = buf[lo]

  if keyword_set(euvsb) then begin
     ; euvsb
     euvs_rec.current = apply_gain(euvs_rec.diodes, euvs_rec.bTemp, /euvsb) / $
                        (0.25*(euvs_rec.asic.integtime+1.) - 0.011)
  endif else begin
     ; euvsa
     euvs_rec.current = apply_gain(euvs_rec.diodes, euvs_rec.aTemp, /euvsa) / $
                        (0.25*(euvs_rec.asic.integtime+1.) - 0.011)
  endelse

  ; decompose flatfield power status register
  tmp=decompose_ff_power(euvs_rec.ff)
  euvs_rec.ff = tmp


return
end
