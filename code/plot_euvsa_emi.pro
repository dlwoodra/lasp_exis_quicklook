pro plot_euvsa_emi, euvsa_rec, temperature

common plot_euvsa_emi_cal, recent_euvsa, recent_df, lasttime

if size(lasttime,/type) eq 0 then lasttime=-1

n_sec_to_avg = 20. ; seconds of data used in averages

euvsa = euvsa_rec.diodes
df  = euvsa_rec.time.df
hms = euvsa_rec.time.hms

if size(recent_df,/type) eq 0 then begin
   recent_df = [1,1]*df
   recent_euvsa = [[euvsa],[euvsa]]
endif

; append the current data to the old arrays
recent_df  = [temporary(recent_df), df]
recent_euvsa = [[temporary(recent_euvsa)], [euvsa]]

n_x = n_elements(recent_df)
nkeep=250 ; offset by 30 for averaging
if n_x gt nkeep then begin
   recent_df = recent_df[(n_x-nkeep):(n_x-1)]
   recent_euvsa = recent_euvsa[*,(n_x-nkeep):(n_x-1)]
endif

if abs(lasttime - euvsa_rec.time.sod) lt 5. then return

lasttime = euvsa_rec.time.sod

window_set,'EMI-EUVSA-ASIC'
!p.multi=[0,4,3]

; scale
mx = max(recent_euvsa, min=minx)

relsec = (recent_df - recent_df[n_elements(recent_df)-1])*86400.d

co=['0000ff'xl,'3399FF'xl,'33CC99'xl, $
    '009900'xl,'FF0000'xl,'CC3399'xl]

; number of intervals to average together
nsum = long( n_sec_to_avg / ((euvsa_rec.asic.integtime+1.)*0.25) )

xdisp=lindgen(nkeep-30) ; indices to display
if n_elements(relsec) gt nkeep-30 then xdisp += 30

; all raw data as points, and line as mean
mavg = float(recent_euvsa)
for i=0,n_elements(recent_euvsa[*,0])-1 do begin
   for j=1,n_elements(recent_euvsa[0,*])-1 do begin
      lo = (j-nsum) > 0
      ; trailing avg only
      hi = j ;(lo+nsum/2) < (n_elements(recent_euvsa[0,*])-1)
      mavg[i,j]=total(recent_euvsa[i,lo:hi])/(hi-lo+1)
   endfor
endfor

for asic=0,3 do begin
   plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
        tit='EUVSA'+strtrim(asic,2)+'_Mean-'+hms,xtit='seconds in the past',$
        ytit='DN', $
        xmargin=[11,4],ymargin=[5,3],charsize=2
   for i=0,5 do oplot,relsec[xdisp],recent_euvsa[i+6*asic,xdisp],co=co[i],ps=3
   
   for i=0,5 do oplot,relsec[xdisp],mavg[i+6*asic,xdisp],co=co[i]

   y0=!y.crange[0]
   dy=!y.crange[1]-y0
   for i=0,5 do begin
      t='EUVSA'+strtrim(asic,2)+'-#'+strtrim(i+asic*6,2)
      xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
   endfor
endfor ; asic

; 2nd plot
; 20-sec stddev over time after applying gain

; apply gain
; this temperature is for the most recent value only, so not good for temperature changes
recent_euvsa_g = apply_gain(recent_euvsa,temperature,/euvsa)

stg = recent_euvsa_g
for i=0,n_elements(recent_euvsa[*,0])-1 do begin
   for j=1,n_elements(recent_euvsa_g[0,*])-1 do begin
      lo=(j-nsum) > 0
      stg[i,j]=stddev(recent_euvsa_g[i,lo:j])
   endfor
   stg[i,0]=stg[i,1]
endfor

for asic=0,3 do begin
   plot,[1,1],[1,1],xr=[-300,0],yr=[min(stg),max(stg)],xs=1,ys=1, $
        tit='EUVSA'+strtrim(asic,2)+'_stdev-'+hms,xtit='seconds in the past',$
        ytit='stddev (fA)', $
        xmargin=[11,4],ymargin=[5,3],charsize=2

   for i=0,5 do oplot,relsec[xdisp],stg[i+6*asic,xdisp],co=co[i]
   y0=!y.crange[0]
   dy=!y.crange[1]-y0
   for i=0,5 do begin
      t='EUVSA'+strtrim(asic,2)+'-#'+strtrim(i+6*asic,2)
      xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
   endfor
endfor ; asic


; 3rd plot
; raw - (moving avg) vs time
delta=recent_euvsa - mavg

for asic=0,3 do begin
   plot,[1,1],[1,1],xr=[-300,0],yr=[min(delta),max(delta)],xs=1,ys=1, $
        tit='EUVSA'+strtrim(asic,2)+'_raw-mean-'+hms,xtit='seconds in the past',$
        ytit='DN', $
        xmargin=[11,4],ymargin=[5,3],charsize=2
   for i=0,5 do oplot,relsec[xdisp],delta[i+6*asic,xdisp],co=co[i]
   
   y0=!y.crange[0]
   dy=!y.crange[1]-y0
   for i=0,5 do begin
      t='EUVSA'+strtrim(asic,2)+'-#'+strtrim(i+6*asic,2)
      xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
   endfor
endfor ; asic

return
end
