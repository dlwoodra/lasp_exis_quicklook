; docformat = 'rst'

;+
; :Author:
;   Don Woodraska
;
; :Copyright:
;    Copyright 2012 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and 
;    Space Physics. 
;
; :Version:
;    $Id: plot_sps.pro 81633 2019-05-21 16:16:48Z dlwoodra $
;
;-

;+
; This makes the SPS target plot. There are two now.
;
; :Params:
;    sps_rec : in, required, type=structure
;      decomposed structure passed in from exis_quicklook
;    temperature_dn : in, optional, type=long
;      this is a legacy argument passed to plot_sps_emi so the proper gain 
;      can be applied, however, the gain is already calculated and applied 
;      in the sps_rec structure, so it is no longer required
;
; :Uses:
;    window_set, plot_sps_emi, convert_fm1_sps_xy_to_alpha_beta, write_pngfile
;
;-
pro plot_sps, sps_rec, temperature_dn, do_files=do_files

;
; note that sps argument is expected to have dark/offset removed
;
  common plot_sps_cal, recent_relx, recent_rely, lasttime, pngfilecount

  if size(lasttime,/type) eq 0 then begin
     lasttime=-1.
     pngfilecount=0L
  endif

  sps = sps_rec.diodes[0:3]

  low_signal  = 0
  high_signal = 0
  co=0L ; default color is black
  if total(sps) lt 1000 then begin
     co='aaaaaa'x               ; grey for low signal
     low_signal=1
  endif
  junk=where(sps ge 238900,n_high)
  if n_high gt 0 then begin
     co='fe'x
     high_signal=1
  endif

  spsg = sps_rec.current[0:3] ;apply_gain(sps_rec.diodes,temperature_dn,/sps)

  hms = sps_rec.time.hms

  ;sum = float(total(sps))
  ;itot = 1. / (sum > 1.)
  ;relx = ((float(sps[0])-sps[1])+(float(sps[2])-sps[3])) * itot
  ;rely = ((float(sps[0])-sps[2])+(float(sps[1])-sps[3])) * itot

  ; match cal report definition for X and Y usign gain-corrected currents
  ;rely = ((float(sps[0])-sps[1])+(float(sps[2])-sps[3])) * itot
  ;relx = ((float(sps[0])-sps[2])+(float(sps[1])-sps[3])) * itot
  sum = float(total(spsg))
  itot = 1. / (sum > 1.)
  ; CHANGED Mar 28, 2012 BASED on SCOTT's REQUEST
  rely = ((float(spsg[1])-spsg[0])+(float(spsg[2])-spsg[3])) * itot
  relx = ((float(spsg[2])-spsg[0])+(float(spsg[3])-spsg[1])) * itot

;  case strlowcase(getenv('exis_type')) of
;     'fm3': begin
;        ;relx -= 0.03057
;        ;rely -= 0.08792
;     end
;     else: 
;  endcase


  if size(recent_relx,/type) eq 0 then begin
     recent_relx=[1,1]*relx
     recent_rely=[1,1]*rely
  endif

  scale=1.0
  mx=max(abs(recent_relx))
  my=max(abs(recent_rely))
  if mx lt .5 and my lt 0.5 then scale = ((mx>my>.1)<1.)


  ; append the current data to the old arrays
  recent_relx = [temporary(recent_relx),relx]
  recent_rely = [temporary(recent_rely),rely]

  n_x = n_elements(recent_relx)
  nkeep=20
  if n_x gt nkeep then begin
     recent_relx = recent_relx[(n_x-nkeep):(n_x-1)]
     recent_rely = recent_rely[(n_x-nkeep):(n_x-1)]
  endif


  ; plot Darren's stuff
  plot_sps_emi, sps_rec, temperature_dn


  ;
  ; if at least 3 seconds has elapsed, then update the plot
  ;
  sps_delta_update_seconds = 3.
  if abs(lasttime - sps_rec.time.sod) lt sps_delta_update_seconds then return
  
  lasttime = sps_rec.time.sod

  ; get the window id
  window_set, 'SPS_Target'

  if total(sps_rec.diodes eq sps_rec.offset) eq n_elements(sps_rec.diodes) then begin
     print,'SPS test pattern found '+hms
  endif

  p_orig = !p
  d_orig = !d

  ; get the current font in use
  device,get_current_font=orig_font

  ; use a device font
  device,set_font='7x13bold'
;  device,set_font='6x13' ; use for bare NUC
  font=0 ; 0=device, -1=hershey, 1=truetype

  ;
  ; XRS coordinate system
  ;

  !p.multi=[0,2,1]
  ; plot the one point
  plot,[1,1],[1,1],xr=[-1.1,1.1]*scale,yr=[-1.1,1.1]*scale,xs=1,ys=1, $
       tit='SPS_Targ.-'+hms,xtit='Rel-x = '+strtrim(relx,2),ytit='Rel-y = '+strtrim(rely,2), $
       xmargin=[8,3], ymargin=[4,2],/isotropic
  ;stop
  ;cross
  oplot,!x.crange,[0,0],lines=1
  oplot,[0,0],!y.crange,lines=1

  ;rings
  r = fltarr(90)
  theta = findgen(90) * (2. * !pi / ( 90.))
  oplot,r+1.0,theta,/polar,lines=1,co='aa'x
  oplot,r+0.5,theta,/polar,ps=3,co='aa0000'x
  oplot,r+0.1,theta,/polar,ps=3,co='aa00'x


  sum_nano = round(sum/1.d6)
  ;xyouts,font=font, -1.*scale,-0.8*scale,'Sum='+strtrim(long(sum),2)+' fA'
  xyouts,font=font, -1.*scale,-0.8*scale,'Sum='+strtrim(long(sum_nano),2)+' nA'

  convert_fm1_sps_xy_to_alpha_beta, relx, rely, alpha, beta,/arcsec
  ; alpha and beta MAY be negative/opposite! Mar 28, 2012
;  case strlowcase(getenv('exis_type')) of
;     'fm3': begin
;        ;alpha += 247
;        ;beta += 1105
;        relx -= 0.03057
;        rely += 0.08792
;     end
;     else: 
;  endcase

  xyouts,font=font,-1.*scale,0,'alpha='+strtrim(long(alpha),2)+' asec'+'!C!Cbeta='+strtrim(long(beta),2)+' asec'

  xyouts,font=font, -1.*scale,-1.*scale,'S1='+strtrim(long(sps[0]),2)+' DN'
  xyouts,font=font, -1.*scale, 1.*scale,'S2='+strtrim(long(sps[1]),2)+' DN'
  xyouts,font=font,  1.*scale, 1.*scale,'S3='+strtrim(long(sps[2]),2)+' DN',align=1.
  xyouts,font=font,  1.*scale,-1.*scale,'S4='+strtrim(long(sps[3]),2)+' DN',align=1.


  ; overplot the old data
  oplot,recent_relx,recent_rely,ps=-4,co='99cc00'x,symsize=1
  oplot,[1,1]*relx,[1,1]*rely,ps=2,co='9900'x,symsize=2


  ;
  ; S/C coordinate system(-ish) Per Jira GOESRDS-274
  ;
  ; next upside-down plot (S/C alignment)
  plot,[1,1],[1,1],xr=[-1.1,1.1]*scale,yr=[-1.1,1.1]*scale,xs=1,ys=1, $
       tit='SPS_ActualSolarView-'+hms,xtit='Rel-x = '+strtrim(relx,2),ytit='Rel-y = '+strtrim(-1.*rely,2), $
       xmargin=[8,3], ymargin=[4,2],/isotropic,co='aa0000'x
  ;stop
  ;cross
  oplot,!x.crange,[0,0],lines=1
  oplot,[0,0],!y.crange,lines=1

  ;rings
  r = fltarr(90)
  theta = findgen(90) * (2. * !pi / ( 90.))
  oplot,r+1.0,theta,/polar,lines=1,co='aa'x
  oplot,r+0.5,theta,/polar,ps=3,co='aa0000'x
  oplot,r+0.1,theta,/polar,ps=3,co='aa00'x


  xyouts,font=font, -1.*scale,-0.8*scale,'Sum='+strtrim(long(sum),2)+' fA',co=co

  xyouts,font=font,-1.*scale,0,'alpha='+strtrim(long(-1.*alpha),2)+' asec'+'!C!Cbeta='+strtrim(long(beta),2)+' asec',co=co

  ; switched order to match upside down 3<->4, 1<->2
  xyouts,font=font, -1.*scale, 1.*scale,'S1='+strtrim(long(sps[0]),2)+' DN',co=co
  xyouts,font=font, -1.*scale,-1.*scale,'S2='+strtrim(long(sps[1]),2)+' DN',co=co
  xyouts,font=font,  1.*scale,-1.*scale,'S3='+strtrim(long(sps[2]),2)+' DN',align=1.,co=co
  xyouts,font=font,  1.*scale, 1.*scale,'S4='+strtrim(long(sps[3]),2)+' DN',align=1.,co=co

  ; overplot the old data with N-S inverted
  oplot,recent_relx,-1.*recent_rely,ps=-4,co='99cc00'x,symsize=1
  oplot,[1,1]*relx,-1.*[1,1]*rely,ps=2,co='9900'x,symsize=2

  ; overplot gravity indicator with a down arrow
  arrow=string(byte('65'o))
  ;xyouts,font=-1, 1*scale, 0.5*scale, 'g!C!C!9'+arrow+'!3',align=1,chars=2 
  xyouts,font=font, 1*scale, 0.5*scale, 'g',align=1
  xyouts,font=-1, 1*scale, 0.5*scale, '!9'+arrow+'!3',align=1,chars=4 
  ; use showfont,9,'-' to see the character map
  ; !3 returns to default hershey font (required)

  if low_signal eq 1 then xyouts,0, 1.*scale,'No Signal',co='9900'x,align=0.5
  if high_signal eq 1 then xyouts,0, 1.*scale,'High Signal',co='fe'x,align=0.5

  ; restore original font
  device,set_font=orig_font
  !p.font = p_orig.font

  stride=20 ; png file update cadence is stride*sps_delta_update_seconds
  ;stride=1 ; png file update cadence is stride*sps_delta_update_seconds
;  if keyword_set(do_files) eq 1 and pngfilecount mod stride eq 0 then begin
;     write_pngfile,'/dev/shm/tmp_sps.png'
;     file_move,'/dev/shm/tmp_sps.png','/dev/shm/sps.png',/overwrite
;     print,'updated sps.png'
;  endif
  pngfilecount = (pngfilecount+1) mod stride

return
end
