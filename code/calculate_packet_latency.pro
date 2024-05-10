function calculate_packet_latency, pkt

  common calculate_packet_latency_cal, epoch_in_unixtime

  if size(epoch_in_unixtime,/type) eq 0 then begin
     epoch_in_jd=julday(1,1,2000,0.,0.,0.) ; GOES-R TLM epoch

     current_unixtime=systime(1) ; current unix seconds since 1970
     current_jd=systime(/jul,/utc) ; current julian date in UT, (assume instantaneous with unix time)

     epoch_in_unixtime= current_unixtime - ((current_jd - epoch_in_jd)*86400.d)
  endif

  delta_unix_seconds = systime(1) - epoch_in_unixtime
  ;RTsod = delta_unix mod 86400.d
  RTmicroSecSinceEpoch = long64(delta_unix_seconds * 1.d6) 
  
  ; return the difference in microseconds
  microsec = RTmicroSecSinceEpoch - pkt.time.microSecondsSinceEpoch

return,microsec
end
