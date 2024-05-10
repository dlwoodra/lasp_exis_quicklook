; $Id: plot_euvsa.pro 76142 2016-08-18 18:07:33Z dlwoodra $

pro plot_euvsa, euvsa_rec, temperature_dn ; , df, hms

;
; note that euvsa is raw DN, df is days since 2000 jan 1 plus day fraction
;
  common plot_euvsa_cal, recent_df, recent_euvsa, lasttime, recent_tempC
  common plot_spectrum_dn_temp_rates_cal, xrsrate, euvsarate, euvsbrate, euvscrate, spsrate
  common apply_gain_cal, temperature_C, xrsgain, euvsagain, euvsbgain

  if size(lasttime,/type) eq 0 then lasttime=-1.

  euvsa = euvsa_rec.diodes
  df    = euvsa_rec.time.df
  hms   = euvsa_rec.time.hms

  if size(recent_df,/type) eq 0 then begin
     recent_df=[1,1]*df
     recent_euvsa=[[euvsa],[euvsa]]
     recent_tempc=[1,1]*temperature_C[temperature_dn]
  endif

  ; append the current data to the old arrays
  recent_df = [temporary(recent_df),df]
  recent_euvsa = [[temporary(recent_euvsa)],[euvsa]]
  recent_tempc = [temporary(recent_tempc), reform(temperature_C[temperature_dn])]

  n_x = n_elements(recent_df)
  nkeep=220
  if n_x gt nkeep then begin
     recent_df = recent_df[(n_x-nkeep):(n_x-1)]
     recent_euvsa = recent_euvsa[*,(n_x-nkeep):(n_x-1)]
     recent_tempc = recent_tempc[(n_x-nkeep):(n_x-1)]
  endif

  ; call plot_euvsa_emi
  plot_euvsa_emi, euvsa_rec, temperature_dn

  if abs(lasttime - euvsa_rec.time.sod) lt 5. then return
  
  lasttime = euvsa_rec.time.sod


  ;scale=1.0
  mx=max(recent_euvsa,min=minx)

  window_set,'EUVS-A'

  if total(euvsa_rec.diodes eq euvsa_rec.offset) eq n_elements(euvsa_rec.diodes) then begin
     print,'EUVS-A test pattern found '+hms
  endif

  !p.multi=0
  ; plot the one point
  plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
       tit='EUVS-A-'+hms,xtit='seconds in the past',$
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
     oplot,relsec,recent_euvsa[i,*],co=co[i]
  endfor

  y0=!y.crange[0]
  dy=!y.crange[1]-y0
  for i=0,23 do begin
     oplot,[1,1]*df,[1,1]*euvsa[i],ps=2,co=co[i],symsize=2
     t='EUVSA-A#'+strtrim(i,2)
     xyouts,!x.crange[0],y0+(i*dy/24.),t,co=co[i]
  endfor

  ; now calculate the temperature rate of change using a line fit
  coef = ladfit(relsec, recent_tempc, /double) ; "robust" line fit
  euvsarate = coef[1]*60. ; slope deg/sec * sec/min


return
end
