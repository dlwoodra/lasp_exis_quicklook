; docformat = 'rst'

;+
; :Author:
;    Don Woodraska
;
; :Copyright:
;    Copyright 2019 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and
;    Space Physics.
; 
; :Version:
;    $Id: update_pkt_count.pro 81639 2019-05-24 14:03:55Z dlwoodra $
;
;-

;+
;  Update values in an array of structures for use in plot_status_2. The 
;  structure is stored in a common block since values need to be retained
;  from one call to the next.
;
; :Params:
;    pri_hdr: in, required, type=structure
;      a scalar structure defined in gpds_defines.pro with apid and
;      seq_count tags
;
; :Keywords:
;    do_plots: in, optional, type=boolean
;      use keyword to enable all plot windows (disabled by default)
;      Opposite of no_plots in exis_quicklook (the caller of this
;      procedure)
;    print_stats: in, optional, type=boolean
;      set this keyword to display the current packet counts as a
;      table to the terminal window
;
; :Uses:
;    window_set
;
; :Examples:
;    This is not a user callable function. It is called by exis_quicklook::
;    IDL> update_pkt_count, pri_hdr, /do_plots
;
;-
pro update_pkt_count, pri_hdr, do_plots=do_plots, print_stats=print_stats

common update_pkt_count_cal, pkt_stats, byte_counter, last_disp_pkt_stats

if keyword_set(print_stats) then goto, show_print_stats

pri_hdr_len = 7L
; bytes in packet are pri_hdr.pkt_len + pri_hdr_len

;
; initialize if needed
;
if size(pkt_stats,/type) eq 0 then begin
   ; initialize
   byte_counter=0LL
   ;
   ; create aray of structures to count/track packets
   ;
   PKT_STAT_REC = {rec_count:0ULL, gaps:0ULL, apid:0u, seq_cnt:0u, name:'unk', rate_kbps:0., is_exis:0b}

   ; number of packets types to track
   ; sps, xrs, euvsa,  euvsb, euvsc0,c1,c2,c3,c4,c5,c6,c7, tdrift, unk

   ; Convention:
   ;  use index 0 for unknown apids, other apids will be higher values
   ;  use index 0 for unknown apids, other apids will be higher values
   ; 1/24/19 Starting Oct 18, 2018 a new packet appeared with APID 255
   ;  APID 255 is a 20 Hz spacecraft packet of unknown decomposition
   ;  Ryan Williams said it was a replacement for position from 385
   ;  result is that there is a new packet to track
   apid=[       0,    $
              151, 164, 173, 255, 384, 385, $ ;spacecraft
;              151, 164, 173, 384, 385, $ ;spacecraft
              928,     929,     930,     931,          '3b0'xu + uindgen(8),    908,$
              896,    913,     33,      34,$
              909,    899,     901,     903,     905,$
              146,    147,     910,     907,     906,     912,$
              904,    902,     900,     898,    1280]
   ; names are 6 character strings
   name=['unk   ',$
         'SC151 ','SC164 ','SC173 ','SC255','SC384 ','SC385 ',$
         'SPS   ','XRS   ','EUVSA ','EUVSB ','EUVSC'+strtrim(lindgen(8),2), 'TDRFT ',$
         'evtmsg','idac  ','is_an ','is_em ',$
         'memory','rfast ','rmed  ','rslow ','rsystm',$
         'gnd146','gnd147','table ','dwell ','dump  ','det   ',$
         'bsystm','bslow ','bmed  ','bfast ','is_gis ']
   ; set type to 1 for EXIS packets, 0 for other packets
   type=[       0,       $
                0,  0,  0,  0,  0,  0, $ ; spacecraft
                1,       1,       1,       1,      1,1,1,1,1,1,1,1,                1,$
                1,       1,       0,       0,$
                1,       1,       1,       1,       1,$
                0,       0,       1,       1,       1,        1,$
                1,       1,       1,      1,        0]

   ; to add another apid, append it to the list above

   ; sort into apid order
   xs=sort(apid)
   apid=apid[xs]
   name=name[xs]
   type=type[xs]

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
idx=idx[0]
; use index 0 for unknown apids, other apids will be higher values
if n_idx eq 0 then begin
   idx=0
   print,'Unknown apid: '+strtrim(pri_hdr.apid,2)
;   stop
endif

; increment counter
pkt_stats[idx].rec_count++

; look for gaps only for enumerated apids
if idx ne 0 then begin
   if pkt_stats[idx].seq_cnt ne 0 and $
      pri_hdr.pkt_seq_count ne 0 then begin
      if pri_hdr.pkt_seq_count ne (pkt_stats[idx].seq_cnt+1) then begin
         pkt_stats[idx].gaps++
         if pkt_stats[idx].apid ne 255 then $
            print,'GAP - APID: '+strtrim(pkt_stats[idx].apid,2)+' '+pkt_stats[idx].name+' lastSeq='+strtrim(pkt_stats[idx].seq_cnt,2)+' thisSeq='+strtrim(pri_hdr.pkt_seq_count,2)
         ;stop
      endif
   endif
endif

; 4-14-15 Update pkt_stats to current packet values
; without this, the gap checking cannot work on the next call
pkt_stats[idx].seq_cnt = pri_hdr.pkt_seq_count

; 8-17-16 display the name, apid, rec_count, and rate_kbps for each packet
; plus total data rate (sum of rate_kbps)

update_display=0
if pkt_stats[idx].name eq 'bslow ' then update_display=1
if pkt_stats[idx].name eq 'rslow ' then update_display=1
if pkt_stats[idx].name eq 'is_an ' and ((pkt_stats[idx].rec_count mod 10) eq 0) then update_display=1

if update_display eq 1 then begin
   kbps = double(byte_counter) * 8.d0 / 10.d0 / 1024.d0 ; kbits
   ;        (bytes/interval) * (bits/byte) / (sec/interval) / (kilobits)
                                ; the EXIS slow packets are fixed at a
                                ; 10 seconds rate, so the 10 is
                                ; explicitly in the calculation as a constant

   if size(last_disp_pkt_stats,/type) eq 0 then last_disp_pkt_stats = pkt_stats ; initialize

;   print,'EXIS bit rate (kbps) over 10 seconds = '+strtrim(kbps,2)
   byte_counter = 0LL

   if keyword_set(do_plots) then begin
     window_set, 'STATUS-3'
     erase                        ; redraw everything every time
     !p.multi=0

     p_orig=!p
     d_orig=!d

     ; get the current font in use
     device,get_current_font=orig_font
     ;set a device font
     ;device,set_font='7x14'
     device,set_font='7x14bold'
     ;device,set_font='6x13' ; works on NUC
     font=0 ; not true type, 0=device

     maxrows = n_elements(pkt_stats)+2
     ypos=reverse((findgen(maxrows)+1.)/(maxrows+1.))
   
     ; columns are name(6), apid(4), rec_count
     thexpos=findgen(3)/3.1 + 0.02

     co=0
     grayco   ='aaaaaa'xUL
     yellowco ='77dddd'xUL
     redco    = 'fe'xUL
     greenco  = 'aa00'xUL

     ; column titles
     xyouts, thexpos[0], ypos[0], co=co, font=font, /norm, charsize=1.25, "PktName"
     xyouts, thexpos[1], ypos[0], co=co, font=font, /norm, charsize=1.25, "APID"
     xyouts, thexpos[2], ypos[0], co=co, font=font, /norm, charsize=1.25, "Rec_Counter"
     ; data
     for i=0L,n_elements(pkt_stats)-1 do begin
        xyouts, thexpos[0], ypos[i+1], co=co, font=font, /norm, charsize=1.25, pkt_stats[i].name
        xyouts, thexpos[1], ypos[i+1], co=co, font=font, /norm, charsize=1.25, strtrim(pkt_stats[i].apid,2)
        cocount=co
        if pkt_stats[i].rec_count eq last_disp_pkt_stats[i].rec_count then cocount=grayco
        if pkt_stats[i].apid eq 0 then begin
           if pkt_stats[i].rec_count eq 0 then cocount=greenco else cocount=redco
        endif
        xyouts, thexpos[2], ypos[i+1], co=cocount, font=font, /norm, charsize=1.25, strtrim(pkt_stats[i].rec_count,2)
     endfor

     ; write EXIS Data Rate line
     xyouts, thexpos[0], ypos[n_elements(ypos)-1], co=co, font=font, /norm, charsize=1.25, 'EXIS Data Rate kbps '
     kco = greenco
     if kbps lt 9.3 then kco=yellowco
     if kbps lt 1 then kco=redco
     if kbps ge 50 then kco=redco
     xyouts, thexpos[2], ypos[n_elements(ypos)-1], co=kco, font=font, /norm, charsize=1.25, strtrim(string(kbps,form='(f7.3)'),2)

     ; reset default font
     device,set_font=orig_font
     !p.font=p_orig.font

     last_disp_pkt_stats = pkt_stats ; keep the last one
  endif
endif

; calculate bytes in this packet
bytes = pri_hdr.pkt_len + pri_hdr_len

if pkt_stats[idx].is_exis eq 1 then byte_counter += bytes

return

;
; can ony get here if the keyword print_stats set
;
show_print_stats:
print,'Name, APID, Count'
for i=0,n_elements(pkt_stats)-1 do $
   print,pkt_stats[i].name,', ',strtrim(pkt_stats[i].apid,2),', ',strtrim(pkt_stats[i].rec_count,2)

return
end
