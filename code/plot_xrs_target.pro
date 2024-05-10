pro plot_xrs_target, xrs_rec, temperature_dn, do_darkxrs=do_darkxrs, do_files=do_files

  common plot_xrs_target_cal, recent_relx_s, recent_rely_s, $
     recent_relx_l, recent_rely_l, lasttime, imgcount

  if size(lasttime,/type) eq 0 then begin
     lasttime=-1.
     imgcount=0L
  endif

  ; apply to just this record
  ; signal is (dn*gain - dark)/dt (fAmps)
  xrs_diodes_gain = xrs_rec.signal ;xrs_rec.current ;apply_gain(xrs_rec.diodes, temperature_dn, /xrs)

  ;xrs_s = xrs_rec.diodes[5:8] ; DN
  ;xrs_l = xrs_rec.diodes[1:4] ; DN
                                ;xrs_s = xrs_diodes_gain[5:8] ; gain
                                ;corrected current (fA) ; DLW 4/9/12
                                ;stop using dark as if it were a quad
  xrs_s = xrs_diodes_gain[6:9] ; gain corrected current (fA)
  xrs_l = xrs_diodes_gain[1:4] ; gain corrected current (fA)
  hms = xrs_rec.time.hms

  ; FORMULA CHANGED BASED on SCOTT's REQUEST (MOBI) - Mar 28, 2012
  sum_s = float(total(xrs_s))
  itot_s = 1. / (sum_s > 1.)
  relx_s = ((float(xrs_s[0])-xrs_s[2])+(float(xrs_s[1])-xrs_s[3])) * itot_s
  rely_s = ((float(xrs_s[0])-xrs_s[1])+(float(xrs_s[3])-xrs_s[2])) * itot_s

  sum_l = float(total(xrs_l))
  itot_l = 1. / (sum_l > 1.)
  relx_l = ((float(xrs_l[0])-xrs_l[2])+(float(xrs_l[1])-xrs_l[3])) * itot_l
  rely_l = ((float(xrs_l[0])-xrs_l[1])+(float(xrs_l[3])-xrs_l[2])) * itot_l

  if size(recent_relx_s,/type) eq 0 then begin
     recent_relx_s=[1,1]*relx_s
     recent_rely_s=[1,1]*rely_s

     recent_relx_l=[1,1]*relx_l
     recent_rely_l=[1,1]*rely_l
  endif

  scale=1.0
  mx=max(abs(recent_relx_s))>max(abs(recent_relx_l))
  my=max(abs(recent_rely_s))>max(abs(recent_rely_l))
  ;if mx lt .5 and my lt 0.5 then scale = ((mx>my>.1)<1.)

  maxval = mx>my
  if maxval lt .5 then begin
     scale=0.5
     if maxval lt .25 then begin
        scale=0.25
        if maxval lt .1 then begin
           scale=0.1
           if maxval lt .01 then begin
              scale=0.01
           endif
        endif
     endif
  endif

  ; append the current data to the old arrays
  recent_relx_s = [temporary(recent_relx_s),relx_s]
  recent_rely_s = [temporary(recent_rely_s),rely_s]

  recent_relx_l = [temporary(recent_relx_l),relx_l]
  recent_rely_l = [temporary(recent_rely_l),rely_l]

  n_x = n_elements(recent_relx_s)
  nkeep=5
  if n_x gt nkeep then begin
     recent_relx_s = recent_relx_s[(n_x-nkeep):(n_x-1)]
     recent_rely_s = recent_rely_s[(n_x-nkeep):(n_x-1)]

     recent_relx_l = recent_relx_l[(n_x-nkeep):(n_x-1)]
     recent_rely_l = recent_rely_l[(n_x-nkeep):(n_x-1)]
  endif

  ;
  ; if at least 3 seconds has elapsed, then update the plot
  ;
  xrs_delta_update_seconds = 3.
  if abs(lasttime - xrs_rec.time.sod) lt xrs_delta_update_seconds then return

  lasttime = xrs_rec.time.sod

  ; set the window for plotting
  window_set, 'XRS_Target'

  ; get the current font in use
  device,get_current_font=orig_font

  ; use a truetype font
  device,set_font='Helvetica',/tt_font
  not_tt=0
  tt=1


  ; plot the one point
  f='(f20.5)'
; Modified by Brian Templeman for Andrew Jones during SURF calibration 07/05/2012
;  plot,[1,1],[1,1],xr=[-0.25,0.25]*scale,yr=[-0.25,0.25]*scale,xs=1,ys=1, 

  ; reverted back to full scale to support alignments in MOBI Don Woodraska, 09/28/12
  if keyword_set(do_darkxrs) then tit='' else $
     tit='NO DARK! XRS_Targ.-'+hms
  tit = tit+'XRS_Targ.-'+hms
  plot,[1,1],[1,1],xr=[-1.1,1.1]*scale,yr=[-1.1,1.1]*scale,xs=1,ys=1, $
       tit=tit, /isotropic, $
       xtit='S='+strtrim(string(relx_s,form=f),2) + $
       ' L='+strtrim(string(relx_l,form=f),2), $
       ytit='S='+strtrim(string(rely_s,form=f),2) + $
       ' L='+strtrim(string(rely_l,form=f),2), $
       xmargin=[7,2], ymargin=[4,2],font=tt,chars=2
       ;xmargin=[11,4], ymargin=[5,3],font=not_tt

  ; make y-axis label
  ;xyouts, -1.1*scale,-0.8*scale,orient=90,font=not_tt, $
  ;        'S='+strtrim(string(rely_s,form=f),2) + $
  ;        ' L='+strtrim(string(rely_l,form=f),2)


  sco='660066'x
  lco='dd7070'x

  ;cross
  oplot,!x.crange,[0,0],lines=1
  oplot,[0,0],!y.crange,lines=1

  ;rings
  r = fltarr(90)
  theta = findgen(90) * (2. * !pi / ( 90.))
  oplot,r+1.0,theta,/polar,lines=1,co='66'x
  oplot,r+0.5,theta,/polar,ps=3,co='660000'x
  oplot,r+0.1,theta,/polar,ps=3,co='6600'x

  ; overplot the old data
  oplot,recent_relx_s,recent_rely_s,co=sco*1.1,symsize=1
  oplot,[1,1]*relx_s,[1,1]*rely_s,ps=7,co=sco,symsize=2.5 ; x
  if sum_s lt 10000. then $
     oplot,[1,1]*relx_s,[1,1]*rely_s,ps=6,co=sco,symsize=2.5,co='fe'x ; box


  oplot,recent_relx_l,recent_rely_l,co=lco*1.1,symsize=1
  oplot,[1,1]*relx_l,[1,1]*rely_l,ps=1,co=lco,symsize=2.5
  if sum_l lt 20000. then $
     oplot,[1,1]*relx_l,[1,1]*rely_l,ps=4,co=lco,symsize=2.5,co='fe'x ; diamond

  p_orig = !p
  d_orig = !d

  ;!p.charsize=2
  ;!p.charthick=2
  ;device,set_font='Courier',/TT_FONT,set_character_size=[12,12]

  device,set_font='10x20'
;  device,set_font='6x13'

  xyouts, -1.*scale,-0.8*scale,'A_Sum='+strtrim(long(sum_s),2),co=sco,font=not_tt
  xyouts, -1.*scale,-0.7*scale,'B_Sum='+strtrim(long(sum_l),2),co=lco,font=not_tt

  xyouts,  1.*scale, 1.*scale,'A1='+strtrim(long(xrs_s[0]),2),align=1,co=sco,font=not_tt
  xyouts,  1.*scale,-1.*scale,'A2='+strtrim(long(xrs_s[1]),2),align=1,co=sco,font=not_tt
  xyouts, -1.*scale,-1.*scale,'A3='+strtrim(long(xrs_s[2]),2),co=sco,font=not_tt
  xyouts, -1.*scale, 1.*scale,'A4='+strtrim(long(xrs_s[3]),2),co=sco,font=not_tt

  xyouts,  1.*scale, 0.9*scale,'B1='+strtrim(long(xrs_l[0]),2),align=1.,co=lco,font=not_tt
  xyouts,  1.*scale,-0.9*scale,'B2='+strtrim(long(xrs_l[1]),2),align=1.,co=lco,font=not_tt
  xyouts, -1.*scale,-0.9*scale,'B3='+strtrim(long(xrs_l[2]),2),co=lco,font=not_tt
  xyouts, -1.*scale, 0.9*scale,'B4='+strtrim(long(xrs_l[3]),2),co=lco,font=not_tt

 ;!p.charsize= p_orig.charsize
 ;!p.charthick=p_orig.charthick
 ;device,set_character_size=[d_orig.x_ch_size,d_orig.y_ch_size]
  device,set_font=orig_font
  !p.font = p_orig.font

  ; don't write every image
  stride=5 ; png file write cadence is stride*xrs_delta_update_seconds
  ;stride=20 ; png file write cadence is stride*xrs_delta_update_seconds
  ;stride=1; png file write cadence is stride*xrs_delta_update_seconds
                                ; a value of 1 indicates write every
                                ; xrs_delta_update_seconds (every time)
;  if keyword_set(do_files) eq 1 and imgcount mod stride eq 0 then begin
;     t0=systime(1)
;     write_pngfile,'/dev/shm/tmp_xrs_target.png'
;     file_move,'/dev/shm/tmp_xrs_target.png','/dev/shm/xrs_target.png',/overwrite
;     print,'file manip seconds = ',systime(1)-t0
;  endif
  imgcount = (imgcount+1) mod stride

;stop
return
end
