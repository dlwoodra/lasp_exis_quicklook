; $Id: decompose_tdrift.pro 35662 2012-09-13 22:11:32Z dlwoodra $

pro decompose_tdrift, buf, tdrift_rec

@gpds_defines.pro

; extract data from byte-array (buf) and populate tdrift_rec

; endian-independence is guaranteed (and required for zuul/staypuft compatibility)

  lo=19
  checksum = buf[lo]

  ; check the checksum (starts on byte 20)
  if checksum ne calculate_checksum(buf[20:*]) then begin
     print,'ERROR: CHECKSUM FAILED - TDRIFT packet failed the checksum test'
  endif

  stride=28L ; number of bytes per time entry

  number_of_time_entries = 5

  for i=0L,number_of_time_entries-1 do begin
     lo = 20L + (i*stride)
     tdrift_rec.td[i].localTimeState = buf[lo]

     lo++ ; 21
     tdrift_rec.td[i].pendDay = ishft(long(buf[lo]),16) + $
                                ishft(long(buf[lo+1]),8) + long(buf[lo+2])
     lo += 3 ; 24
     tdrift_rec.td[i].pendMillisec = ishft(ulong(buf[lo]),24) + ishft(ulong(buf[lo+1]),16) + $
                                ishft(ulong(buf[lo+2]),8) + ulong(buf[lo+3])
     
     lo += 4 ; 28
     tdrift_rec.td[i].pendMicrosec = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

     lo += 2 ; 30
     tdrift_rec.td[i].freeWheelCnt = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

     lo += 2 ; 32
     tdrift_rec.td[i].spwLinkRxTimeTick = buf[lo]

     lo++ ; 33
     tdrift_rec.td[i].lastDay = ishft(long(buf[lo]),16) + $
                                ishft(long(buf[lo+1]),8) + long(buf[lo+2])
     lo += 3 ; 36
     tdrift_rec.td[i].lastMillisec = ishft(ulong(buf[lo]),24) + ishft(ulong(buf[lo+1]),16) + $
                                ishft(ulong(buf[lo+2]),8) + ulong(buf[lo+3])
     
     lo += 4 ; 40
     tdrift_rec.td[i].lastMicrosec = ishft(uint(buf[lo]),8) + uint(buf[lo+1])

     lo += 2 ; 42
     tdrift_rec.td[i].scTimeMsgNotRecvdCnt = buf[lo]

     lo++ ; 43
     tdrift_rec.td[i].scTimeCodeNotRecvdCnt = buf[lo]

     lo++ ; 44
     tdrift_rec.td[i].spwLinkRxTimePrevMaxMicrosec = $
        ishft(ulong(buf[lo]),24) + ishft(ulong(buf[lo+1]),16) + $
        ishft(ulong(buf[lo+2]),8) + ulong(buf[lo+3])
     
  endfor

return
end
