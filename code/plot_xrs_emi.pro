pro plot_xrs_emi, xrs_rec, temperature_dn

common plot_xrs_emi_cal, recent_xrs, recent_df, recent_xrs_g, lasttime

if size(lasttime,/type) eq 0 then lasttime=-1

n_sec_to_avg = 20. ; seconds of data used in averages

xrs = xrs_rec.diodes
df  = xrs_rec.time.df
hms = xrs_rec.time.hms
xrsg= xrs_rec.current

if size(recent_df,/type) eq 0 then begin
   recent_df = [1,1]*df
   recent_xrs = [[xrs],[xrs]]
   recent_xrs_g = [[xrsg],[xrsg]]
endif

; append the current data to the old arrays
recent_df  = [temporary(recent_df), df]
recent_xrs = [[temporary(recent_xrs)], [xrs]]
recent_xrs_g = [[temporary(recent_xrs_g)], [xrsg]]

n_x = n_elements(recent_df)
nkeep=250 ; offset for averaging 
if n_x gt nkeep then begin
   recent_df = recent_df[(n_x-nkeep):(n_x-1)]
   recent_xrs = recent_xrs[*,(n_x-nkeep):(n_x-1)]
   recent_xrs_g = recent_xrs_g[*,(n_x-nkeep):(n_x-1)]
endif

if abs(lasttime - xrs_rec.time.sod) lt 5. then return

lasttime = xrs_rec.time.sod

window_set, 'EMI-XRS-ASIC'

!p.multi=[0,2,3]

; scale
mx = max(recent_xrs, min=minx)

relsec = (recent_df - recent_df[n_elements(recent_df)-1])*86400.d

co=['0000ff'xl,'3399FF'xl,'33CC99'xl, $
    '009900'xl,'FF0000'xl,'CC3399'xl]

; number of intervals to average together
nsum = long( n_sec_to_avg / ((xrs_rec.asic.integtime+1.)*0.25) )

xdisp=lindgen(nkeep-30) ; indices to display
if n_elements(relsec) gt nkeep-30 then xdisp += 30

; all raw data as points, and line as mean
mavg = float(recent_xrs)
for i=0,n_elements(recent_xrs[*,0])-1 do begin
   for j=1,n_elements(recent_xrs[0,*])-1 do begin
      lo = (j-nsum) > 0
      ; trailing avg only
      hi = j ;(lo+nsum/2) < (n_elements(recent_xrs[0,*])-1)
      mavg[i,j]=total(recent_xrs[i,lo:hi])/(hi-lo+1)
   endfor
endfor

labels=['d1','B21','B22','B23','B24','A1','A21','A22','A23','A24','B1','d2']

for asic=0,1 do begin
   plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
        tit='XRS_Means-'+hms,xtit='seconds in the past',$
        ytit='DN', $
        xmargin=[11,4],ymargin=[5,3],charsize=2
   ;plot,[1,1],[1,1],xr=[-300,0],yr=[minx,mx],xs=1,ys=1, $
   ;     tit='XRS'+strtrim(asic,2)+'_Mean-'+hms,xtit='seconds in the past',$
   ;     ytit='DN', $
   ;     xmargin=[11,4],ymargin=[5,3],charsize=2
   for i=0,5 do oplot,relsec[xdisp],recent_xrs[i+6*asic,xdisp],co=co[i],ps=3
   
   for i=0,5 do oplot,relsec[xdisp],mavg[i+6*asic,xdisp],co=co[i]

   y0=!y.crange[0]
   dy=!y.crange[1]-y0
   for i=0,5 do begin
      xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,labels[i+asic*6],co=co[i]
   endfor
   ;for i=0,5 do begin
   ;   t='XRS'+strtrim(asic,2)+'-#'+strtrim(i+asic*6,2)
   ;   xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
   ;endfor
endfor ; asic

; 2nd plot
; 20-sec stddev over time after applying gain

;recent_xrs_g = recent_xrs

; dead time only applies to the ETU XRS, nothing else
exis_type = strupcase(getenv('exis_type'))
;if strcmp(!EXIS_HARDWARE,'ETU') eq 1 then begin
if strcmp(exis_type,'ETU') eq 1 then begin
   recent_xrs_g = apply_dead_time(recent_xrs) ; account for dead time
endif

;; apply gain
;recent_xrs_g = apply_gain(recent_xrs_g, temperature_dn, /xrs)

stg = recent_xrs_g
for i=0,n_elements(recent_xrs[*,0])-1 do begin
   for j=1,n_elements(recent_xrs_g[0,*])-1 do begin
      lo=(j-nsum) > 0
      stg[i,j]=stddev(recent_xrs_g[i,lo:j])
   endfor
   stg[i,0]=stg[i,1]
endfor

for asic=0,1 do begin
   plot,[1,1],[1,1],xr=[-300,0],yr=[min(stg),max(stg)],xs=1,ys=1, $
        tit='XRS_stdev-'+hms,xtit='seconds in the past',$
        ytit='stddev (fA)', $
        xmargin=[11,4],ymargin=[5,3],charsize=2
   ;plot,[1,1],[1,1],xr=[-300,0],yr=[min(stg),max(stg)],xs=1,ys=1, $
   ;     tit='XRS'+strtrim(asic,2)+'_stdev-'+hms,xtit='seconds in the past',$
   ;     ytit='stddev (fA)', $
   ;     xmargin=[11,4],ymargin=[5,3],charsize=2

   for i=0,5 do oplot,relsec[xdisp],stg[i+6*asic,xdisp],co=co[i]
   y0=!y.crange[0]
   dy=!y.crange[1]-y0
   for i=0,5 do begin
      ;t='XRS'+strtrim(asic,2)+'-#'+strtrim(i+6*asic,2)
      ;xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
      xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,labels[i+asic*6],co=co[i]
   endfor
endfor ; asic


; 3rd plot
; raw - (moving avg) vs time
delta=recent_xrs - mavg

for asic=0,1 do begin
   plot,[1,1],[1,1],xr=[-300,0],yr=[min(delta),max(delta)],xs=1,ys=1, $
        tit='XRS_raw-mean-'+hms,xtit='seconds in the past',$
        ytit='DN', $
        xmargin=[11,4],ymargin=[5,3],charsize=2
   ;plot,[1,1],[1,1],xr=[-300,0],yr=[min(delta),max(delta)],xs=1,ys=1, $
   ;     tit='XRS'+strtrim(asic,2)+'_raw-mean-'+hms,xtit='seconds in the past',$
   ;     ytit='DN', $
   ;     xmargin=[11,4],ymargin=[5,3],charsize=2
   for i=0,5 do oplot,relsec[xdisp],delta[i+6*asic,xdisp],co=co[i]
   
   y0=!y.crange[0]
   dy=!y.crange[1]-y0
   for i=0,5 do begin
      ;t='XRS'+strtrim(asic,2)+'-#'+strtrim(i+6*asic,2)
      ;xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,t,co=co[i]
      xyouts,!x.crange[0],y0+(i*dy/6.) + dy/12.,labels[i+asic*6],co=co[i]
   endfor
endfor ; asic

return
end
