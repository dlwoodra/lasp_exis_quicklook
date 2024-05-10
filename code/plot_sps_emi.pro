pro plot_sps_emi, sps_rec, temperature_dn

common plot_sps_emi_cal, recent_sps, recent_df, recent_sps_g, lasttime, recent_tempC
common plot_spectrum_dn_temp_rates_cal, xrsrate, euvsarate, euvsbrate, euvscrate, spsrate
common apply_gain_cal, temperature_C, xrsgain, euvsagain, euvsbgain

if size(lasttime,/type) eq 0 then lasttime=-1

n_sec_to_avg = 20. ; seconds of data used in averages

sps = sps_rec.diodes
sps_g = sps_rec.current
df  = sps_rec.time.df
hms = sps_rec.time.hms

if size(recent_df,/type) eq 0 then begin
   recent_df = [1,1]*df
   recent_sps = [[sps],[sps]]
   recent_sps_g = [[sps_g],[sps_g]]
   recent_tempc=[1,1]*temperature_C[temperature_dn]
endif

; append the current data to the old arrays
recent_df  = [temporary(recent_df), df]
recent_sps = [[temporary(recent_sps)], [sps]]
recent_sps_g = [[temporary(recent_sps_g)], [sps_g]]
recent_tempc = [temporary(recent_tempc), reform(temperature_C[temperature_dn])]

n_x = n_elements(recent_df)
nkeep=880 ; keep 120 seconds (120*4=480)
if n_x gt nkeep then begin
   recent_df = recent_df[(n_x-nkeep):(n_x-1)]
   recent_sps = recent_sps[*,(n_x-nkeep):(n_x-1)]
   recent_sps_g = recent_sps_g[*,(n_x-nkeep):(n_x-1)]
   recent_tempc = recent_tempc[(n_x-nkeep):(n_x-1)]
endif

if abs(lasttime - sps_rec.time.sod) lt 5. then return

lasttime = sps_rec.time.sod

window_set, 'EMI-SPS-ASIC'
!p.multi=[0,1,3]

; scale
mx = max(recent_sps, min=minx)
;mx = max(recent_sps[0:3,*],min=minx)
;mx = max(recent_sps[0,*])>max(recent_sps[1:*:6])>max(recent_sps[2:*:6])>max(recent_sps[3:*:6])
;minx=min(recent+sps[0,*])<min(recent_sps[1:*:6])<min(recent_sps[2:*:6])<min(recent_sps[3:*:6])

relsec = (recent_df - recent_df[n_elements(recent_df)-1])*86400.d

co=['0000ff'xl,'3399FF'xl,'33CC99'xl, $
    '009900'xl,'FF0000'xl,'CC3399'xl]

; number of intervals to average together
nsum = long( n_sec_to_avg / ((sps_rec.asic.integtime+1.)*0.25) )

xdisp=lindgen(nkeep-30) ; indices to display
if n_elements(relsec) gt nkeep-30 then xdisp += 30

; all raw data as points, and line as mean
mavg = float(recent_sps)
for i=0,n_elements(recent_sps[*,0])-1 do begin
   for j=1,n_elements(recent_sps[0,*])-1 do begin
      lo = (j-nsum) > 0
      hi = j ;(lo+nsum/2) < (n_elements(recent_sps[0,*])-1)
      mavg[i,j]=total(recent_sps[i,lo:hi])/(hi-lo+1)
   endfor
endfor

; data as points
plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
     tit='SPS_Mean-'+hms,xtit='seconds in the past',$
     ytit='DN', ps=3, $
     xmargin=[11,4],ymargin=[5,3],charsize=2

for i=0,5 do oplot,relsec[xdisp],recent_sps[i,xdisp],co=co[i],ps=3
;for i=0,5 do oplot,relsec[xdisp],recent_sps[i,xdisp],co=co[i],nsum=nsum

for i=0,5 do oplot,relsec[xdisp],mavg[i,xdisp],co=co[i]


y0=!y.crange[0]
dy=!y.crange[1]-y0
for i=0,5 do begin
   t='SPS-#'+strtrim(i,2)
   xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
endfor


;; 20-sec stddev over time after applying gain
;;thegain = ( fltarr(6) + 9. ) ; fA/count ;;;; use * 1e-15 to get A/count
;recent_sps_g = apply_gain(recent_sps, temperature_dn, /sps)

; dead time only applies to the ETU XRS, nothing else
;recent_sps_g = apply_dead_time(recent_sps) ; account for dead time

;for i=0,n_elements(recent_sps[*,0])-1 do recent_sps_g[i,*] *= thegain[i]

stg = recent_sps_g
for i=0,n_elements(recent_sps[*,0])-1 do begin
   for j=1,n_elements(recent_sps_g[0,*])-1 do begin
      lo=(j-nsum) > 0
      stg[i,j]=stddev(recent_sps_g[i,lo:j])
   endfor
   stg[i,0]=stg[i,1]
endfor

plot,[1,1],[1,1],xr=[-300,0],yr=[min(stg),max(stg)],xs=1,ys=1, $
     tit='SPS_stdev-'+hms,xtit='seconds in the past',$
     ytit='stddev (fA)', $
     xmargin=[11,4],ymargin=[5,3],charsize=2

for i=0,5 do oplot,relsec[xdisp],stg[i,xdisp],co=co[i]
y0=!y.crange[0]
dy=!y.crange[1]-y0
for i=0,5 do begin
   t='SPS-#'+strtrim(i,2)
   xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
endfor

;stop

; raw - (moving avg) vs time
delta=recent_sps - mavg
plot,[1,1],[1,1],xr=[-300,0],yr=[min(delta),max(delta)],xs=1,ys=1, $
     tit='SPS_raw-mean-'+hms,xtit='seconds in the past',$
     ytit='DN', $
     xmargin=[11,4],ymargin=[5,3],charsize=2
for i=0,5 do oplot,relsec[xdisp],delta[i,xdisp],co=co[i],nsum=40

y0=!y.crange[0]
dy=!y.crange[1]-y0
for i=0,5 do begin
   t='SPS-#'+strtrim(i,2)
   xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
endfor

  ; now calculate the temperature rate of change using a line fit
  coef = ladfit(relsec, recent_tempc, /double) ; "robust" line fit
  spsrate = coef[1]*60. ; slope deg/sec * sec/min

return
end
