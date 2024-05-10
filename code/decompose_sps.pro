; $Id: decompose_sps.pro 32836 2012-05-11 00:54:53Z dlwoodra $

pro decompose_sps, buf, sps_rec

@gpds_defines.pro

; extract data from byte-array (buf) and populate sps_rec

; endian-independence is guaranteed (and required for zuul/staypuft compatibility)

  lo=19
  checksum = buf[lo]

  ; check the checksum (starts on byte 20)
  if checksum ne calculate_checksum(buf[20:*]) then begin
     print,'ERROR: CHECKSUM FAILED - SPS packet failed the checksum test'
  endif

  lo = 20
  hi = 37
  sps_data = (ishft(ulong(buf[lo:hi:3]) AND 'F'xUL,16)) + $
             ishft(ulong(buf[lo+1:hi:3]),8) + $
             ulong(buf[lo+2:hi:3])
  
  sps_rec.diodes = sps_data
  lo = 38
  hi = 49
  sps_rec.offset = (ishft(uint(buf[lo:hi:2]) AND '3F'xu,8)) + $
                   uint(buf[lo+1:hi:2])
  
  lo = 50
  sps_rec.asic.runCtrl     = buf[lo++]
  sps_rec.asic.SciMode     = buf[lo++]
  sps_rec.asic.pwrStatus   = buf[lo++]
  sps_rec.asic.integTime   = buf[lo++]

  lo = 54
  sps_rec.ifBoardTemp  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 56
  sps_rec.fpgaTemp  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 58
  sps_rec.pwrSupplyTemp  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 60
  sps_rec.caseHtrTemp  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 62
  sps_rec.temperature  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 64
  sps_rec.fsw.invalidFlags = buf[lo++]
  sps_rec.fsw.detChg_cnt   = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  ;lo = 67
  ;sps_rec.asic.cal.asicCalRamp  = buf[lo++]

  ;lo = 68
  ;sps_rec.asic.cal.asicCalCyclesRemaining  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 67
  sps_rec.asic.cal.SciVDAC  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 69
  sps_rec.asic.cal.CalVMin  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 71
  sps_rec.asic.cal.CalVMax  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 73
  sps_rec.asic.cal.CalVStepUp  = buf[lo++]
  sps_rec.asic.cal.CalTStepUp  = buf[lo++]
  sps_rec.asic.cal.CalVStepDown  = buf[lo++]
  sps_rec.asic.cal.CalTStepDown  = buf[lo++]

  sps_rec.fsw.xrsEuvsMode  = buf[lo++]
  sps_rec.fsw.FOVFlags  = buf[lo]

  ; populate current (gain correction)
  sps_rec.current = apply_gain(sps_rec.diodes, sps_rec.temperature, /sps) / $
                    (0.25*(sps_rec.asic.integtime+1.) - 0.011)

return
end
