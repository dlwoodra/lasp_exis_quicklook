; $Id: plot_euvsb.pro 76142 2016-08-18 18:07:33Z dlwoodra $

pro plot_euvsb, euvsb_rec, temperature_dn ;, df, hms

;
; note that euvsb is raw DN, df is days since 2000 jan 1 plus day fraction
;
  common plot_euvsb_cal, recent_df, recent_euvsb, lasttime, recent_tempC
  common plot_spectrum_dn_temp_rates_cal, xrsrate, euvsarate, euvsbrate, euvscrate, spsrate
  common apply_gain_cal, temperature_C, xrsgain, euvsagain, euvsbgain

  if size(lasttime,/type) eq 0 then lasttime = -1.

  euvsb = euvsb_rec.diodes
  df    = euvsb_rec.time.df
  hms   = euvsb_rec.time.hms

  if size(recent_df,/type) eq 0 then begin
     recent_df=[1,1]*df
     recent_euvsb=[[euvsb],[euvsb]]
     recent_tempc=[1,1]*temperature_C[temperature_dn]
  endif

  ; append the current data to the old arrays
  recent_df = [temporary(recent_df),df]
  recent_euvsb = [[temporary(recent_euvsb)],[euvsb]]
  recent_tempc = [temporary(recent_tempc), reform(temperature_C[temperature_dn])]
  n_x = n_elements(recent_df)
  nkeep=220
  if n_x gt nkeep then begin
     recent_df = recent_df[(n_x-nkeep):(n_x-1)]
     recent_euvsb = recent_euvsb[*,(n_x-nkeep):(n_x-1)]
     recent_tempc = recent_tempc[(n_x-nkeep):(n_x-1)]
  endif

  ; call plot_euvsb_emi
  plot_euvsb_emi, euvsb_rec, temperature_dn


  ; don't update the plot more often than every other second
  if abs(lasttime - euvsb_rec.time.sod) lt 5. then return

  lasttime = euvsb_rec.time.sod

  ;scale=1.0
  mx=max(recent_euvsb,min=minx)

  window_set,'EUVS-B'

  if total(euvsb_rec.diodes eq euvsb_rec.offset) eq n_elements(euvsb_rec.diodes) then begin
     print,'EUVS-B test pattern found '+hms
  endif

  !p.multi=0
  ; plot the one point
  plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
       tit='EUVS-B-'+hms,xtit='seconds in the past',$
       xmargin=[11,4], ymargin=[5,3]

  ; overplot the old data
  co=['000066'xl,'0000ff'xl,'0066ff'xl, $
      '00cc99'xl,'00ff00'xl,'006600'xl, $
      'cc9900'xl,'ff0000'xl,'990033'xl, $
      'cc00cc'xl,'666666'xl,'000000'xl, $
      '000066'xl,'0000ff'xl,'0066ff'xl, $
      '00cc99'xl,'00ff00'xl,'006600'xl, $
      'cc9900'xl,'ff0000'xl,'990033'xl, $
      'cc00cc'xl,'666666'xl,'000000'xl]
  relsec = (recent_df - recent_df[n_elements(recent_df)-1])*86400.d
  for i=0,23 do begin
     oplot,relsec,recent_euvsb[i,*],co=co[i]
  endfor

  y0=!y.crange[0]
  dy=!y.crange[1]-y0
  for i=0,23 do begin
     oplot,[1,1]*df,[1,1]*euvsb[i],ps=2,co=co[i],symsize=2
     t='EUVSB-A#'+strtrim(i,2)
     xyouts,!x.crange[0],y0+(i*dy/24.),t,co=co[i]
  endfor

  ; now calculate the temperature rate of change using a line fit
  coef = ladfit(relsec, recent_tempc, /double) ; "robust" line fit
  euvsbrate = coef[1]*60. ; slope deg/sec * sec/min

return
end
