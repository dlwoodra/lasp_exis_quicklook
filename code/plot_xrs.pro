pro plot_xrs, xrs_rec, temperature_dn, do_darkxrs=do_darkxrs, do_files=do_files

;
; note that xrs is raw DN, df is days since 2000 jan 1 plus day fraction
;
  common plot_xrs_cal, recent_df, recent_xrs, lasttime, recent_tempC
  common plot_spectrum_dn_temp_rates_cal, xrsrate, euvsarate, euvsbrate, euvscrate, spsrate
  common apply_gain_cal, temperature_C, xrsgain, euvsagain, euvsbgain


  ; whenever an event happens, clear the history
  ;if size(recent_df,/type) ne 0 then begin
  ;   ; clear the common block
  ;   tmp=temporary(recent_df)
  ;   tmp=temporary(recent_xrs)
  ;   tmp=temporary(lasttime)
  ;endif

  if size(lasttime,/type) eq 0 then lasttime=-1.

  xrs = xrs_rec.diodes[[5,6,7,8,9,0,10,1,2,3,4,11]] ; reorder to be a1,a21-4,d1,b1,b21-4,d2
  df  = xrs_rec.time.df
  hms = xrs_rec.time.hms

  if size(recent_df,/type) eq 0 then begin
     recent_df=[1,1]*df
     recent_xrs=[[xrs],[xrs]]
     recent_tempc=[1,1]*temperature_C[temperature_dn]
  endif


  ; append the current data to the old arrays
  recent_df = [temporary(recent_df),df]
  recent_xrs = [[temporary(recent_xrs)],[xrs]]
  recent_tempc = [temporary(recent_tempc), reform(temperature_C[temperature_dn])]

  n_x = n_elements(recent_df)
  nkeep=220
  if n_x gt nkeep then begin
     recent_df = recent_df[(n_x-nkeep):(n_x-1)]
     recent_xrs = recent_xrs[*,(n_x-nkeep):(n_x-1)]
     recent_tempc = recent_tempc[(n_x-nkeep):(n_x-1)]
  endif

  ; call plot_xrs_emi
  plot_xrs_emi, xrs_rec, temperature_dn

  ;
  ; if at least 3 seconds has elapsed, then update the plot
  ;
  xrs_delta_update_seconds = 5.
  if abs(lasttime - xrs_rec.time.sod) lt xrs_delta_update_seconds then return
  
  lasttime = xrs_rec.time.sod


  ;scale=1.0
  mx=max(recent_xrs,min=minx)
  
  ; set the window for plotting
  window_set, 'XRS'

  title='XRS-'+hms
  if total(xrs_rec.diodes eq xrs_rec.offset) eq n_elements(xrs_rec.diodes) then begin
     print,'XRS test pattern found '+hms
     title='XRS-TESTPATTERN-'+hms
  endif

  ; plot the one point
  !p.multi=0
  plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
       tit=title,xtit='seconds in the past',$
       xmargin=[11,4], ymargin=[5,3],ytit='DN'

  ; overplot the old data
  co=['000066'xl,'0000ff'xl,'0066ff'xl, $
      '00cc99'xl,'00ff00'xl,'006600'xl, $
      'cc9900'xl,'ff0000'xl,'990033'xl, $
      'cc00cc'xl,'666666'xl,'000000'xl]
  relsec = (recent_df - recent_df[n_elements(recent_df)-1])*86400.d
  for i=0,11 do begin
     oplot,relsec,recent_xrs[i,*],co=co[i]
  endfor

  y0=!y.crange[0]
  dy=!y.crange[1]-y0
  ; Randy Meisner 15 Aug 2013 - fix plot lables/colors according to ordering in array.
  ;labels=['d1','B21','B22','B23','B24','A1','A21','A22','A23','A24','B1','d2']
  labels=['A1','A21','A22','A23','A24','d1','B1','B21','B22','B23','B24','d2']
  for i=0,11 do begin
     oplot,[1,1]*df,[1,1]*xrs[i],ps=2,co=co[i],symsize=2
     ;if i le 5 then t='XRS-A#'+strtrim(i,2) else t='XRS-B#'+strtrim(i-6,2)
     ;xyouts,!x.crange[0]+5,y0+(i*dy/12.),t,co=co[i]
     xyouts,!x.crange[0]+5,y0+(i*dy/12.),labels[i],co=co[i]
  endfor



  ;
  ; Now do the targeting plot
  ;
  plot_xrs_target, xrs_rec, temperature_dn, do_darkxrs=do_darkxrs, do_files=do_files


  ; now calculate the temperature rate of change using a line fit
  coef = ladfit(relsec, recent_tempc, /double) ; "robust" line fit
  xrsrate = coef[1]*60. ; slope deg/sec*sec/min

return
end
