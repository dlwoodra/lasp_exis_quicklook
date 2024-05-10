; docformat = 'rst'

;+
; :Author:
;   Don Woodraska
;
; :Copyright:
;    Copyright 2013 The Regents of the University of Colorado.
;    All rights reserved. This software was developed at the
;    University of Colorado's Laboratory for Atmospheric and 
;    Space Physics. 
;
; :Version:
;    $Id: plot_euvsc.pro 79016 2017-09-14 21:17:53Z dlwoodra $
;
;-

;+
; Internal function used to store the latest laser data.
;
; :Params:
;    euvsc : in, required, type=structure
;      The scalar structure is defined in gpds_defines.pro
;
;-
pro write_to_euvsc_binstats_file, euvsc, av, st
  
  ; if there is no directory, bail out
  if file_test(getenv('exis_data_quicklook'),/dir) ne 1 then return

  default_file_name = getenv('exis_data_quicklook')+'/latest_euvsc_stats.txt'

  openw, euvsc_lun, default_file_name, /get_lun

  ptime=euvsc[0].time

  printf, euvsc_lun, ';Creator: plot_euvsc_sigma via write_to_euvsc_binstats_file'
  printf, euvsc_lun, ';YYYYDOY HH:MM:SS.sss SOD Avg64 Stdev64'
  printf, euvsc_lun, strtrim(ptime.yd,2)+' '+$
          ptime.hms+' '+$
          strtrim(ptime.sod,2)+' '+$
          strjoin(strtrim(round(av),2),' ')+' '+$
          strjoin(strtrim(round(st),2),' ')

  free_lun,euvsc_lun

return
end

;+
; This routine makes two plots, to support the EXIS science data quicklook.
; It relies on window information defined in the exis_quicklook.pro file.
;
; :Params:
;    euvsc_rec : in, required, type=structure
;      The scalar structure is defined in gpds_defines.pro
;
; :Keywords:
;    laser : in, optional, type=boolean
;      use keyword to replace the last (sigma) plot with a zoom in of the laser line
;    do_files: in, optional, type=boolean
;      writes pngfile if enabled
;
; :Uses:
;    window_set, plot_euvsc_sigma, write_pngfile, plot_euvsc_count_image
;
;-
pro plot_euvsc, euvsc_rec, laser=laser, do_files=do_files

  common plot_euvsc, euvsc_arr, co, n, nx, ny, lasttime,pngfilecount
  common limits, lim

  if size(co,/type) eq 0 then begin
     co=['a0f0a0'xUL, '80cc80'xUL, '50aa50'xUL, '105510'xUL, 'a0a0a0'xUL]
     euvsc_arr=euvsc_rec
     ;window_id = get_window_id('EUVS-C')

     lasttime=-1.d
     pngfilecount = 0L

     n  = 512                      ;total pixels
     nx = 8                       ;number of bins
     ny = long(n/nx)              ; number of pixels in one bin

     ;f = file_which(getenv('PATH'),'limits.sav',/include_current_dir)
     f = file_dirname(routine_filepath('plot_euvsc')) + '/limits.sav'
     if file_test(f) ne '' then restore,f else begin
        print,'***'
        print,' ERROR: plot_euvsc.pro cannot find the limits.sav file!'
        print,'***'
     endelse

  endif


  if n_elements(euvsc_arr) gt n_elements(co)-1 then begin
     euvsc_arr = shift(euvsc_arr,1)
     euvsc_arr[0] = euvsc_rec
        ;euvsc_arr = [euvsc_rec,euvsc_arr[0:n_elements(euvsc_arr)-2]] 
  endif else $
     euvsc_arr=[euvsc_rec,euvsc_arr]
;  endelse


  tit = strtrim(euvsc_rec.time.yd,2)+'-'+euvsc_rec.time.hms
  channel = ishft(euvsc_rec.reg.pwrstatus,-2) and 11b
  intTime = euvsc_rec.reg.integtime
  xtit= $
     'Channel:' +strtrim(string(channel, form='(z1)'),2) + $
     ' ModeReg: '+strtrim(string(euvsc_rec.reg.modeReg,form='(i3)'),2) + $
     ' IntTime:'+string((intTime+1.)*.25,form='(f5.2)') + $
     ' DeadTime:'+strtrim(fix(euvsc_rec.reg.deadtime),2) + $
     ' FlushCnt:'+strtrim(fix(euvsc_rec.reg.modeReg and '3'xb),2)
  ;if euvsc_rec.test gt 0 then $
  ;   xtit=xtit+' Test:'   +strtrim(string(euvsc_rec.test,form='(z2.2)'),2)
  if (euvsc_rec.ff.power and 1b) eq 1 then $
     xtit=xtit+' FF_on:'+string(ishft(euvsc_rec.ff.power,-1) and '7'xb,form='(z1)')+$
     ' FF_Level:'+strtrim(string(euvsc_rec.ff.level,form='(i6)'),2)

  ;avg = total(rebin(transpose(euvsc_rec.data),ny,nx),1)/ny
  avg = total(rebin(transpose(euvsc_rec.decoded_data),ny,nx),1)/ny
  tx = findgen(nx)*ny+(ny*0.5)
  
  ;calculate stddev
  st=fltarr(nx)
  if n_elements(euvsc_arr) gt 2 then begin
     av = fltarr(nx,n_elements(euvsc_arr))
     for j=0,n_elements(euvsc_arr)-1 do $
        ;av[*,j] = total(rebin(transpose(euvsc_arr[j].data),ny,nx),1)/ny
        av[*,j] = total(rebin(transpose(euvsc_arr[j].decoded_data),ny,nx),1)/ny
     for k=0,nx-1 do st[k] = stddev(av[k,*])
  endif


  ;
  ; if less than 5 seconds has elapsed, skip the plot and return
  ;
  euvsc_delta_update_seconds = 5.
  if abs(euvsc_rec.time.sod - lasttime) lt euvsc_delta_update_seconds then return

  ; more than 5 seconds has elapsed, do the plotting, update the timer
  lasttime = euvsc_rec.time.sod

  write_to_euvsc_binstats_file, euvsc_rec, avg, st

  ; set the window id
  window_set, 'EUVS-C'

  if total(euvsc_rec.data eq lindgen(512)) eq n_elements(euvsc_rec.data) then begin
     print,'EUVSC Test pattern found '+euvsc_rec.time.hms
  endif

  pmulti_orig=!p.multi
  !p.multi=[0,1,2]

  if channel ne 1b then begin
     plot,euvsc_rec.decoded_data,xs=1,tit='Channel C1 off',/nodata,xr=[0,n]
     xyouts,/norm,align=0.5,.5,.75,'No C1 data'
  endif

  ; setup the axes ranges for the plot and the titles
  ;plot,euvsc_rec.data,ys=1,ps=-4,xs=1, $ ; autoscale
  plot,euvsc_rec.decoded_data,ys=1,ps=-4,xs=1, $ ; autoscale
       tit=tit,xtit=xtit,/nodata, $
       xticks=nx,xr=[0,n]

  ; plot average rectangles
  for i=0L,nx-1 do draw_fill_rect, tx[i], avg[i], ny*.9, co=co[0]

  ; now overplot the older data rectangles
  for j=1,n_elements(euvsc_arr)-1 do begin
     ;a=total(rebin(transpose(euvsc_arr[j].data),ny,nx),1)/ny
     a=total(rebin(transpose(euvsc_arr[j].decoded_data),ny,nx),1)/ny
     for i=0L,nx-1 do draw_fill_rect, tx[i]+(ny*j*.1), a[i], ny*.1, co=co[j]
  endfor

  ; overplot the latest spectrum
  ;oplot,euvsc_rec.data,ps=10,co='f00000'xUL
  oplot,euvsc_rec.decoded_data,ps=10,co='f00000'xUL

  ; print values on plot
  dy = !y.crange[1]-!y.crange[0]
  y  = !y.crange[0] + dy*(.05) + lonarr(nx)
  ;text = strtrim(ulong(avg),2)+' +/- '+strtrim(string(st,form='(f15.1)'),2)
  text = strtrim(long(avg),2)+' +/- '+strtrim(string(st,form='(f15.1)'),2)
  xyouts, tx+(ny*.1), y, text, align=0,orient= 90, chars=1.5

  y = !y.crange[1] - dy*(.05) + lonarr(nx)
  xyouts, tx+(ny*.1), y, text, align=0,orient=-90,co=min(co), chars=1.5

  if channel eq 1b then begin
     plot,euvsc_rec.decoded_data,xs=1,tit='Channel C2 off',/nodata,xr=[0,n]
     xyouts,/norm,align=0.5,.5,.25,'No C2 data'
  endif

  ; write to png file
  stride=20 ; png file write cadence is stride*euvsc_delta_update_seconds
  if keyword_set(do_files) eq 1 and pngfilecount mod stride eq 1 then begin
     write_pngfile,'/dev/shm/tmp_euvsc.png'
     file_move,'/dev/shm/tmp_euvsc.png','/dev/shm/euvsc.png',/overwrite
     print,'euvsc.png updated'
  endif
  pngfilecount = (pngfilecount+1) mod stride

  !p.multi=pmulti_orig

  plot_euvsc_sigma, euvsc_rec, laser=laser

  plot_euvsc_count_image, euvsc_rec

;stop
return
end
