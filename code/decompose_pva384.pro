; $Id$

pro decompose_pva384, buf, pva_rec

@gpds_defines.pro

; extract data from byte-array (buf) and populate pva_rec

; endian-independence is NOT guaranteed because of the use of FLOATS
; in telemetry
; Definition is from ABI_APID_SC_OandA_Data1-1.docx

  lo=20
  quat = fltarr(4)
  for component=0,3 do begin
     ; assemble the float from 4 bytes
     quat[component] = float( reverse(buf[lo:lo+3]), 0, 1 ) ;NOT endian independent
     lo += 4
  endfor

  pva_rec.sc_quaternion = quat

  ; skip 2 bytes spare
  lo += 2

  ; position and velocity part has another time stamp
  ; ...copied from the secondary decomposition make_sec_hdr.pro...
  array = buf[lo:lo+8]
  postime = CCSDS_SEC_HDR
  postime.day      = ishft(array[0],16) + ishft(array[1],8) + array[2]
  postime.millisec = ishft(array[3],24) + ishft(array[4],16) + $
                  ishft(array[5],8) + array[6]
  postime.microsec = uint(ishft(array[7],8) + array[8])

  pva_rec.postime = postime

  lo += 10

  position = fltarr(3)
  for component=0,2 do begin
     ; assemble the float from 4 bytes
     position[component] = float( reverse(buf[lo:lo+3]), 0, 1 ) ;NOT endian independent
     lo += 4
  endfor

  pva_rec.sc_position = position

  velocity = fltarr(3)
  for component=0,2 do begin
     ; assemble the float from 4 bytes
     velocity[component] = float( reverse(buf[lo:lo+3]), 0, 1 ) ;NOT endian independent
     lo += 4
  endfor

  pva_rec.sc_velocity = velocity

return
end
