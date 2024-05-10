; $Id: plot_spectrum_dn.pro 76142 2016-08-18 18:07:33Z dlwoodra $

pro oplot_val_on_bar_plot, x, current=current, good=good

; good is an array of indices where x is valid and should be plotted
; this is used to skip over spaces in the cathode plots

if size(good,/type) eq 0 then good=lindgen(n_elements(x))

y=max(x)*0.1
xpos=findgen(n_elements(x)+1)*(n_elements(x)-1.15)/n_elements(x) + 0.55
;for i=0,n_elements(x)-1 do xyouts,xpos[i],y,strtrim(long(x[i]),2),orient=90,align=0,chars=1.5
y=max(x)*0.1 + lonarr(n_elements(x))
xyouts,xpos[good],y[good],strtrim(long(x[good]),2),orient=90,align=0,chars=1.5
xyouts,max(xpos)*1.01,y[0],'DN',orient=90,align=0,charsize=1

if size(current,/type) ne 0 then begin
   y=max(x)*0.95 + lonarr(n_elements(current))
   xyouts,xpos[good],y[good],strtrim(round(current[good]),2),orient=90,align=1,chars=1.25
   xyouts,max(xpos)*1.01,y[0],'fA',orient=90,align=1,charsize=1
endif

return
end


pro plot_spectrum_dn, xrs, euvsa, euvsb, sps, do_files=do_files

common limits, lim
common plot_spectrum_dn_cal, lasttime, pngfilecount
common plot_spectrum_dn_temp_rates_cal, xrsrate, euvsarate, euvsbrate, euvscrate, spsrate

if size(lim,/type) eq 0 then begin

     f = file_dirname(routine_filepath('plot_spectrum_dn')) + '/limits.sav'
     if file_test(f) then restore,f else begin
        print,'***'
        print,' ERROR: plot_spectrum.pro cannot find the limits.sav file!'
        print,'***'
     endelse
endif

if size(lasttime,/type) eq 0 then begin
   lasttime = -1.
   pngfilecount = 0L

   if size(xrsrate,/type) eq 0 then xrsrate=-1.
   if size(spsrate,/type) eq 0 then spsrate=-1.
   if size(euvsarate,/type) eq 0 then euvsarate=-1.
   if size(euvsbrate,/type) eq 0 then euvsbrate=-1.
   if size(euvscrate,/type) eq 0 then euvscrate=-1.

endif

;
; don't update the plot more often than every 3 seconds
;
;maxtime = (xrs.time.sod > sps.time.sod) > (euvsa.time.sod > euvsb.time.sod)
maxtime = (xrs.time.df > sps.time.df) > (euvsa.time.df > euvsb.time.df)

delta_update_seconds = 5.
if abs(lasttime - maxtime) lt delta_update_seconds/86400. then return ; update every time for testing

lasttime = maxtime


;create_plot_windows,'Spectrum'
window_set, 'Spectrum'

p_orig=!p

orig_charsize=!p.charsize
!p.charsize=2
!p.multi=[0,3,4]


; calculate currents from the gain
;xrsg   = apply_gain(xrs.diodes, xrs.asic1Temp, /xrs)   / (0.25*(xrs.asic.integtime+1.) - .011)
xrsg = xrs.current
;spsg   = apply_gain(sps.diodes, sps.temperature, /sps) / (0.25*(sps.asic.integtime+1.) - .011)
spsg = sps.current
;euvsag = apply_gain(euvsa.diodes, euvsa.aTemp, /euvsa) / (0.25*(euvsa.asic.integtime+1.) - .011)
euvsag = euvsa.current
;euvsbg = apply_gain(euvsb.diodes, euvsb.bTemp, /euvsb) / (0.25*(euvsb.asic.integtime+1.) - .011)
euvsbg = euvsb.current

;xallco = lonarr(n_elements(xrs.diodes))
;check_exis_limits, lim.xrs, xrs.diodes, xallco

; long channel
l_l=[1,2,3,4,10,0] ; quad, min, dark order (quad & dark same asic, min is other asic)

x = xrs.diodes[l_l]
co='eeee00'xUL+intarr(n_elements(x)) ;default color
offcolor='cccccc'x ; grey
; check limits
check_exis_limits,lim.xrs[l_l],x,co
; note that check_exis_limits only replaces if a limit is violated
if xrs.asic.pwrstatus eq 3 then begin
      ; ASIC1 powered on
   co[4] = offcolor             ; b1
endif else begin
   if xrs.asic.pwrstatus eq 12 then begin
         ; ASIC2 powered on
      co[0:3] = offcolor        ; b2
      co[5] = offcolor          ; d1
   endif
endelse
bar_plot,x,tit='XRS B - '+strtrim(xrs.time.yd,2)+'-'+xrs.time.hms, $
         background=!p.background, colors=co, $
         barnames=['B21','B22','B23','B24','B1','d1']
oplot_val_on_bar_plot, x, current=xrsg[l_l]

; half - short channel
s_l = [6,7,8,9,5,11] ; quad, min, dark order (quad & dark same asic, min is other asic)
x = xrs.diodes[s_l]
co='eeee00'xUL+intarr(n_elements(x)) ;default color
check_exis_limits,lim.xrs[s_l],x,co
if xrs.asic.pwrstatus eq 3 then begin
      ; ASIC1 powered on
   co[0:3] = offcolor           ; a2
   co[5] = offcolor             ; d2
endif else begin
   if xrs.asic.pwrstatus eq 12 then begin
         ; ASIC2 powered on
      co[4] = offcolor          ; a1
   endif
endelse
bar_plot,x,tit='XRS A - '+strtrim(xrs.time.yd,2)+'-'+xrs.time.hms, $
         background=!p.background, colors=co, $ ;'aaaa00'xUL+intarr(n_elements(x)), $
         barnames=['A21','A22','A23','A24','A1','d2']
oplot_val_on_bar_plot, x, current=xrsg[s_l]

;
; SPS diode order remains unknown 6/15/10 Version 11
; now it is known effective from Nov, 2011
;
x=sps.diodes
co='eeee'xUL+intarr(n_elements(sps.diodes)) ; default color
; check limits
check_exis_limits,lim.sps,x,co
bar_plot,x,tit='SPS - '+strtrim(sps.time.yd,2)+'-'+sps.time.hms, $
         colors=co, $
         barnames=['Q0','Q1','Q2','Q3','s1','s2']
oplot_val_on_bar_plot, x, current=spsg



; EUVS-A
; first part of 256
x256=[0,1,2,3,4,5]
x=euvsa.diodes[x256]
co = 'ffc0c0'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsa, x, co
if (euvsa.asic.pwrstatus and '3'xb) ne 3 then co[*] = offcolor
bar_plot,x,tit='EUVS-A 25.6 '+strtrim(euvsa.time.yd,2)+'-'+euvsa.time.hms, $
         colors=co, $ ;'dd7070'x+intarr(12), $
         barnames=strtrim(string(x256+1L),2)
         ;barnames=strtrim(sindgen(n_elements(x)),2)
oplot_val_on_bar_plot, x, current=euvsag[x256]

;if euvsa.asic.pwrstatus ne 15 then stop ;and euvsa.asic.pwrstatus ne 0 then stop

;second part of 256
x256=[23,22,21,20,19,18]
x=euvsa.diodes[x256]
co = 'ffc0c0'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsa, x, co
if (euvsa.asic.pwrstatus and '3'xb) ne 3 then co[*] = offcolor
bar_plot,x,tit='A4 25.6 '+strtrim(euvsa.time.yd,2)+'-'+euvsa.time.hms, $
         colors=co, $ ;'dd7070'x+intarr(12), $
         barnames=strtrim(string(x256+1L),2)
         ;barnames=strtrim(reverse(sindgen(n_elements(x)))+min(x256),2)
oplot_val_on_bar_plot, x, current=euvsag[x256]



x284=[6,7,8,9,10,11]
x=euvsa.diodes[x284]
co = 'ffc0c0'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsa, x, co
if (euvsa.asic.pwrstatus and '3'xb) ne 3 then co[*] = offcolor
bar_plot,x,tit='A2 28.4 '+strtrim(euvsa.time.yd,2)+'-'+euvsa.time.hms, $
         colors=co, $ ;'dd7070'x+intarr(n_elements(x)), $
         barnames=strtrim(string(x284+1L),2)
         ;barnames=strtrim(sindgen(n_elements(x))+min(x284),2)
oplot_val_on_bar_plot, x, current=euvsag[x284]

;x304=[12,13,14,15,16,17] ; this is backwards DLW 4/9/12 MOBI
x304=[17,16,15,14,13,12]
x=euvsa.diodes[x304]
co = 'ffc0c0'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsa, x, co
if (euvsa.asic.pwrstatus and '3'xb) ne 3 then co[*] = offcolor
vert = strtrim(round(float(euvsa.diodes[15])-float(euvsa.diodes[14])),2)
bar_plot,x,tit='A3 30.4 '+strtrim(euvsa.time.yd,2)+'-'+euvsa.time.hms, $
         colors=co, $ ;'dd7070'x+intarr(6), $
         xtit='30.4 -> 16-15= '+vert, $
         barnames=strtrim(string(x304+1L),2)
         ;barnames=strtrim(sindgen(n_elements(x))+min(x304),2)
oplot_val_on_bar_plot, x, current=euvsag[x304]


; EUVS-B
; 117.5
x117=[17,16,15,14,13,12] ; 12 is dark
x=euvsb.diodes[x117]
co = 'dd00'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsb, x, co
if euvsb.asic.pwrstatus lt 12 then co[*] = offcolor
bar_plot,x,tit='B3 117.5 '+strtrim(euvsb.time.yd,2)+'-'+euvsb.time.hms, $
         colors=co, $
         barnames=strtrim(string(x117+1L),2)
oplot_val_on_bar_plot, x, current=euvsbg[x117]

; 121.6
vert = strtrim(round(float(euvsb.diodes[9])-float(euvsb.diodes[8])),2)
x121=[6,7,8,9,10,11]
x=euvsb.diodes[x121]
co = 'dd00'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsb, x, co
if euvsb.asic.pwrstatus lt 12 then co[*] = offcolor
bar_plot,x,tit='B2 121.6 '+strtrim(euvsb.time.yd,2)+'-'+euvsb.time.hms, $
         colors=co, $
         xtit='121.6 -> 10-9= '+vert, $
         barnames=strtrim(string(x121+1L),2)
oplot_val_on_bar_plot, x, current=euvsbg[x121]

; 133
x133=[23,22,21,20,19,18] ; 23 is dark
x=euvsb.diodes[x133]
co = 'dd00'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsb, x, co
if euvsb.asic.pwrstatus lt 12 then co[*] = offcolor
bar_plot,x,tit='B4 133.5 '+strtrim(euvsb.time.yd,2)+'-'+euvsb.time.hms, $
         colors=co, $
         barnames=strtrim(string(x133+1L),2)
oplot_val_on_bar_plot, x, current=euvsbg[x133]

; 140
x140=[0,1,2,3,4,5]
x=euvsb.diodes[x140]
co = 'dd00'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsb, x, co
if euvsb.asic.pwrstatus lt 12 then co[*] = offcolor
bar_plot,x,tit='B1 140.5 '+strtrim(euvsb.time.yd,2)+'-'+euvsb.time.hms, $
         colors=co, $
         barnames=strtrim(string(x140+1L),2)
oplot_val_on_bar_plot, x, current=euvsbg[x140]


;
; print total DN
;
; get the current font in use
device,get_current_font=orig_font
;set a device font
;device,set_font='7x14'
;device,set_font='7x14bold'
device,set_font='6x13' ; for bare NUC
font=0 ; not true type, 0=device

plot,[0,1],[0,1],xs=4,ys=4,/nodata ; no axes, no data
x256=[ 1,2,3,4,5, 23, 22, 21, 20, 19,18]
x=total(float(euvsa.diodes[x256]))
tmpoffset=0.175
xyouts,font=font,-.1,.925+tmpoffset,'256(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2
x284=[ 6,7,8,9,10 ]
x=total(float(euvsa.diodes[x284]))
xyouts,font=font,-.1,.800+tmpoffset,'284(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2
x304=[ 12,13,14,15,16,17 ]
x=total(float(euvsa.diodes[x304]))
xyouts,font=font,-.1,.675+tmpoffset,'304(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2

xc_order = [12, 13,14,15,16,17, 11,10,9,8,7,6, 18,19,20,21,22, 5,4,3,2,1,0, 23]
x117=[13,14,15,16,17]
x121=[11,10,9,8,7,6]
x133=[18,19,20,21,22]
x140=[5,4,3,2,1,0]
x=total(float(euvsb.diodes[x117]))
xyouts,font=font,-.1,.500+tmpoffset,'117(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2
x=total(float(euvsb.diodes[x121]))
xyouts,font=font,-.1,.375+tmpoffset,'121(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2
x=total(float(euvsb.diodes[x133]))
xyouts,font=font,-.1,.250+tmpoffset,'133(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2
x=total(float(euvsb.diodes[x140]))
xyouts,font=font,-.1,.125+tmpoffset,'140(DN)='+strtrim(string(x,form='(e12.2)'),2);,chars=1.2

device,set_font='7x14bold'
xyouts,font=font,-.3, .000+tmpoffset,'Temp Rates degC/min'

; define colors
FFcolor='cc0000'xUL
grayco='aaaaaa'xUL
yellowco='77dddd'xUL
redco   = 'fe'xUL
greenco = 'aa00'xUL


xrsco=greenco
spsco=greenco
euvsaco=greenco
euvsbco=greenco
euvscco=greenco

if abs(xrsrate) gt 0.01 then xrsco=redco
if abs(spsrate) gt 0.01 then spsco=redco
if abs(euvsarate) gt 0.01 then euvsaco=redco
if abs(euvsbrate) gt 0.01 then euvsbco=redco
if abs(euvscrate) gt 0.01 then euvscco=redco

threshold = 64./86400.d0 ; 64 seconds is threshold
if abs(xrs.time.df-maxtime) gt threshold then xrsstale=1 else xrsstale=0
if abs(sps.time.df-maxtime) gt threshold then spsstale=1 else spsstale=0
if abs(euvsa.time.df-maxtime) gt threshold then euvsastale=1 else euvsastale=0
if abs(euvsb.time.df-maxtime) gt threshold then euvsbstale=1 else euvsbstale=0

if xrsstale eq 1 then xrsco=grayco
if spsstale eq 1 then spsco=grayco
if euvsastale eq 1 then euvsaco=grayco
if euvsbstale eq 1 then euvsbco=grayco

xyouts,font=font,-.25,-.125+tmpoffset,'XRS:   '
xyouts,font=font,0.05,-.125+tmpoffset,strtrim(string(xrsrate,form='(f7.3)'),2),co=xrsco

xyouts,font=font,-.25,-.250+tmpoffset,'SPS:   '
xyouts,font=font,0.05,-.250+tmpoffset,strtrim(string(spsrate,form='(f7.3)'),2),co=spsco

xyouts,font=font,0.45,-.125+tmpoffset,'EUVSA: '
xyouts,font=font,0.75,-.125+tmpoffset,strtrim(string(euvsarate,form='(f7.3)'),2),co=euvsaco

xyouts,font=font,0.45,-.250+tmpoffset,'EUVSB: '
xyouts,font=font,0.75,-.250+tmpoffset,strtrim(string(euvsbrate,form='(f7.3)'),2),co=euvsbco

xyouts,font=font,0.45,-.375+tmpoffset,'EUVSC: '
xyouts,font=font,0.75,-.375+tmpoffset,strtrim(string(euvscrate,form='(f7.3)'),2),co=euvscco

; reset default font
device,set_font=orig_font
!p.font=p_orig.font



;
; Make EUVS-A_Cathodes
;
window_set, 'EUVS-A_Cathodes'
!p.charsize=1.25
;!p.multi=0
!p.multi=[0,1,2] ; two plots
xc_order=[0, 1,2,3,4,5, 23,22,21,20,19,18, 6,7,8,9,10, 17,16,15,14,13,12, 11 ]
clabel='c'+strtrim((string(lindgen(24)+1L)),2)
x = euvsa.diodes[xc_order]
xa= [x[0], 0, x[1:11], 0, x[12:16], 0, x[17:22], 0, x[23]]
xg=euvsag[xc_order]
xeuvsag=[xg[0], 0, xg[1:11], 0, xg[12:16], 0, xg[17:22], 0, xg[23]]
co = 'ffc0c0'x+intarr(n_elements(x)) ; default color
;co = 'dd7070'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsa, x, co
if (euvsa.asic.pwrstatus and '3'xb) ne 3 then co[*] = offcolor
xco = [co[0], 0, co[1:11], 0, co[12:16], 0, co[17:22], 0, co[23]]

barnames = [clabel[0],' ',clabel[1:11],' ',clabel[12:16],' ',clabel[17:22],' ',clabel[23]]
barnames[0] += '!Cd'
barnames[7] += '!C25.6nm'
barnames[16] += '!C28.4nm'
barnames[23] += '!C30.4nm'
barnames[27] += '!Cd'

bar_plot,xa,tit='EUVS-A '+strtrim(euvsa.time.yd,2)+'-'+euvsa.time.hms, $
         colors=xco, background='ffffff'x, $
         barnames=barnames
good=where(xco gt 0)
oplot_val_on_bar_plot, xa, current=xeuvsag, good=good

; second plot
idx304=lindgen(6)+20L
         ;tit='EUVS-A '+strtrim(euvsa.time.yd,2)+'-'+euvsa.time.hms, $
barnames[22] += '!C30.4nm BOTTOM'
barnames[23] += ' TOP'
bar_plot,xa[idx304], tit='c18-c23 Total Current(fA)='+strtrim(total(xeuvsag[idx304]),2),$
         colors=xco[idx304], background='ffffff'x, $
         barnames=barnames[idx304]
good=where(xco[idx304] gt 0)
oplot_val_on_bar_plot, xa[idx304], current=xeuvsag[idx304], good=good

stride=20 ; png file write cadence is stride*delta_update_seconds
;stride=5 ; png file write cadence is stride*delta_update_seconds
if keyword_set(do_files) eq 1 and pngfilecount mod stride eq 0 then begin
   write_pngfile,'/dev/shm/tmp_euvsa_cathodes.png'
   file_move,'/dev/shm/tmp_euvsa_cathodes.png','/dev/shm/euvsa_cathodes.png',/overwrite
   print,'euvsa_cathodes.png updated'
endif
;pngfilecount = (pngfilecount+1) mod stride
; don't update pngfilecount until euvsb has been updated

;
; Make EUVS-B_Cathodes
;
window_set, 'EUVS-B_Cathodes'
!p.charsize=1.25
!p.multi=[0,1,2]
;           d,  117            121   split        133           140        d
xc_order = [12,13,14,15,16,17, 11,10,9,8,7,6, 18,19,20,21,22, 5,4,3,2,1,0, 23]
clabel='c'+strtrim(string(reverse(lindgen(24))+1L),2)
x = euvsb.diodes[xc_order]
xb= [x[0], 0, x[1:5], 0, x[6:11], 0, x[12:16], 0, x[17:22], 0, x[23]]
xg=euvsbg[xc_order]
xeuvsbg=[xg[0], 0, xg[1:5], 0, xg[6:11], 0, xg[12:16], 0, xg[17:22], 0, xg[23]]
;co = 'dd7070'x+intarr(n_elements(x)) ; default color
co = 'dd00'x+intarr(n_elements(x)) ; default color
check_exis_limits, lim.euvsb, x, co
if euvsb.asic.pwrstatus lt 12 then co[*] = offcolor
xco = [co[0], 0, co[1:5], 0, co[6:11], 0, co[12:16], 0, co[17:22], 0, co[23]]

barnames = [clabel[0],' ',clabel[1:5],' ',clabel[6:11],' ',clabel[12:16],' ',clabel[17:22],' ',clabel[23]]
barnames[0] += '!Cd'
barnames[4] += '!C117.5nm'
barnames[10] += '!C121.6nm'
barnames[17] += '!C133.5nm'
barnames[24] += '!C140.5nm'
barnames[28] += '!Cd'

bar_plot,xb,tit='EUVS-B '+strtrim(euvsb.time.yd,2)+'-'+euvsb.time.hms, $
         colors=xco, background='ffffff'x, $
         barnames=barnames
good=where(xco gt 0)
oplot_val_on_bar_plot, xb, current=xeuvsbg,good=good


; second plot
idx121=lindgen(6)+8L
barnames[11] += '!C121.6nm TOP'
barnames[10] += ' BOTTOM'
bar_plot,xb[idx121], tit='c13-c18 Total Current(fA)='+strtrim(total(xeuvsbg[idx121]),2),$
         colors=xco[idx121], background='ffffff'x, $
         barnames=barnames[idx121]
good=where(xco[idx121] gt 0)
oplot_val_on_bar_plot, xb[idx121], current=xeuvsbg[idx121], good=good


;stride=20 ; png file write cadence is stride*delta_update_seconds
if keyword_set(do_files) eq 1 and pngfilecount mod stride eq 0 then begin
   write_pngfile,'/dev/shm/tmp_euvsb_cathodes.png'
   file_move,'/dev/shm/tmp_euvsb_cathodes.png','/dev/shm/euvsb_cathodes.png',/overwrite
   print,'euvsb_cathodes.png updated'
endif
pngfilecount = (pngfilecount+1) mod stride

;if euvsa.asic.pwrstatus ne 15 then stop

;
; return to normal parameters
;
!p.charsize=orig_charsize

!p.multi=0
return
end
