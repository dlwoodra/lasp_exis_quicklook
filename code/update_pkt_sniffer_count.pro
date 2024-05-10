; docformat = 'rst'

;+
; :Author:
;    Don Woodraska
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
; 
; :Version:
;    $Id: update_pkt_sniffer_count.pro 67754 2015-05-27 19:53:21Z dlwoodra $
;
;-

;+
;  Update values in an array of structures for use in plot_status_2. The 
;  structure is stored in a common block since values need to be retained
;  from one call to the next.
;
; :Params:
;    pri_hdr: in, required, type=structure
;      a scalar structure defined in gpds_defines.pro with apid and seq_count tags
;
; :Examples:
;    This is not a user callable function. It is called by exis_quicklook::
;    IDL> update_pkt_count, pri_hdr
;
;-
pro update_pkt_sniffer_count, pri_hdr

common update_pkt_sniffer_count_cal, pkt_stats, bit_counter

pri_hdr_len = 7L
; bytes in packet are pri_hdr.pkt_len + pri_hdr_len

;
; initialize if needed
;
if size(pkt_stats,/type) eq 0 then begin
   ; initialize
   bit_counter=0LL

   ;
   ; create aray of structures to count/track packets
   ;
   PKT_STAT_REC = {count:0ULL, gaps:0ULL, apid:0u, seq_cnt:0u, name:'unk', $
                   is_exis:0}

   ; number of packets types to track
   ; sps, xrs, euvsa,  euvsb, euvsc0,c1,c2,c3,c4,c5,c6,c7, tdrift, unk

   ; Convention:
   ;  use index 0 for unknown apids, other apids will be higher values
   apid=[    0, 928,  929,    930,    931,          '3b0'xu + uindgen(8),     908,     896,   913,       33,       34,     909,    899,   901,   903,       905,     147,    910,    907 ,  906,  912,      904,    902,   900,    898]
   name=['unk','SPS','XRS','EUVSA','EUVSB','EUVSC'+strtrim(lindgen(8),2), 'TDRFT','evtmsg','idac','isis_an','isis_em','memory','rfast','rmed','rslow','rsystem','sc_pkt','table','dwell','dump','det','bsystem','bslow','bmed','bfast']
   type=[    0,   1,    1,       1,      1,      1,1,1,1,1,1,1,1,               1,       1,     1,        0,        0,       1,      1,     1,      1,       1,        0,     1,      1,     1,     1,       1,      1,      1,      1]

   ; to add another apid, append it to the list above

   pkt_stats = replicate(PKT_STAT_REC, n_elements(apid))

   pkt_stats.apid = apid
   pkt_stats.name = name
   pkt_stats.is_exis = type ; exis is 1, non exis is 0

   print,'Tracking packets', name, apid

                                ; since slow packet is 10 seconds in
                                ; both boot and ram, use bslow or slow
                                ; to calculate bit rate
   ;
endif

; find the index of the array for this apid
idx = where(pri_hdr.apid eq pkt_stats.apid, n_idx)

; use index 0 for unknown apids, other apids will be higher values
if n_idx eq 0 then begin
   idx=0
   print,'Unknown apid: '+strtrim(pri_hdr.apid,2)
;   stop
endif

; increment counter
pkt_stats[idx].count++

; look for gaps only for enumerated apids
if idx ne 0 then begin
   if pkt_stats[idx].seq_cnt ne 0 and $
      pri_hdr.pkt_seq_count ne 0 then begin
      if pri_hdr.pkt_seq_count ne pkt_stats[idx].seq_cnt+1 then $
         pkt_stats[idx].gaps++
   endif
endif

;stop
; print stats assuming a 10 second rate between slow packets
if pkt_stats[idx].name eq 'bslow' or pkt_stats[idx].name eq 'rslow' then begin
   kbps = double(bit_counter) * 8.d0 / 10.d0 / 1024.d0 ; kbits
   ;        (bytes/interval) * (bits/byte) / (sec/interval) / (kilobits)
   print,'EXIS bit rate (kbps) over 10 seconds = '+strtrim(kbps,2)
   bit_counter = 0LL
   ;print,'cnt bsystem, blsow, bmed, bfast, unk'
   ;bootidx = [28,29,30,31,0]
   ;print,strtrim(pkt_stats[bootidx].count,2)
   print,strtrim(pkt_stats.name,2)
   print,strtrim(pkt_stats.count,2)
endif
;print,strtrim(pkt_stats.name,2)
;print,strtrim(pkt_stats.count,2)


; calculate bits in this packet
bits = pri_hdr.pkt_len + pri_hdr_len

if pkt_stats[idx].is_exis eq 1 then bit_counter += bits


return
end
