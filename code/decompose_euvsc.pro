; $Id: decompose_euvsc.pro 32846 2012-05-11 19:21:37Z dlwoodra $

pro decompose_euvsc, buf, euvsc_rec

  lo=19
  checksum = buf[lo]

  ; check the checksum (starts on byte 20)
  if checksum ne calculate_checksum(buf[20:*]) then begin
     print,'ERROR: CHECKSUM FAILED - EUVS-C packet failed the checksum test'
  endif

  lo = 148
  euvsc_rec.reg.ModeReg        = buf[lo++]
  euvsc_rec.reg.ControlStatReg = buf[lo++]
  euvsc_rec.reg.pwrStatus      = buf[lo++]
  euvsc_rec.reg.integTime      = buf[lo++]

  euvsc_rec.reg.deadTime       = buf[lo++]

  ;lo=153
  euvsc_rec.ff.power = buf[lo++]
  euvsc_rec.ff.level = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 156
  euvsc_rec.ifBoardTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 158
  euvsc_rec.fpgaTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 160
  euvsc_rec.pwrSupplyTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 162
  euvsc_rec.caseHtrTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 164
  euvsc_rec.euvscHtrTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 166
  euvsc_rec.c1Temp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 168
  euvsc_rec.c2Temp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 170
  euvsc_rec.adcTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 172
  euvsc_rec.slitTemp = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 174
  euvsc_rec.fsw.invalidFlags = buf[lo++]
  
  lo = 175
  euvsc_rec.fsw.detChg_cnt   = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 177
  euvsc_rec.fsw.ffChg_cnt    = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 179
  euvsc_rec.exis_mech.doorStatus   = buf[lo++]
  euvsc_rec.exis_mech.filterStatus = buf[lo++]
  euvsc_rec.exis_mech.doorPosition      = buf[lo++]
  euvsc_rec.exis_mech.filterPosition    = buf[lo++]

  euvsc_rec.fsw.xrsEuvsMode = buf[lo++]
  euvsc_rec.fsw.fovFlags    = buf[lo]

  ; decompose flatfield power status register
  tmp=decompose_ff_power(euvsc_rec.ff)
  euvsc_rec.ff = tmp

return
end
