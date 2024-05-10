; $Id: decompose_xrs.pro 40609 2013-02-16 01:14:56Z dlwoodra $

pro decompose_xrs, buf, xrs_rec, user_flags=user_flags, do_darkxrs=do_darkxrs

@gpds_defines.pro

; extract data from byte-array (buf) and populate xrs_rec

  ; 3/21/11 DLW - removed checksum 
  lo=19
  checksum = buf[lo]

  ; check the checksum (starts on byte 20)
  if checksum ne calculate_checksum(buf[20:*]) then begin
     print,'ERROR: CHECKSUM FAILED - XRS packet failed the checksum test'
  endif
  
  ; diode data
  lo=20
  hi = 55
  xrs_data = (ishft(ulong(buf[lo:hi:3]) AND 'F'xUL,16)) + $
             ishft(ulong(buf[lo+1:hi:3]),8) + $
             ulong(buf[lo+2:hi:3])
  ; tlm order is d1, b21,b22,b23,b24, a1, a21,a22,a23,a24, b1,d2 ;V11 6/15/10
  ;tmp = xrs_data[[1,2,3,4,5,0]] ; XRS-B ordering is OK
  ;xrs_data[0:5] = tmp

  xrs_rec.diodes = xrs_data

  ; asic offsets
  lo = 56
  hi = 79
  offset = (ishft(uint(buf[lo:hi:2]) AND '3F'xu,8)) + $
           uint(buf[lo+1:hi:2])

  ;; reorder XRS-A to match email from Greg N 11-05-09
  ;offset = xrs_rec.offset[[1,2,3,4,5,0]]
  xrs_rec.offset = offset
  
  lo = 80
  xrs_rec.asic.runCtrl    = buf[lo++]
  xrs_rec.asic.SciMode    = buf[lo++]
  xrs_rec.asic.pwrStatus  = buf[lo++]
  xrs_rec.asic.integTime  = buf[lo++]

  xrs_rec.ff.power = buf[lo++]
  xrs_rec.ff.level = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 87
  xrs_rec.ifBoardTemp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 89
  xrs_rec.fpgaTemp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 91
  xrs_rec.pwrSupplyTemp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 93
  xrs_rec.caseHtrTemp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 95
  xrs_rec.asic1Temp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 97
  xrs_rec.asic2Temp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 99
  xrs_rec.filterTemp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 101
  xrs_rec.magnetTemp = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 103
  xrs_rec.fsw.invalidFlags   = buf[lo]

  lo = 104
  xrs_rec.fsw.detChg_cnt     = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  lo = 106
  xrs_rec.fsw.ffChg_cnt      = ishft((uint(buf[lo])),8) + uint(buf[lo+1])

  ;xrs_rec.asic.cal.asicCalRamp    = buf[lo++]
  ;lo = 108
  ;xrs_rec.asic.cal.asicCalCyclesRemaining = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 108
  xrs_rec.asic.cal.SciVDAC  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 110
  xrs_rec.asic.cal.CalVMin  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 112
  xrs_rec.asic.cal.CalVMax  = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

  lo = 114
  xrs_rec.asic.cal.calVStepUp  = buf[lo++]
  xrs_rec.asic.cal.calTStepUp  = buf[lo++]
  xrs_rec.asic.cal.calVStepDown  = buf[lo++]
  xrs_rec.asic.cal.calTStepDown  = buf[lo++]

  xrs_rec.fsw.xrsEuvsMode  = buf[lo++]
  xrs_rec.fsw.FOVFlags  = buf[lo]

; populate current (gain correction)
  xrs_rec.current = apply_gain(xrs_rec.diodes, xrs_rec.asic1Temp, /xrs)

  dark=0. ; assume no dark needed
  if keyword_set(do_darkxrs) then $
     dark = apply_xrs_dark( user_flags.pwr_status, xrs_rec.asic1Temp, inttime, /famps)

  invdenom = 1.0 / (0.25*(xrs_rec.asic.integtime+1.) - 0.011)

  xrs_rec.signal = ((xrs_rec.current - dark)*invdenom) > 0.     ; prevent negative signal

  ; decompose flatfield power status register
  tmp=decompose_ff_power(xrs_rec.ff)
  xrs_rec.ff = tmp

return
end
