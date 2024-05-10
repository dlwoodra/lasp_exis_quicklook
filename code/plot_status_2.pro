pro plot_status_2, xrs_rec, euvsa_rec, euvsb_rec, euvsc_rec, sps_rec, tdrift_rec

common plot_status_2_cal, lastxrs, errmessages, errco, normmessages, normco, lasttime, displaycount, latency, latco

common update_pkt_count_cal, pkt_stats, byte_counter, last_disp_pkt_stats

thistime = (sps_rec.time.sod > xrs_rec.time.sod > $
            euvsa_rec.time.sod > euvsb_rec.time.sod > $
            euvsc_rec.time.sod)
if size(lasttime,/type) eq 0 then lasttime=-1.

; define colors
FFcolor='cc0000'xUL
grayco='aaaaaa'xUL
yellowco='77dddd'xUL
redco   = 'fe'xUL
greenco = 'aa00'xUL
co=0

if size(lastxrs,/type) eq 0 then begin
   lastxrs=xrs_rec
   n_errm = 16
   n_normm = 16
   errmessages = strarr(n_errm)
   errco       = ulonarr(n_errm)
   normmessages =  strarr(n_normm)
   normco       = ulonarr(n_normm)
   latency      =  strarr(n_normm)
   latco        = ulonarr(n_normm)
   displaycount = 0
endif else begin
   ; compare xrs_rec to lastxrs
   ;microsecdiff = xrs_rec.sec_hdr.microSecondsSinceEpoch - lastxrs.microSecondsSinceEpoch
   microsecPredict = long64(lastxrs.time.microSecondsSinceEpoch) + ishft((long64(xrs_rec.asic.integTime+1ULL)*1000000ULL),-2)
   timediff = long64(xrs_rec.time.microSecondsSinceEpoch) - long64(microsecPredict)

   ; set the normal time difference message color
   normco    = shift(normco,1)
   normco[0] = co ; default color is black
   absolutetimediff = abs(timediff)
   if absolutetimediff gt 1000LL then normco[0] = FFcolor ; >1 millisecond happens occasionally with ESTE
   if absolutetimediff gt 10000LL then normco[0] = yellowco ; >10 milliseconds
   if absolutetimediff gt 1000000LL then normco[0] = redco ; >1 second

   ;
   ; new test to prevent leakage test from going bonkers
   ; the xrs cadence becomes 1/4 second, but the int time remains 3
   ; only during the leakage test at SURF
   ;
   isleakage=0
   if fix(xrs_rec.asic.runctrl) eq 2 then isleakage=1

   normmessages    = shift(normmessages,1)
   normmessages[0] = xrs_rec.time.hms+' XRS '+strtrim(timediff,2)

   if isleakage eq 1 then begin
      ; replace the normmessage
      normco[0] = grayco
      normmessages[0] = xrs_rec.time.hms+' XRS LKG '+strtrim(timediff,2)
   endif


   threshold = 250000LL / 2 ; half a quarter of a second
   ; if time difference is unexpected, print something
   if absolutetimediff gt threshold then begin
      errmessages = shift(errmessages,1)
      errco = shift(errco,1)
      if xrs_rec.asic.runctrl ne lastxrs.asic.runctrl then begin
         errmessages[0] = xrs_rec.time.hms+' CAL change, TIME unexpected, last XRS was '+lastxrs.time.hms+' diff='+strtrim(timediff,2)
         errco[0] = FFcolor
      endif else begin
         if ( xrs_rec.asic.runctrl ne 2 ) then begin ; ignore gain cal, those are always 1 Hz no matter what inttime is
            errmessages[0] = xrs_rec.time.hms+' TIME unexpected, last XRS was '+lastxrs.time.hms+' diff='+strtrim(timediff,2)
            errco[0] = redco
            ; replace the error string if the leakage test is going on
            if isleakage eq 1 then begin
               errco[0] = grayco
               errmessages[0] = xrs_rec.time.hms+' XRS possible leakage test'
            endif
         endif
      endelse
      ;stop
      
   endif


   ; now look for sequence gaps
   if lastxrs.pri_hdr.pkt_seq_count ne 16383 and xrs_rec.pri_hdr.pkt_seq_count ne 0 then begin
      cntdiff = long(xrs_rec.pri_hdr.pkt_seq_count) - long(lastxrs.pri_hdr.pkt_seq_count)
      if cntdiff ne 1 then begin
         errmessages = shift(errmessages,1)
         errmessages[0] = xrs_rec.time.hms+' SEQ CNT unexpected '+strtrim(xrs_rec.pri_hdr.pkt_seq_count,2)+$
                       ' should be '+strtrim(lastxrs.pri_hdr.pkt_seq_count+1L,2)+' DATA GAP FOUND'
      errco = shift(errco,1)
      errco[0] = redco
      endif
   endif

   ; now compare packet time to system clock to measure total latency
   latency    = shift(latency,1)
   latency[0] = calculate_packet_latency(xrs_rec)
   latco = shift(latco,1)
   latco[0] = co
   if latency[0] gt 125000LL then latco[0] = FFcolor
   if latency[0] gt 500000LL then latco[0] = yellowco
   ;if latency[0] gt 1000000LL then latco[0] = redco
   if latency[0] gt 2000000LL then latco[0] = redco ; 2 seconds
   
   lastxrs=xrs_rec
   displaycount = (displaycount+1) mod 3
endelse

; limit display updates to 3 seconds
;if displaycount ne 0 then return
; if time difference ge 3 sec or the day had rolled over execute
if thistime-lasttime lt 3 and lasttime lt thistime then return
lasttime=thistime

window_set, 'STATUS-2'
erase ; redraw everything every time
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

; 6 columns defined using ..._xpos, many rows defined as maxrows
maxrows = float(33)
ypos=reverse((findgen(maxrows)+1.)/(maxrows+1.))

thexpos=findgen(6)/6.1 + 0.02


exismode=['Failsafe','Normal','Diag','Safe']

; SPS
sps_xpos = thexpos[0] ;0.03

co=0
if abs(sps_rec.time.sod - thistime) ge 64 then co=grayco

row=0
xyouts,font=font,/norm,sps_xpos,ypos[row++],'SPS',charsize=1.5

; deal with quicklook packet counters and gaps
pkidx = where(strtrim(pkt_stats.name,2) eq 'SPS') ; must find the index for this packet type
pkidx=pkidx[0]
if pkidx ne -1 then begin
   xyouts,font=font,/norm,sps_xpos,ypos[row++],'Cnt:'+strtrim(pkt_stats[pkidx].rec_count,2),charsize=1.25,co=co
   gapco=co                     ; assume normal color
   if pkt_stats[pkidx].rec_count ne 0 then gapco=greenco
   if pkt_stats[pkidx].gaps ne 0 then gapco=redco
   xyouts,font=font,/norm,sps_xpos,ypos[row++],'Gaps:'+strtrim(pkt_stats[pkidx].gaps,2),charsize=1.25,co=gapco
endif

xyouts,font=font,/norm,sps_xpos,ypos[row++],sps_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(sps_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrVerNum: '+strtrim(fix(sps_rec.pri_hdr.ver_num),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrType: '+strtrim(fix(sps_rec.pri_hdr.type),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrSecHdrFlag: '+strtrim(fix(sps_rec.pri_hdr.sec_hdr_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrAPID: '+strtrim(fix(sps_rec.pri_hdr.apid),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrSeqFlag: '+strtrim(fix(sps_rec.pri_hdr.seq_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrSeqCnt: '+strtrim(fix(sps_rec.pri_hdr.pkt_seq_count),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'PriHdrPktLen: '+strtrim(fix(sps_rec.pri_hdr.pkt_len),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'SecHdrDay: '+strtrim(ulong(sps_rec.sec_hdr.day),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'SecHdrMilSec: '+strtrim(ulong(sps_rec.sec_hdr.millisec),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'SecHdrMicSec: '+strtrim(uint(sps_rec.sec_hdr.microsec),2),charsize=1.25,co=co
xyouts,font=font,/norm,sps_xpos,ypos[row++],'SecHdrUF: '+strtrim(ulong(sps_rec.sec_hdr.userflags),2),charsize=1.25,co=co


; XRS
xrs_xpos = thexpos[1] ;0.20

co=0
if abs(xrs_rec.time.sod - thistime) ge 64 then co=grayco
;lastxrstime_sod = xrs_rec.time.sod

row=0
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'XRS',charsize=1.5

; deal with quicklook packet counters and gaps
pkidx = where(strtrim(pkt_stats.name,2) eq 'XRS') ; must find the index for this packet type
pkidx=pkidx[0]
if pkidx ne -1 then begin
   xyouts,font=font,/norm,xrs_xpos,ypos[row++],'Cnt:'+strtrim(pkt_stats[pkidx].rec_count,2),charsize=1.25,co=co
   gapco=co                     ; assume normal color
   if pkt_stats[pkidx].rec_count ne 0 then gapco=greenco
   if pkt_stats[pkidx].gaps ne 0 then gapco=redco
   xyouts,font=font,/norm,xrs_xpos,ypos[row++],'Gaps:'+strtrim(pkt_stats[pkidx].gaps,2),charsize=1.25,co=gapco
endif

xyouts,font=font,/norm,xrs_xpos,ypos[row++],xrs_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(xrs_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrVerNum: '+strtrim(fix(xrs_rec.pri_hdr.ver_num),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrType: '+strtrim(fix(xrs_rec.pri_hdr.type),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrSecHdrFlag: '+strtrim(fix(xrs_rec.pri_hdr.sec_hdr_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrAPID: '+strtrim(fix(xrs_rec.pri_hdr.apid),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrSeqFlag: '+strtrim(fix(xrs_rec.pri_hdr.seq_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrSeqCnt: '+strtrim(fix(xrs_rec.pri_hdr.pkt_seq_count),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'PriHdrPktLen: '+strtrim(fix(xrs_rec.pri_hdr.pkt_len),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'SecHdrDay: '+strtrim(ulong(xrs_rec.sec_hdr.day),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'SecHdrMilSec: '+strtrim(ulong(xrs_rec.sec_hdr.millisec),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'SecHdrMicSec: '+strtrim(uint(xrs_rec.sec_hdr.microsec),2),charsize=1.25,co=co
xyouts,font=font,/norm,xrs_xpos,ypos[row++],'SecHdrUF: '+strtrim(ulong(xrs_rec.sec_hdr.userflags),2),charsize=1.25,co=co


; EUVS-A
euvsa_xpos = thexpos[2] ;0.37

co=0
if abs(euvsa_rec.time.sod - thistime) ge 64 then co=grayco
;lasteuvsatime_sod = euvsa_rec.time.sod

row=0
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'EUVS-A',charsize=1.5

; deal with quicklook packet counters and gaps
pkidx = where(strtrim(pkt_stats.name,2) eq 'EUVSA') ; must find the index for this packet type
pkidx=pkidx[0]
if pkidx ne -1 then begin
   xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'Cnt:'+strtrim(pkt_stats[pkidx].rec_count,2),charsize=1.25,co=co
   gapco=co                     ; assume normal color
   if pkt_stats[pkidx].rec_count ne 0 then gapco=greenco
   if pkt_stats[pkidx].gaps ne 0 then gapco=redco
   xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'Gaps:'+strtrim(pkt_stats[pkidx].gaps,2),charsize=1.25,co=gapco
endif

xyouts,font=font,/norm,euvsa_xpos,ypos[row++],euvsa_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(euvsa_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrVerNum: '+strtrim(fix(euvsa_rec.pri_hdr.ver_num),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrType: '+strtrim(fix(euvsa_rec.pri_hdr.type),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrSecHdrFlag: '+strtrim(fix(euvsa_rec.pri_hdr.sec_hdr_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrAPID: '+strtrim(fix(euvsa_rec.pri_hdr.apid),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrSeqFlag: '+strtrim(fix(euvsa_rec.pri_hdr.seq_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrSeqCnt: '+strtrim(fix(euvsa_rec.pri_hdr.pkt_seq_count),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'PriHdrPktLen: '+strtrim(fix(euvsa_rec.pri_hdr.pkt_len),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'SecHdrDay: '+strtrim(ulong(euvsa_rec.sec_hdr.day),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'SecHdrMilSec: '+strtrim(ulong(euvsa_rec.sec_hdr.millisec),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'SecHdrMicSec: '+strtrim(uint(euvsa_rec.sec_hdr.microsec),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsa_xpos,ypos[row++],'SecHdrUF: '+strtrim(ulong(euvsa_rec.sec_hdr.userflags),2),charsize=1.25,co=co


; EUVS-B
euvsb_xpos = thexpos[3] ;0.54

co=0
if abs(euvsb_rec.time.sod - thistime) ge 64 then co=grayco
;lasteuvsbtime_sod = euvsb_rec.time.sod

row=0
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'EUVS-B',charsize=1.5

; deal with quicklook packet counters and gaps
pkidx = where(strtrim(pkt_stats.name,2) eq 'EUVSB') ; must find the index for this packet type
pkidx=pkidx[0]
if pkidx ne -1 then begin
   xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'Cnt:'+strtrim(pkt_stats[pkidx].rec_count,2),charsize=1.25,co=co
   gapco=co                     ; assume normal color
   if pkt_stats[pkidx].rec_count ne 0 then gapco=greenco
   if pkt_stats[pkidx].gaps ne 0 then gapco=redco
   xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'Gaps:'+strtrim(pkt_stats[pkidx].gaps,2),charsize=1.25,co=gapco
endif

xyouts,font=font,/norm,euvsb_xpos,ypos[row++],euvsb_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(euvsb_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrVerNum: '+strtrim(fix(euvsb_rec.pri_hdr.ver_num),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrType: '+strtrim(fix(euvsb_rec.pri_hdr.type),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrSecHdrFlag: '+strtrim(fix(euvsb_rec.pri_hdr.sec_hdr_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrAPID: '+strtrim(fix(euvsb_rec.pri_hdr.apid),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrSeqFlag: '+strtrim(fix(euvsb_rec.pri_hdr.seq_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrSeqCnt: '+strtrim(fix(euvsb_rec.pri_hdr.pkt_seq_count),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'PriHdrPktLen: '+strtrim(fix(euvsb_rec.pri_hdr.pkt_len),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'SecHdrDay: '+strtrim(ulong(euvsb_rec.sec_hdr.day),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'SecHdrMilSec: '+strtrim(ulong(euvsb_rec.sec_hdr.millisec),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'SecHdrMicSec: '+strtrim(uint(euvsb_rec.sec_hdr.microsec),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsb_xpos,ypos[row++],'SecHdrUF: '+strtrim(ulong(euvsb_rec.sec_hdr.userflags),2),charsize=1.25,co=co


; EUVS-C
euvsc_xpos = thexpos[4] ;0.71

co=0
if abs(euvsc_rec.time.sod - thistime) ge 64 then co=grayco
;lasteuvsctime_sod = euvsc_rec.time.sod

row=0
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'EUVS-C',charsize=1.5

; deal with quicklook packet counters and gaps
pkidx = where(strtrim(pkt_stats.name,2) eq 'EUVSC0') ; must find the index for this packet type
pkidx=pkidx[0]
if pkidx ne -1 then begin
   xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'Cnt0-7:'+strtrim(round(total(pkt_stats[pkidx+lindgen(8)].rec_count)),2),charsize=1.25,co=co
   gapco=co                     ; assume normal color
   if pkt_stats[pkidx].rec_count ne 0 then gapco=greenco
   if pkt_stats[pkidx].gaps ne 0 then gapco=redco
   xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'Gaps0-7:'+strtrim((round(total(pkt_stats[pkidx+lindgen(8)].gaps))),2),charsize=1.25,co=gapco
endif

xyouts,font=font,/norm,euvsc_xpos,ypos[row++],euvsc_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(euvsc_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrVerNum: '+strtrim(fix(euvsc_rec.pri_hdr.ver_num),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrType: '+strtrim(fix(euvsc_rec.pri_hdr.type),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrSecHdrFlag: '+strtrim(fix(euvsc_rec.pri_hdr.sec_hdr_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrAPID: '+strtrim(fix(euvsc_rec.pri_hdr.apid),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrSeqFlag: '+strtrim(fix(euvsc_rec.pri_hdr.seq_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrSeqCnt: '+strtrim(fix(euvsc_rec.pri_hdr.pkt_seq_count),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'PriHdrPktLen: '+strtrim(fix(euvsc_rec.pri_hdr.pkt_len),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'SecHdrDay: '+strtrim(ulong(euvsc_rec.sec_hdr.day),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'SecHdrMilSec: '+strtrim(ulong(euvsc_rec.sec_hdr.millisec),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'SecHdrMicSec: '+strtrim(uint(euvsc_rec.sec_hdr.microsec),2),charsize=1.25,co=co
xyouts,font=font,/norm,euvsc_xpos,ypos[row++],'SecHdrUF: '+strtrim(ulong(euvsc_rec.sec_hdr.userflags),2),charsize=1.25,co=co


; Tdrift
tdrift_xpos = thexpos[5] ;0.71

co=0
if abs(tdrift_rec.time.sod - thistime) ge 64 then co=grayco
;lasttdrifttime_sod = tdrift_rec.time.sod

row=0
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'TimeDrift',charsize=1.5

; deal with quicklook packet counters and gaps
pkidx = where(strtrim(pkt_stats.name,2) eq 'TDRFT') ; must find the index for this packet type
pkidx=pkidx[0]
if pkidx ne -1 then begin
   xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'Cnt:'+strtrim(pkt_stats[pkidx].rec_count,2),charsize=1.25,co=co
   gapco=co                     ; assume normal color
   if pkt_stats[pkidx].rec_count ne 0 then gapco=greenco
   if pkt_stats[pkidx].gaps ne 0 then gapco=redco
   xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'Gaps:'+strtrim(pkt_stats[pkidx].gaps,2),charsize=1.25,co=gapco
endif

xyouts,font=font,/norm,tdrift_xpos,ypos[row++],tdrift_rec.time.hms,charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'UFTimeValid: '+strtrim(fix(tdrift_rec.sec_hdr.uf.timevalid),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrVerNum: '+strtrim(fix(tdrift_rec.pri_hdr.ver_num),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrType: '+strtrim(fix(tdrift_rec.pri_hdr.type),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrSecHdrFlag: '+strtrim(fix(tdrift_rec.pri_hdr.sec_hdr_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrAPID: '+strtrim(fix(tdrift_rec.pri_hdr.apid),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrSeqFlag: '+strtrim(fix(tdrift_rec.pri_hdr.seq_flag),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrSeqCnt: '+strtrim(fix(tdrift_rec.pri_hdr.pkt_seq_count),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'PriHdrPktLen: '+strtrim(fix(tdrift_rec.pri_hdr.pkt_len),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'SecHdrDay: '+strtrim(ulong(tdrift_rec.sec_hdr.day),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'SecHdrMilSec: '+strtrim(ulong(tdrift_rec.sec_hdr.millisec),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'SecHdrMicSec: '+strtrim(uint(tdrift_rec.sec_hdr.microsec),2),charsize=1.25,co=co
xyouts,font=font,/norm,tdrift_xpos,ypos[row++],'SecHdrUF: '+strtrim(ulong(tdrift_rec.sec_hdr.userflags),2),charsize=1.25,co=co

titlerow=row

ypos[titlerow:*] -= 0.01

row++

startrow=row ; save this row value for normmessages to align properly
msg_xpos = sps_xpos+0.01
xyouts,font=font,/norm,msg_xpos,ypos[titlerow],'Error/Warning Messages',charsize=1.25,co=FFcolor
for i=0,n_elements(errmessages)-1 do $
   xyouts,font=font,/norm,msg_xpos,ypos[row++],strtrim(errmessages[i],2),charsize=1.25,co=errco[i]

row=startrow ; reset row to begin at the same spot
ms_xpos = euvsc_xpos - 0.04
xyouts,font=font,/norm,ms_xpos,ypos[titlerow],'Microsec time diff from predict',charsize=1.25,co=FFcolor
for i=0,n_elements(normmessages)-1 do $
   xyouts,font=font,/norm,ms_xpos,ypos[row++],strtrim(normmessages[i],2),charsize=1.25,co=normco[i]

row=startrow ; reset row to begin at the same spot
ms_xpos = tdrift_xpos + 0.04
xyouts,font=font,/norm,ms_xpos,ypos[titlerow],'Latency microsec',charsize=1.25,co=FFcolor
for i=0,n_elements(latency)-1 do $
   xyouts,font=font,/norm,ms_xpos,ypos[row++],strtrim(latency[i],2),charsize=1.25,co=latco[i]


; reset default font
device,set_font=orig_font
!p.font=p_orig.font

return
end
