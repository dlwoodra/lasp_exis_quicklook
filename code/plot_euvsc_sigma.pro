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
;    $Id: plot_euvsc_sigma.pro 78832 2017-07-31 21:14:26Z dlwoodra $
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
pro write_to_euvsc_laser_file, euvsc, cm, tmax

  default_file_name = getenv('exis_data_quicklook')+'/latest_euvsc_laser.txt'

  openw, euvsc_lun, default_file_name, /get_lun

  ptime=euvsc[0].time

  printf, euvsc_lun, ';Creator: plot_euvsc_sigma via write_to_euvsc_laser_file'
  printf, euvsc_lun, ';YYYYDOY HH:MM:SS.sss SOD PixelCentroid PeakSignal'
  printf, euvsc_lun, strtrim(ptime.yd,2)+' '+$
          ptime.hms+' '+$
          strtrim(ptime.sod,2)+' '+$
          strtrim(cm,2)+' '+$
          strtrim(round(tmax),2)

  free_lun,euvsc_lun

return
end


;+
; This routine makes three plots, to support the EXIS science data quicklook.
; It relies on window information defined in the exis_quicklook.pro file.
;
; :Params:
;    euvsc_rec : in, required, type=structure
;      The scalar structure is defined in gpds_defines.pro
;
; :Keywords:
;    laser : in, optional, type=boolean
;      use keyword to replace the last (sigma) plot with a zoom in of the laser line
;
; :Uses:
;    window_set
;
;-
pro plot_euvsc_sigma, euvsc_rec, laser=laser

common plot_euvsc_sigma_cal, euvsc, sig, temperature_C
common plot_spectrum_dn_temp_rates_cal, xrsrate, euvsarate, euvsbrate, euvscrate, spsrate

n_keep = 181 ; integrations

; ignore first two integrations after detector change count is zero
if euvsc_rec.fsw.detchg_cnt lt 2 then goto, bailout

if size(temperature_C,/type) eq 0 then begin
   temperature_C = (read_goes_l0b_file(getenv('exis_cal_data')+'/exis_temperature.cal')).data
endif

if size(euvsc,/type) eq 0 then begin
  ;window_id = get_window_id('EMI-EUVS-C_Sigma')
  euvsc = euvsc_rec
  goto, bailout
endif else begin
  if n_elements(euvsc_rec) lt n_keep then begin
    euvsc = [euvsc_rec,euvsc] ;add new to front, in reverse-time order
  endif else begin
    ;rotate the elements and overwrite the first (oldest)
    euvsc=shift(euvsc,1)
    euvsc[0] = euvsc_rec
  endelse
endelse

if n_elements(euvsc) lt 3 then return

euvsctmp = euvsc[1:(n_elements(euvsc)-1)<6]
baseline = total(float(euvsctmp.decoded_data),2) / n_elements(euvsctmp)

sig1 = total(stddev_dim(float(euvsc[0:(n_elements(euvsc)-1)<5].decoded_data),2))/512.
if size(sig,/type) eq 0 then sig=sig1 else begin
  if n_elements(sig) lt n_keep then sig=[sig1,sig] else begin
    sig = shift(sig,1)
    sig[0]=sig1
  endelse
endelse
dsec = (euvsc.time.df - euvsc[0].time.df)*86400.

; if the window is not open then bailout
;if window_exists(window_id) ne 1 then goto,bailout

; override default graphics
init_pmulti=!p.multi
!p.multi=[0,1,3]

window_set,'EMI-EUVS-C_Sigma'

plot,baseline,xs=1,xr=[0,511],tit='EUVS-C '+euvsc[0].time.hms, charsize=2, $
  yr=[(min(baseline)<min(euvsc[0].decoded_data)), (max(baseline)>max(euvsc[0].decoded_data))]

oplot,float(euvsc[0].decoded_data),co='9900'x


darkmaskavg=mean(euvsc[0].decoded_data[0:45])
plot,float(euvsc[0].decoded_data) - darkmaskavg,ys=1,xs=1,charsize=2, tit='Latest - <darkmask>'


if keyword_set(laser) then begin
   ; plot the laser signal over +/- 10 diodes
   rel = float(euvsc[0].decoded_data) - darkmaskavg
   tmax=max(rel,maxidx)
   width=10
   lo=(maxidx-width)>0
   hi=(lo+2*width) < 511
   cm=total(rel[lo:hi]*(findgen(hi-lo+1)+lo)) / total(rel[lo:hi])
   plot,rel,charsize=2,ps=10,$
      xr=[maxidx-width > 0, maxidx+width < 511], xs=1, ys=1,$
      title='Laser signal above dark-'+euvsc[0].time.hms
   ; add text to plot for low/high signal warning and Max/CM pixel location
   if tmax lt 100 then begin
      xyouts,lo+1,tmax*.5,charsize=3,co='fe'x,'LOW SIGNAL'
   endif else begin
      if tmax gt 43000 then $
         xyouts,lo+1,tmax*0.75,charsize=3,co='fe'x,'HIGH SIGNAL'

      ; do the font switcheroo

      ; get the current font in use
      p_orig = !p
      device,get_current_font=orig_font

      ; use a device font
      device,set_font='6x13' ; for bare NUC
      device,set_font='10x20'
      font=0 ; 0=device, -1=hershey, 1=truetype

      ;xyouts,font=font,lo+1,tmax*.75,'Max@'+strtrim(maxidx,2);,charsize=2
      xyouts,font=font,lo+1,tmax*.25,'Centroid='+strtrim(cm,2),co='9900'x;,charsize=2
      xyouts,font=font,lo+1,tmax*.50,'PeakSignal='+strtrim(round(tmax),2),co='9900'x;,charsize=2
      oplot,cm*[1,1],!y.crange,lines=2,co='9900'x

      ; switch the font back
      device,set_font=orig_font
      !p.font = p_orig.font

   endelse
endif else begin
   if n_elements(sig) gt 2 then $
      plot,dsec,sig,ys=1,xr=[-180,0],xs=1,charsize=2,xtit='Seconds past', $
           tit='EUVS-C <Sigma>-'+euvsc[0].time.hms
endelse

  ; now calculate the temperature rate of change using a line fit
  ; restrict to last 30 points
  n_dsec=n_elements(dsec) - 1
  xs = sort(dsec) ; sort to be sure
  lo = (n_dsec-30) > 0
  rdsec = dsec[xs[lo:n_dsec]]
  rtemp = temperature_C[euvsc[xs[lo:n_dsec]].c2temp]

  ;coef = ladfit(dsec, temperature_C[euvsc.c2temp], /double) ; "robust" line fit
  coef = ladfit(rdsec, rtemp, /double) ; "robust" line fit
  euvscrate = coef[1]*60. ; slope deg/sec*sec/min

;restore defaults
!p.multi=init_pmulti

bailout:

return
end
